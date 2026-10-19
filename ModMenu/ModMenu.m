/*=============================================================================
 *  ModMenu.m  -  menu runtime del proyecto fusion (fase A)
 *  ---------------------------------------------------------------------------
 *  Este archivo se compila como ModMenu.dylib y la herramienta lo mete en el
 *  IPA REEMPLAZANDO el binario de una framework que el juego ya carga:
 *
 *      Payload/cod.app/Frameworks/MSDKPolicy.framework/MSDKPolicy
 *
 *  Consecuencias (el motivo de hacerlo asi):
 *    - cero LC_LOAD_DYLIB nuevas en el cod: dyld carga la framework porque
 *      ya venia en su lista de imagenes;
 *    - cero archivos nuevos en el paquete.
 *  Es la misma tecnica del modder que sigue vivo (SP3CTERIOS V1.2.0).
 *
 *  v0.1.2 (18 oct) - build de DIAGNOSTICO. Responde, sin depender de capturas
 *  de syslog, si la dylib carga y donde esta el fallo:
 *    1. el constructor anota su RUTA real (dladdr): se ve que binario cargo;
 *    2. burbuja arriba-izquierda con CONTADOR de segundos: si sube, esta viva;
 *    3. la burbuja se revisa en cada tick y se recoloca para siempre (ya no
 *       se rinde a los 120 s como la 0.1.1); usa ventana overlay propia;
 *    4. LATIDO en el log cada 5 s (escenas, ventanas, estado de la burbuja):
 *       cualquier trocito de syslog que pise el juego ya sirve;
 *    5. archivo de estado en Documents/modmenu_status.txt, reescrito en cada
 *       latido: se lee desde el iPhone (app Archivos) o 3uTools, sin syslog.
 *       La herramienta marca ademas el icono como "CODM [MM]" al meter esta
 *       build, para reconocer la instalacion a simple vista.
 *  Cuando esto se vea en el equipo desechable, la fase A queda cerrada y las
 *  siguientes (ESP, skins, stream, guest reset) cuelgan de este binario.
 *============================================================================*/

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <dlfcn.h>
#include <unistd.h>

#define MODMENU_VERSION     "0.1.2-faseA"
#define MM_TAG              "[MODMENU]"
#define MM_FAST_TRIES       120             /* 120 x 0.5 s = 60 s rapidos  */
#define MM_FAST_LOG_EVERY   20              /* log de espera cada 10 s     */
#define MM_SLOW_SECS        5               /* luego un latido cada 5 s    */

/* Marcador global: el CI lo verifica para confirmar que este fuente llego al
   binario (el constructor es static y no sirve como prueba de presencia). */
const char *modmenu_build_id = "modmenu-faseA-0.1.2";

static UIWindow *g_pill_win = nil;          /* ventana overlay propia      */
static UIView   *g_pill     = nil;          /* la pildora en si            */
static UILabel  *g_pill_lbl = nil;          /* etiqueta (con contador)     */
static const char *g_via    = "-";          /* donde quedo colgada         */
static int       g_tries    = 0;
static NSTimeInterval g_t0  = 0;
static BOOL      g_ui_ok    = NO;           /* UIApplication ya es segura  */

static void mm_tick(void);

static double mm_uptime(void)
{
    return [NSDate timeIntervalSinceReferenceDate] - g_t0;
}

static const char *mm_my_path(void)
{
    Dl_info info;
    if (dladdr((const void *)&mm_my_path, &info) && info.dli_fname != NULL)
        return info.dli_fname;
    return "?";
}

/* UIApplication solo es fiable cuando el main ya corre: hasta el primer tick
   ni la tocamos (el constructor va antes de UIApplicationMain). */
static UIApplication *mm_app(void)
{
    if (!g_ui_ok) return nil;
    @try { return UIApplication.sharedApplication; }
    @catch (NSException *e) { return nil; }
}

