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
 *    - cero claves nuevas en el Info.plist;
 *    - cero archivos nuevos en el paquete.
 *  Es la misma tecnica del modder que sigue vivo (SP3CTERIOS V1.2.0).
 *
 *  Fase A = prueba de vida:
 *    1. el constructor anota en el log del sistema que la dylib cargo;
 *    2. a los ~0.5 s aparece una burbuja flotante "ModMenu cargado".
 *  v0.1.1 (18 oct): la burbuja ya no depende de una escena en foreground.
 *    - acepta cualquier UIWindowScene conectada (prefiere foreground);
 *    - si aun no hay escena, cae al keyWindow / windows[0] y agrega la pildora
 *      como subview (el juego ES scene-based, pero el fallback cubre el caso
 *      de que la escena tarde en activarse);
 *    - reintenta hasta 120 s (240 x 0.5 s) y deja rastro en el log cada 10 s.
 *  Cuando eso se vea en el equipo desechable, el esqueleto esta validado y
 *  las siguientes fases (ESP, skins, stream, guest reset, anti-checksum) se
 *  cuelgan de este mismo binario.
 *============================================================================*/

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#include <unistd.h>

#define MODMENU_VERSION "0.1.1-faseA"
#define MM_TAG          "[MODMENU]"
#define MM_TRIES        240                 /* 240 x 0.5 s = 120 s */
#define MM_LOG_EVERY    20                  /* log cada 10 s           */

/* Marcador global: el CI lo verifica para confirmar que este fuente llego al
   binario (el constructor es static y no sirve como prueba de presencia). */
const char *modmenu_build_id = "modmenu-faseA-0.1.1";

static UIWindow *g_pill_win  = nil;         /* via UIWindowScene  */
static UIView   *g_pill_view = nil;         /* via keyWindow      */

/* Cualquier escena conectada sirve; se prefiere la que esta en foreground.
   Una escena "unattached"/"inactive" igual puede mostrar ventanas en iOS 13+. */
static UIWindowScene *mm_pick_scene(void)
{
    UIWindowScene *fallback = nil;
    for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
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
    UIApplication *app = UIApplication.sharedApplication;
    if (app.keyWindow) return app.keyWindow;
    for (UIWindow *w in app.windows) {
        if (!w.hidden) return w;
    }
    return nil;
}

/* Crea la pildora UNA sola vez y la cuelga donde se pueda. Devuelve YES si
   quedo visible. */
static BOOL mm_show_pill(void)
{
    if (g_pill_win != nil || g_pill_view != nil) return YES;   /* ya visible */

    CGRect pillRect = CGRectMake(12.0, 100.0, 260.0, 36.0);

    UIView *pill = [[UIView alloc] initWithFrame:pillRect];
    pill.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.62];
    pill.layer.cornerRadius = 9.0;
    pill.clipsToBounds = YES;
    pill.userInteractionEnabled = NO;

    UILabel *lbl = [[UILabel alloc] initWithFrame:pill.bounds];
    lbl.text = @"ModMenu " MODMENU_VERSION @" cargado";
    lbl.textColor = [UIColor colorWithRed:0.35 green:1.0 blue:0.55 alpha:1.0];
    lbl.font = [UIFont boldSystemFontOfSize:13.0];
    lbl.textAlignment = NSTextAlignmentCenter;
    [pill addSubview:lbl];

    UIWindowScene *scene = mm_pick_scene();
    if (scene != nil) {
        g_pill_win = [[UIWindow alloc] initWithWindowScene:scene];
        g_pill_win.frame = UIScreen.mainScreen.bounds;
        g_pill_win.windowLevel = UIWindowLevelAlert + 2;
        g_pill_win.userInteractionEnabled = NO;

        UIViewController *vc = [[UIViewController alloc] init];
        g_pill_win.rootViewController = vc;
        [vc.view addSubview:pill];

        g_pill_win.hidden = NO;
        NSLog(@"%s burbuja en pantalla v%s  via=UIWindowScene estado=%ld",
              MM_TAG, MODMENU_VERSION, (long)scene.activationState);
        return YES;
    }

    UIWindow *host = mm_host_window();
    if (host != nil) {
        [host addSubview:pill];
        [host bringSubviewToFront:pill];
        g_pill_view = pill;
        NSLog(@"%s burbuja en pantalla v%s  via=keyWindow subview (sin escena)",
              MM_TAG, MODMENU_VERSION);
        return YES;
    }

    return NO;   /* todavia no hay nada donde colgarla */
}

static void mm_pill_try(int intento)
{
    if (intento >= MM_TRIES) {
        NSLog(@"%s burbuja: sin escena ni ventana tras 120 s; me rindo", MM_TAG);
        return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        if (mm_show_pill()) return;
        if (intento > 0 && (intento % MM_LOG_EVERY) == 0) {
            NSLog(@"%s esperando escena/ventana... intento %d/%d",
                  MM_TAG, intento, MM_TRIES);
        }
        mm_pill_try(intento + 1);
    });
}

__attribute__((constructor)) static void modmenu_init(void)
{
    NSLog(@"%s dylib cargada v%s  bundle=%s  pid=%d",
          MM_TAG, MODMENU_VERSION,
          [NSBundle.mainBundle.bundleIdentifier UTF8String],
          (int)getpid());
    mm_pill_try(0);
}