/* Cualquier escena conectada sirve; se prefiere la que esta en foreground. */
static UIWindowScene *mm_pick_scene(void)
{
    UIApplication *app = mm_app();
    if (app == nil) return nil;
    UIWindowScene *fallback = nil;
    for (UIScene *s in app.connectedScenes) {
        if (![s isKindOfClass:[UIWindowScene class]]) continue;
        UIWindowScene *ws = (UIWindowScene *)s;
        if (ws.activationState == UISceneActivationStateForegroundActive)
            return ws;
        if (fallback == nil) fallback = ws;
    }
    return fallback;
}

/* Ventana ya existente del juego, por si aun no hay escena usable. */
static UIWindow *mm_host_window(void)
{
    UIApplication *app = mm_app();
    if (app == nil) return nil;
    if (app.keyWindow) return app.keyWindow;
    for (UIWindow *w in app.windows) {
        if (!w.hidden) return w;
    }
    return nil;
}

static int mm_scene_count(void)
{
    UIApplication *app = mm_app();
    return (app == nil) ? 0 : (int)app.connectedScenes.count;
}

static int mm_window_count(void)
{
    UIApplication *app = mm_app();
    return (app == nil) ? 0 : (int)app.windows.count;
}

static NSString *mm_scene_state(void)
{
    UIWindowScene *ws = mm_pick_scene();
    if (ws == nil) return @"ninguna";
    switch (ws.activationState) {
        case UISceneActivationStateForegroundActive:   return @"ForegroundActive";
        case UISceneActivationStateForegroundInactive: return @"ForegroundInactive";
        case UISceneActivationStateBackground:         return @"Background";
        default:                                       return @"Unattached";
    }
}

static NSString *mm_docs_dir(void)
{
    NSArray *a = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                     NSUserDomainMask, YES);
    return (a.count > 0) ? a[0] : nil;
}

/* Reescritura atomica del archivo de estado que se puede leer sin syslog. */
static void mm_write_status(NSString *nota)
{
    @try {
        NSString *docs = mm_docs_dir();
        if (docs.length == 0) return;

        NSString *ios = @"?";
        @try { ios = [UIDevice currentDevice].systemVersion; } @catch (NSException *e) {}

        NSString *txt = [NSString stringWithFormat:
            @"build=%s\n"
            @"dylib=%s\n"
            @"uptime_s=%d\n"
            @"pid=%d\n"
            @"bundle=%@\n"
            @"ios=%@\n"
            @"escenas=%d estado=%@\n"
            @"ventanas=%d\n"
            @"burbuja=%s via=%s\n"
            @"nota=%@\n",
            MODMENU_VERSION, mm_my_path(), (int)mm_uptime(), (int)getpid(),
            NSBundle.mainBundle.bundleIdentifier ?: @"?",
            ios, mm_scene_count(), mm_scene_state(), mm_window_count(),
            (g_pill != nil && g_pill.window != nil) ? "SI" : "NO",
            g_via, nota];

        [txt writeToFile:[docs stringByAppendingPathComponent:@"modmenu_status.txt"]
               atomically:YES
                 encoding:NSUTF8StringEncoding
                    error:NULL];
    } @catch (NSException *e) {
        NSLog(@"%s no pude escribir el archivo de estado: %@", MM_TAG, e.reason);
    }
}

/* Coloca (o recoloca) la pildora. Devuelve YES si quedo enganchada a una
   ventana VIVA. Se ejecuta en el main queue, una vez por tick. */
static BOOL mm_place_pill(void)
{
    @try {
        /* si ya esta enganchada a una ventana viva, solo asegurar visible */
        if (g_pill != nil && g_pill.window != nil) {
            if (g_pill_win != nil) g_pill_win.hidden = NO;
            return YES;
        }

        if (g_pill == nil) {
            CGRect r = CGRectMake(12.0, 88.0, 250.0, 38.0);
            g_pill = [[UIView alloc] initWithFrame:r];
            g_pill.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.92];
            g_pill.layer.cornerRadius = 10.0;
            g_pill.clipsToBounds = YES;
            g_pill.userInteractionEnabled = NO;

            g_pill_lbl = [[UILabel alloc] initWithFrame:g_pill.bounds];
            g_pill_lbl.text = @"ModMenu " MODMENU_VERSION;
            g_pill_lbl.textColor = [UIColor blackColor];
            g_pill_lbl.font = [UIFont boldSystemFontOfSize:13.0];
            g_pill_lbl.textAlignment = NSTextAlignmentCenter;
            [g_pill addSubview:g_pill_lbl];
        }

        UIWindowScene *scene = mm_pick_scene();
        if (scene != nil) {
            if (g_pill_win == nil || g_pill_win.windowScene != scene) {
                g_pill_win = [[UIWindow alloc] initWithWindowScene:scene];
                g_pill_win.frame = UIScreen.mainScreen.bounds;
                g_pill_win.windowLevel = UIWindowLevelAlert + 2;
                g_pill_win.userInteractionEnabled = NO;
                UIViewController *vc = [[UIViewController alloc] init];
                g_pill_win.rootViewController = vc;
            }
            [g_pill_win.rootViewController.view addSubview:g_pill];
            g_pill_win.hidden = NO;
            g_via = "UIWindowScene";
            NSLog(@"%s burbuja CREADA via=UIWindowScene estado=%ld escenas=%d",
                  MM_TAG, (long)scene.activationState, mm_scene_count());
            return YES;
        }

        UIWindow *host = mm_host_window();
        if (host != nil) {
            [host addSubview:g_pill];
            [host bringSubviewToFront:g_pill];
            g_via = "keyWindow";
            NSLog(@"%s burbuja CREADA via=keyWindow subview (sin escena)", MM_TAG);
            return YES;
        }

        return NO;   /* todavia no hay nada donde colgarla */
    } @catch (NSException *e) {
        NSLog(@"%s excepcion colocando la burbuja: %@", MM_TAG, e.reason);
        return NO;
    }
}

/* El latido: intenta colocar la pildora, la actualiza y deja rastro.
   Rapido (0.5 s) durante 60 s; despues lento (5 s) pero PARA SIEMPRE. */
static void mm_tick(void)
{
    @try {
        g_tries++;
        if (!g_ui_ok) g_ui_ok = YES;
        BOOL fast = (g_tries <= MM_FAST_TRIES);
        BOOL ok = mm_place_pill();

        if (g_pill_lbl != nil) {
            g_pill_lbl.text = [NSString stringWithFormat:@"ModMenu %s | %d s",
                               MODMENU_VERSION, (int)mm_uptime()];
        }

        if (fast) {
            if (!ok && (g_tries % MM_FAST_LOG_EVERY) == 0)
                NSLog(@"%s esperando escena/ventana... intento %d/%d (escenas=%d ventanas=%d)",
                      MM_TAG, g_tries, MM_FAST_TRIES, mm_scene_count(), mm_window_count());
            if (!ok && g_tries == MM_FAST_TRIES)
                NSLog(@"%s fase rapida agotada; sigo intentando cada %d s",
                      MM_TAG, MM_SLOW_SECS);
        } else {
            NSLog(@"%s latido vivo_s=%d escenas=%d estado=%@ ventanas=%d burbuja=%s via=%s",
                  MM_TAG, (int)mm_uptime(), mm_scene_count(), mm_scene_state(),
                  mm_window_count(), ok ? "SI" : "NO", g_via);
            mm_write_status(ok ? @"latido ok" : @"latido sin ventana");
        }

        double next = fast ? 0.5 : (double)MM_SLOW_SECS;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(next * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{ mm_tick(); });
    } @catch (NSException *e) {
        NSLog(@"%s excepcion en el latido: %@", MM_TAG, e.reason);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{ mm_tick(); });
    }
}

__attribute__((constructor)) static void modmenu_init(void)
{
    g_t0 = [NSDate timeIntervalSinceReferenceDate];
    NSLog(@"%s dylib cargada v%s  path=%s  pid=%d",
          MM_TAG, MODMENU_VERSION, mm_my_path(), (int)getpid());
    mm_write_status(@"arranque");

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{ mm_tick(); });
}
