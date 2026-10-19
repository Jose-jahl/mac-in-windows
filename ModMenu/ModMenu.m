/*=============================================================================
 *  ModMenu.m  -  menu runtime del proyecto fusion
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
 *  v0.2.2 (19 oct) - ESP parte 1: MOTOR DE DIBUJO + SONDA.
 *    - capa de dibujo propia (MMCanvasView) DENTRO de la ventana del juego,
 *      por debajo del boton/panel: pinta cajas con nombre/distancia/salud a
 *      ~30 fps (CADisplayLink);
 *    - aun SIN datos reales: con el ESP maestro ON se dibujan 3 cajas DEMO en
 *      movimiento (valida el motor de dibujo en el equipo);
 *    - sonda de SOLO LECTURA de la tabla methodPointers del juego: lee con
 *      vm_read_overwrite (si una direccion no vale, devuelve error en vez de
 *      tumbar la app) y comprueba que los punteros caen en el binario del
 *      juego; resultado en Documents/modmenu_status.txt (linea probe=);
 *    - la v0.2.3 conecta camara/pawns reales (objetivos ya cribados en el
 *      laboratorio con la dylib del modder).
 *
 *  v0.2.1 (19 oct) - FIX reportado en dispositivo real:
 *    - FUERA la ventana overlay propia: provocaba que la app girara a
 *      vertical (su rootViewController admite todos los giros) y bloqueaba
 *      los toques fuera del boton/panel (un UIWindow es a su vez una vista:
 *      su hitTest devolvia la propia ventana y ahi moria el toque);
 *    - la UI ahora va PEGADA dentro de la ventana del juego (capa
 *      transparente): los toques fuera del menu caen solos al juego y la
 *      rotacion la decide unicamente el juego;
 *    - reenganche automatico en cada latido si el juego cambia de ventana.
 *
 *  v0.2.0 (19 oct) - FASE B, parte 1: EL MENU DE VERDAD.
 *    - boton flotante arrastrable que se despliega a toque (recuerda donde
 *      lo dejas; estilo del modder de referencia);
 *    - panel con paginas ESP / MISC / INFO;
 *    - los toggles y sliders se guardan (NSUserDefaults): persisten entre
 *      partidas; el ESP REAL se conecta en la build siguiente (v0.2.2) -
 *      esta build valida la UI y la interaccion en dispositivo;
 *    - Stream Mode: atenua el boton casi hasta desaparecer (para grabar);
 *    - la ventana overlay DEJA PASAR los toques fuera del boton/panel: el
 *      juego se sigue jugando igual;
 *    - se conserva el instrumental de diagnostico de la fase A: latido en el
 *      log cada 5 s + Documents/modmenu_status.txt + dladdr.
 *============================================================================*/

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <dlfcn.h>
#include <unistd.h>
#include <mach/mach.h>
#include <mach/vm_map.h>
#include <mach-o/dyld.h>
#include <math.h>
#include <string.h>

#define MODMENU_VERSION     "0.2.2-esp"
#define MM_TAG              "[MODMENU]"
#define MM_FAST_TRIES       120             /* 120 x 0.5 s = 60 s rapidos  */
#define MM_FAST_LOG_EVERY   20              /* log de espera cada 10 s     */
#define MM_SLOW_SECS        5               /* luego un latido cada 5 s    */
#define MM_PANEL_W          300.0
#define MM_PANEL_H          430.0

/* Marcador global: el CI lo verifica para confirmar que este fuente llego al
   binario (el constructor es static y no sirve como prueba de presencia). */
const char *modmenu_build_id = "modmenu-esp-0.2.2";

/* --- objetos de UI (globales, creados una sola vez) --- */
static UIView   *g_root  = nil;   /* capa transparente sobre la ventana juego */
static UIButton *g_btn   = nil;   /* boton flotante                           */
static UIView   *g_panel = nil;   /* panel desplegable                        */
static UISegmentedControl *g_seg = nil;
static UIView   *g_p_esp  = nil;
static UIView   *g_p_misc = nil;
static UIView   *g_p_info = nil;
static UILabel  *g_info   = nil;  /* texto vivo de la pagina INFO             */
static UILabel  *g_range_val = nil;
static NSMutableArray *g_sub_switches = nil;  /* switches bajo el maestro    */

static const char *g_via   = "-";     /* donde quedo colgada la UI        */
static BOOL  g_panel_open  = NO;
static int   g_tries       = 0;
static NSTimeInterval g_t0 = 0;
static BOOL  g_ui_ok       = NO;      /* UIApplication ya es segura       */

/* --- ESP v0.2.2: lienzo + cajas + sonda --- */
#define MM_MAX_BOXES 24
typedef struct { CGFloat x, y, w, h; float dist; int alive; } MMEspBox;
static MMEspBox     g_boxes[MM_MAX_BOXES];
static int          g_box_count = 0;  /* cajas listas para pintar         */
static UIView      *g_esp   = nil;    /* lienzo MMCanvasView              */
static CADisplayLink *g_link = nil;   /* latido de dibujo ~30 fps         */
static NSString    *g_probe = nil;    /* texto de la sonda (fase B)       */
static int          g_probe_ok = -1;  /* -1 pendiente / 0 revisar / 1 ok  */

/* prototipos */
static void mm_tick(void);
static void mm_set_panel(BOOL open);
static void mm_position_panel(void);
static void mm_apply_esp_lock(void);
static void mm_apply_stream(void);
static void mm_refresh_info(void);
static void mm_write_status(NSString *nota);
static BOOL mm_def_bool(NSString *k, BOOL d);
static void mm_esp_frame(double t);
static void mm_probe_run(void);

/*---------------------------------------------------------------------------
 * Vista raiz que DEJA PASAR los toques: si nadie (boton/panel) los consume,
 * el toque sigue su camino a la ventana del juego. Sin esto el overlay se
 * comeria los controles.
 *--------------------------------------------------------------------------*/
@interface MMPassView : UIView @end

@implementation MMPassView
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *hit = [super hitTest:point withEvent:event];
    return (hit == self) ? nil : hit;
}
@end

/*---------------------------------------------------------------------------
 * Lienzo del ESP (v0.2.2): pinta las cajas ENCIMA del juego pero DEBAJO del
 * boton y del panel (va el primero dentro de la capa). No recibe toques.
 *--------------------------------------------------------------------------*/
@interface MMCanvasView : UIView @end

@implementation MMCanvasView
- (void)drawRect:(CGRect)rect
{
    if (g_box_count <= 0) return;
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (ctx == NULL) return;

    UIFont *f = [UIFont fontWithName:@"Menlo-Bold" size:11.0];
    if (f == nil) f = [UIFont boldSystemFontOfSize:11.0];
    NSDictionary *attr = @{ NSFontAttributeName: f,
        NSForegroundColorAttributeName:
            [UIColor colorWithRed:1.0 green:0.45 blue:0.45 alpha:1.0] };

    BOOL conNombre = mm_def_bool(@"mm_esp_name", NO);
    BOOL conDist   = mm_def_bool(@"mm_esp_dist", NO);
    BOOL conSalud  = mm_def_bool(@"mm_esp_health", NO);

    CGContextSetLineWidth(ctx, 1.6);
    for (int i = 0; i < g_box_count && i < MM_MAX_BOXES; i++) {
        MMEspBox *b = &g_boxes[i];
        if (!b->alive) continue;
        CGRect r = CGRectMake(b->x, b->y, b->w, b->h);
        CGContextSetRGBStrokeColor(ctx, 1.0, 0.25, 0.25, 0.95);
        CGContextStrokeRect(ctx, r);
        if (conSalud) {
            CGRect hb = CGRectMake(r.origin.x, r.origin.y - 6.0, r.size.width, 3.0);
            CGContextSetRGBFillColor(ctx, 0.25, 1.0, 0.35, 0.9);
            CGContextFillRect(ctx, CGRectMake(hb.origin.x, hb.origin.y,
                                              hb.size.width * 0.7, hb.size.height));
            CGContextSetRGBStrokeColor(ctx, 0.2, 0.6, 0.2, 0.9);
            CGContextStrokeRect(ctx, hb);
        }
        if (conNombre)
            [[NSString stringWithFormat:@"DEMO-%d", i + 1]
             drawAtPoint:CGPointMake(r.origin.x, r.origin.y - 16.0)
             withAttributes:attr];
        if (conDist)
            [[NSString stringWithFormat:@"%d m", (int)(b->dist + 0.5f)]
             drawAtPoint:CGPointMake(r.origin.x, CGRectGetMaxY(r) + 2.0)
             withAttributes:attr];
    }
}
@end

/*---------------------------------------------------------------------------
 * Callbacks de la UI (un singleton para target/action).
 *--------------------------------------------------------------------------*/
@interface MMTargets : NSObject
+ (MMTargets *)shared;
- (void)onFrame:(CADisplayLink *)link;
@end

@implementation MMTargets
+ (MMTargets *)shared
{
    static MMTargets *s = nil;
    if (s == nil) s = [[MMTargets alloc] init];
    return s;
}

- (void)onTap { mm_set_panel(!g_panel_open); }

- (void)onPan:(UIPanGestureRecognizer *)g
{
    @try {
        UIView *v = g.view;
        UIView *root = v.superview;
        if (root == nil) return;
        CGPoint t = [g translationInView:root];
        [g setTranslation:CGPointMake(0.0, 0.0) inView:root];
        CGPoint c = CGPointMake(v.center.x + t.x, v.center.y + t.y);
        CGFloat r = v.bounds.size.width / 2.0;
        c.x = MAX(r + 4.0, MIN(root.bounds.size.width  - r - 4.0,  c.x));
        c.y = MAX(r + 44.0, MIN(root.bounds.size.height - r - 60.0, c.y));
        v.center = c;
        if (g.state == UIGestureRecognizerStateEnded) {
            NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
            [ud setFloat:c.x forKey:@"mm_btn_x"];
            [ud setFloat:c.y forKey:@"mm_btn_y"];
            if (g_panel_open) mm_position_panel();
        }
    } @catch (NSException *e) {
        NSLog(@"%s onPan: %@", MM_TAG, e.reason);
    }
}

- (void)onClose { mm_set_panel(NO); }

- (void)onSeg:(UISegmentedControl *)s
{
    NSInteger i = s.selectedSegmentIndex;
    if (g_p_esp  != nil) g_p_esp.hidden  = (i != 0);
    if (g_p_misc != nil) g_p_misc.hidden = (i != 1);
    if (g_p_info != nil) g_p_info.hidden = (i != 2);
}

- (void)onSwitch:(UISwitch *)s
{
    NSString *k = s.accessibilityIdentifier;
    if (k.length == 0) return;
    [[NSUserDefaults standardUserDefaults] setBool:s.on forKey:k];
    if ([k isEqualToString:@"mm_esp_master"]) mm_apply_esp_lock();
    if ([k isEqualToString:@"mm_stream"])     mm_apply_stream();
    mm_write_status(@"ajuste");
}

- (void)onSlider:(UISlider *)s
{
    [[NSUserDefaults standardUserDefaults] setFloat:s.value forKey:s.accessibilityIdentifier];
    if (g_range_val != nil)
        g_range_val.text = [NSString stringWithFormat:@"%d m", (int)(s.value + 0.5f)];
    mm_write_status(@"ajuste");
}

- (void)onFrame:(CADisplayLink *)link
{
    mm_esp_frame(link.timestamp);
}
@end

/*---------------------------------------------------------------------------
 * Helpers generales (heredados de la fase A)
 *--------------------------------------------------------------------------*/
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

/* La ventana DEL JUEGO. NUNCA creamos ventana propia: era la causa de la
   rotacion a vertical y del bloqueo de toques. Preferimos la visible de nivel
   normal de la escena activa; si no hay, keyWindow; si no, cualquiera. */
static UIWindow *mm_host_window(void)
{
    UIApplication *app = mm_app();
    if (app == nil) return nil;

    UIWindowScene *scene = mm_pick_scene();
    UIWindow *best = nil;
    for (UIWindow *w in app.windows) {
        if (w.hidden || w.alpha < 0.01) continue;
        if (w.windowLevel != UIWindowLevelNormal) continue;
        if (scene != nil && w.windowScene != nil && w.windowScene != scene) continue;
        best = w;               /* el ultimo de la lista = el mas alto */
    }
    if (best != nil) return best;
    if (app.keyWindow != nil) return app.keyWindow;
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

/* defaults con valor por defecto (sin el, boolForKey devuelve NO) */
static BOOL mm_def_bool(NSString *k, BOOL d)
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if ([ud objectForKey:k] == nil) return d;
    return [ud boolForKey:k];
}

static float mm_def_float(NSString *k, float d)
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if ([ud objectForKey:k] == nil) return d;
    return [ud floatForKey:k];
}

/*---------------------------------------------------------------------------
 * ESP v0.2.2 - motor de dibujo.
 *  El CADisplayLink llama a mm_esp_frame() ~30 veces por segundo: decide que
 *  cajas hay y pide repintar el lienzo. Aun NO hay datos reales del juego:
 *  con el ESP maestro ON se pintan 3 cajas DEMO en movimiento (valida el
 *  motor de dibujo en el equipo). La v0.2.3 conecta camara/pawns reales.
 *--------------------------------------------------------------------------*/
static BOOL mm_esp_collect_real(void)
{
    return NO;                          /* v0.2.3: camara + jugadores */
}

static void mm_esp_demo(double t)
{
    CGFloat W = (g_esp != nil && g_esp.bounds.size.width > 1.0)
              ? g_esp.bounds.size.width : 800.0;
    g_box_count = 3;
    for (int i = 0; i < 3; i++) {
        CGFloat bw = 42.0 + (CGFloat)i * 14.0;
        CGFloat bh = bw * 1.9;
        CGFloat cx = W * 0.5 + sin(t * 0.8 + (double)i * 2.1) * (110.0 + 45.0 * i);
        CGFloat cy = 150.0 + (CGFloat)i * 115.0;
        MMEspBox *b = &g_boxes[i];
        b->x = cx - bw / 2.0;
        b->y = cy - bh / 2.0;
        b->w = bw;
        b->h = bh;
        b->dist = 30.0f + (float)i * 37.0f + (float)fmod(t * 8.0, 6.0);
        b->alive = 1;
    }
}

static void mm_esp_frame(double t)
{
    @try {
        if (g_esp == nil) return;
        if (!mm_def_bool(@"mm_esp_master", NO)) {
            if (g_box_count != 0) {
                g_box_count = 0;
                [g_esp setNeedsDisplay];
            }
            if (!g_esp.hidden) g_esp.hidden = YES;
            return;
        }
        if (g_esp.hidden) g_esp.hidden = NO;
        if (!mm_esp_collect_real()) mm_esp_demo(t);
        [g_esp setNeedsDisplay];
    } @catch (NSException *e) {}
}

/*---------------------------------------------------------------------------
 * Sonda de SOLO LECTURA (v0.2.2 - fase B).
 *  Comprueba en el equipo que la tabla methodPointers del juego es legible y
 *  que sus punteros caen en su binario. NO llama a nada del juego: solo lee.
 *  La lectura va con vm_read_overwrite: si la direccion no es valida devuelve
 *  error en vez de tumbar la app (sin eso la sonda seria un riesgo).
 *  Direccion de la tabla (en archivo): VA 0x10C33BFA8, base imagen 0x100000000.
 *--------------------------------------------------------------------------*/
static uint64_t mm_safe_read64(uintptr_t addr, BOOL *ok)
{
    uint64_t v = 0;
    vm_size_t outsz = 0;
    kern_return_t kr = vm_read_overwrite(mach_task_self(), (vm_address_t)addr,
                                         (vm_size_t)sizeof(v),
                                         (vm_address_t)&v, &outsz);
    *ok = (kr == KERN_SUCCESS && outsz == sizeof(v));
    return *ok ? v : 0;
}

static void mm_probe_run(void)
{
    @try {
        const struct mach_header *hdr = _dyld_get_image_header(0);
        if (hdr == NULL) { g_probe = @"sin imagen principal"; g_probe_ok = 0; return; }

        uintptr_t base = (uintptr_t)hdr;
        uintptr_t tbl  = base + (uintptr_t)(0x10C33BFA8ULL - 0x100000000ULL);
        NSMutableString *s = [NSMutableString stringWithFormat:
            @"base=0x%lX tabla=0x%lX",
            (unsigned long)base, (unsigned long)tbl];

        static const struct { int pos; const char *que; } slots[] = {
            {      0, "slot0"          },
            {  11130, "fieldOfView"    },
            {  11250, "WorldToScreen"  },
            {  47790, "get_LocalPawn"  },
            {  54477, "get_Health"     },
            { 142662, "WorldToScreen2" },
            { 236771, "aim(parche)"    },
            {     -1, NULL             },
        };

        int enCod = 0, malos = 0;
        for (int i = 0; slots[i].pos >= 0; i++) {
            BOOL ok = NO;
            uint64_t v = mm_safe_read64(tbl + (uintptr_t)slots[i].pos * 8, &ok);
            if (!ok) { [s appendFormat:@" | %s=ilegible", slots[i].que]; malos++; continue; }
            uint64_t vv = v & 0x0000FFFFFFFFFFFFULL;   /* quita PAC si lo hay */
            const char *img = "?";
            Dl_info di;
            if (vv != 0 && dladdr((const void *)(uintptr_t)vv, &di) && di.dli_fname != NULL) {
                const char *bn = strrchr(di.dli_fname, '/');
                img = (bn != NULL) ? (bn + 1) : di.dli_fname;
            }
            if (strcmp(img, "cod") == 0) enCod++;
            else malos++;
            [s appendFormat:@" | %s=0x%llX(%s)", slots[i].que,
                            (unsigned long long)vv, img];
        }
        g_probe = s;
        g_probe_ok = (malos == 0 && enCod > 0) ? 1 : 0;
        NSLog(@"%s sonda: %@", MM_TAG, s);
    } @catch (NSException *e) {
        g_probe = [NSString stringWithFormat:@"excepcion: %@", e.reason];
        g_probe_ok = 0;
    }
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
            @"boton=%s panel=%s via=%s\n"
            @"esp=%d cajas=%d nombres=%d distancia=%d salud=%d lineas=%d rango=%d\n"
            @"stream=%d\n"
            @"render=%s cajas=%d link=%s\n"
            @"probe=%s\n"
            @"nota=%@\n",
            MODMENU_VERSION, mm_my_path(), (int)mm_uptime(), (int)getpid(),
            NSBundle.mainBundle.bundleIdentifier ?: @"?",
            ios, mm_scene_count(), mm_scene_state(), mm_window_count(),
            (g_btn != nil && g_btn.window != nil) ? "SI" : "NO",
            g_panel_open ? "abierto" : "cerrado", g_via,
            (int)mm_def_bool(@"mm_esp_master", NO),
            (int)mm_def_bool(@"mm_esp_box", NO),
            (int)mm_def_bool(@"mm_esp_name", NO),
            (int)mm_def_bool(@"mm_esp_dist", NO),
            (int)mm_def_bool(@"mm_esp_health", NO),
            (int)mm_def_bool(@"mm_esp_lines", NO),
            (int)mm_def_float(@"mm_esp_range", 150.0f),
            (int)mm_def_bool(@"mm_stream", NO),
            (g_esp != nil && g_esp.superview != nil && !g_esp.hidden) ? "on" : "off",
            g_box_count,
            (g_link != nil && !g_link.paused) ? "activo" : "parado",
            g_probe != nil ? g_probe.UTF8String : "pendiente",
            nota];

        [txt writeToFile:[docs stringByAppendingPathComponent:@"modmenu_status.txt"]
               atomically:YES
                 encoding:NSUTF8StringEncoding
                    error:NULL];
    } @catch (NSException *e) {
        NSLog(@"%s no pude escribir el archivo de estado: %@", MM_TAG, e.reason);
    }
}

/*---------------------------------------------------------------------------
 * Construccion de la UI (la primera vez; luego se reutiliza)
 *--------------------------------------------------------------------------*/

/* Fila generica del panel: titulo a la izquierda + control a la derecha. */
static UIView *mm_row(NSString *titulo, UIView *ctrl)
{
    UIView *r = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 284.0, 34.0)];
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(6.0, 0, 200.0, 34.0)];
    l.text = titulo;
    l.textColor = [UIColor whiteColor];
    l.font = [UIFont systemFontOfSize:13.0];
    [r addSubview:l];
    CGRect cf = ctrl.frame;
    ctrl.frame = CGRectMake(284.0 - cf.size.width - 6.0, (34.0 - cf.size.height) / 2.0,
                            cf.size.width, cf.size.height);
    [r addSubview:ctrl];
    return r;
}

static UIView *mm_switch_row(NSString *titulo, NSString *key, BOOL def)
{
    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 51.0, 31.0)];
    sw.on = mm_def_bool(key, def);
    sw.accessibilityIdentifier = key;
    [sw addTarget:[MMTargets shared] action:@selector(onSwitch:)
        forControlEvents:UIControlEventValueChanged];
    return mm_row(titulo, sw);
}

/* Crea boton flotante + panel (una sola vez). */
static void mm_build_ui(void)
{
    /* --- boton flotante --- */
    if (g_btn == nil) {
        g_btn = [UIButton buttonWithType:UIButtonTypeCustom];
        g_btn.bounds = CGRectMake(0, 0, 54.0, 54.0);
        g_btn.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.55];
        g_btn.layer.cornerRadius = 27.0;
        g_btn.layer.borderWidth = 1.0;
        g_btn.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.6].CGColor;
        [g_btn setTitle:@"MENU" forState:UIControlStateNormal];
        [g_btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        g_btn.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
        [g_btn addTarget:[MMTargets shared] action:@selector(onTap)
        forControlEvents:UIControlEventTouchUpInside];
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]
            initWithTarget:[MMTargets shared] action:@selector(onPan:)];
        [g_btn addGestureRecognizer:pan];
    }

    /* --- lienzo del ESP + latido de dibujo (~30 fps) --- */
    if (g_esp == nil) {
        g_esp = [[MMCanvasView alloc] initWithFrame:CGRectZero];
        g_esp.backgroundColor = [UIColor clearColor];
        g_esp.userInteractionEnabled = NO;
        g_esp.hidden = YES;
    }
    if (g_link == nil) {
        g_link = [CADisplayLink displayLinkWithTarget:[MMTargets shared]
                                             selector:@selector(onFrame:)];
        g_link.preferredFramesPerSecond = 30;
        [g_link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }

    if (g_panel != nil) return;

    /* --- panel --- */
    g_panel = [[UIView alloc] initWithFrame:CGRectMake(0, 0, MM_PANEL_W, MM_PANEL_H)];
    g_panel.backgroundColor = [UIColor colorWithWhite:0.05 alpha:0.90];
    g_panel.layer.cornerRadius = 14.0;
    g_panel.layer.borderWidth = 1.0;
    g_panel.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.25].CGColor;
    g_panel.clipsToBounds = YES;
    g_panel.hidden = YES;
    g_panel.alpha = 0.0;

    UILabel *h = [[UILabel alloc] initWithFrame:CGRectMake(14.0, 9.0, 220.0, 20.0)];
    h.text = [NSString stringWithFormat:@"ModMenu %s", MODMENU_VERSION];
    h.textColor = [UIColor whiteColor];
    h.font = [UIFont boldSystemFontOfSize:15.0];
    [g_panel addSubview:h];

    UIButton *x = [UIButton buttonWithType:UIButtonTypeCustom];
    x.frame = CGRectMake(MM_PANEL_W - 46.0, 5.0, 40.0, 28.0);
    [x setTitle:@"X" forState:UIControlStateNormal];
    [x setTitleColor:[UIColor colorWithWhite:0.85 alpha:1.0] forState:UIControlStateNormal];
    x.titleLabel.font = [UIFont boldSystemFontOfSize:15.0];
    [x addTarget:[MMTargets shared] action:@selector(onClose)
        forControlEvents:UIControlEventTouchUpInside];
    [g_panel addSubview:x];

    g_seg = [[UISegmentedControl alloc] initWithItems:@[@"ESP", @"MISC", @"INFO"]];
    g_seg.frame = CGRectMake(10.0, 36.0, MM_PANEL_W - 20.0, 30.0);
    g_seg.selectedSegmentIndex = 0;
    [g_seg addTarget:[MMTargets shared] action:@selector(onSeg:)
        forControlEvents:UIControlEventValueChanged];
    [g_panel addSubview:g_seg];

    g_p_esp  = [[UIView alloc] initWithFrame:CGRectMake(8.0, 74.0, 284.0, 348.0)];
    g_p_misc = [[UIView alloc] initWithFrame:CGRectMake(8.0, 74.0, 284.0, 348.0)];
    g_p_info = [[UIView alloc] initWithFrame:CGRectMake(8.0, 74.0, 284.0, 348.0)];
    g_p_misc.hidden = YES;
    g_p_info.hidden = YES;
    [g_panel addSubview:g_p_esp];
    [g_panel addSubview:g_p_misc];
    [g_panel addSubview:g_p_info];

    /* --- pagina ESP --- */
    NSArray *keys = @[@"mm_esp_master", @"mm_esp_box", @"mm_esp_name",
                      @"mm_esp_dist", @"mm_esp_health", @"mm_esp_lines"];
    NSArray *titulos = @[@"ESP maestro", @"Cajas", @"Nombres",
                         @"Distancia", @"Salud", @"Lineas"];
    g_sub_switches = [NSMutableArray array];
    for (NSUInteger i = 0; i < keys.count; i++) {
        UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 51.0, 31.0)];
        sw.on = mm_def_bool(keys[i], NO);
        sw.accessibilityIdentifier = keys[i];
        [sw addTarget:[MMTargets shared] action:@selector(onSwitch:)
            forControlEvents:UIControlEventValueChanged];
        UIView *row = mm_row(titulos[i], sw);
        row.frame = CGRectMake(0, 2.0 + (CGFloat)i * 38.0, 284.0, 34.0);
        [g_p_esp addSubview:row];
        if (i > 0) [g_sub_switches addObject:sw];
    }

    float rng = mm_def_float(@"mm_esp_range", 150.0f);

    UILabel *rt = [[UILabel alloc] initWithFrame:CGRectMake(6.0, 236.0, 190.0, 18.0)];
    rt.text = @"Rango ESP (m)";
    rt.textColor = [UIColor whiteColor];
    rt.font = [UIFont systemFontOfSize:13.0];
    [g_p_esp addSubview:rt];

    g_range_val = [[UILabel alloc] initWithFrame:CGRectMake(200.0, 236.0, 78.0, 18.0)];
    g_range_val.text = [NSString stringWithFormat:@"%d m", (int)(rng + 0.5f)];
    g_range_val.textColor = [UIColor colorWithWhite:0.8 alpha:1.0];
    g_range_val.font = [UIFont systemFontOfSize:12.0];
    g_range_val.textAlignment = NSTextAlignmentRight;
    [g_p_esp addSubview:g_range_val];

    UISlider *sl = [[UISlider alloc] initWithFrame:CGRectMake(6.0, 256.0, 272.0, 30.0)];
    sl.minimumValue = 20.0f;
    sl.maximumValue = 300.0f;
    sl.value = rng;
    sl.accessibilityIdentifier = @"mm_esp_range";
    [sl addTarget:[MMTargets shared] action:@selector(onSlider:)
        forControlEvents:UIControlEventValueChanged];
    [g_p_esp addSubview:sl];

    UILabel *na = [[UILabel alloc] initWithFrame:CGRectMake(6.0, 292.0, 272.0, 40.0)];
    na.text = @"DEMO v0.2.2: con el maestro ON veras cajas de prueba moviendose. Los jugadores reales llegan en la proxima build.";
    na.textColor = [UIColor colorWithWhite:0.65 alpha:1.0];
    na.font = [UIFont systemFontOfSize:10.5];
    na.numberOfLines = 2;
    [g_p_esp addSubview:na];

    /* --- pagina MISC --- */
    UIView *r1 = mm_switch_row(@"Stream Mode (atenuar boton)", @"mm_stream", NO);
    r1.frame = CGRectMake(0, 2.0, 284.0, 34.0);
    [g_p_misc addSubview:r1];

    UILabel *d1 = [[UILabel alloc] initWithFrame:CGRectMake(6.0, 48.0, 272.0, 18.0)];
    d1.text = @"Skins: fase D (pendiente)";
    d1.textColor = [UIColor colorWithWhite:0.65 alpha:1.0];
    d1.font = [UIFont systemFontOfSize:11.0];
    [g_p_misc addSubview:d1];

    UILabel *d2 = [[UILabel alloc] initWithFrame:CGRectMake(6.0, 70.0, 272.0, 18.0)];
    d2.text = @"Guest reset: fase D (pendiente)";
    d2.textColor = [UIColor colorWithWhite:0.65 alpha:1.0];
    d2.font = [UIFont systemFontOfSize:11.0];
    [g_p_misc addSubview:d2];

    /* --- pagina INFO --- */
    g_info = [[UILabel alloc] initWithFrame:CGRectMake(6.0, 4.0, 272.0, 330.0)];
    g_info.numberOfLines = 0;
    g_info.textColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    g_info.font = [UIFont fontWithName:@"Menlo" size:10.0] ?: [UIFont systemFontOfSize:10.0];
    [g_p_info addSubview:g_info];

    mm_apply_esp_lock();
}

/*---------------------------------------------------------------------------
 * Colocacion y estado de la UI
 *--------------------------------------------------------------------------*/

static void mm_apply_esp_lock(void)
{
    BOOL on = mm_def_bool(@"mm_esp_master", NO);
    for (UISwitch *s in g_sub_switches)
        s.superview.alpha = on ? 1.0 : 0.5;
}

static void mm_apply_stream(void)
{
    BOOL on = mm_def_bool(@"mm_stream", NO);
    if (g_btn != nil) g_btn.alpha = on ? 0.15 : 1.0;
    if (on && g_panel_open) mm_set_panel(NO);
}

static void mm_position_panel(void)
{
    if (g_panel == nil || g_panel.superview == nil || g_btn == nil) return;
    CGRect rb = g_panel.superview.bounds;
    CGFloat w = MM_PANEL_W, h = MM_PANEL_H;
    CGPoint c = g_btn.center;
    CGFloat x = c.x - w / 2.0;
    CGFloat y = c.y + 34.0;
    x = MAX(8.0, MIN(rb.size.width - w - 8.0, x));
    if (y + h > rb.size.height - 12.0) y = c.y - h - 34.0;   /* si no cabe abajo, arriba */
    y = MAX(34.0, MIN(rb.size.height - h - 12.0, y));
    g_panel.frame = CGRectMake(x, y, w, h);
}

static void mm_set_panel(BOOL open)
{
    @try {
        if (g_panel == nil) return;
        g_panel_open = open;
        if (open) {
            mm_position_panel();
            g_panel.hidden = NO;
            g_panel.alpha = 0.0;
            [UIView animateWithDuration:0.15 animations:^{
                g_panel.alpha = 1.0;
            }];
        } else {
            [UIView animateWithDuration:0.12 animations:^{
                g_panel.alpha = 0.0;
            } completion:^(BOOL done) {
                if (!g_panel_open) g_panel.hidden = YES;
            }];
        }
        mm_refresh_info();
    } @catch (NSException *e) {
        NSLog(@"%s set_panel: %@", MM_TAG, e.reason);
    }
}

/* Texto vivo de la pagina INFO (se refresca en cada tick). */
static void mm_refresh_info(void)
{
    if (g_info == nil) return;
    @try {
        NSString *txt = [NSString stringWithFormat:
            @"build    %s\n"
            @"ruta     %s\n"
            @"pid      %d\n"
            @"ios      %@\n"
            @"escena   %d (%@)\n"
            @"ventanas %d  via %s\n"
            @"uptime   %d s\n"
            @"panel    %@\n"
            @"esp      %@   rango %d m\n"
            @"render   %@   cajas %d\n"
            @"probe    %@\n",
            MODMENU_VERSION,
            mm_my_path(),
            (int)getpid(),
            [UIDevice currentDevice].systemVersion,
            mm_scene_count(),
            mm_scene_state(),
            mm_window_count(),
            g_via,
            (int)mm_uptime(),
            g_panel_open ? @"abierto" : @"cerrado",
            mm_def_bool(@"mm_esp_master", NO) ? @"ON" : @"off",
            (int)mm_def_float(@"mm_esp_range", 150.0f),
            (g_esp != nil && g_esp.superview != nil && !g_esp.hidden) ? @"ON" : @"off",
            g_box_count,
            (g_probe_ok == 1) ? @"ok" : (g_probe == nil ? @"pendiente" : @"revisar")];
        g_info.text = txt;
    } @catch (NSException *e) {}
}

/* Coloca (o recoloca) la UI DENTRO de la ventana del juego. Devuelve YES si
   quedo enganchada. Se ejecuta en el main queue, una vez por tick.
   v0.2.1: ya NO creamos ventana propia (rompia la rotacion y los toques). */
static BOOL mm_place_ui(void)
{
    @try {
        UIWindow *host = mm_host_window();
        if (host == nil) return NO;

        if (g_root == nil) {
            g_root = [[MMPassView alloc] initWithFrame:host.bounds];
            g_root.backgroundColor = [UIColor clearColor];
            g_root.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                                      UIViewAutoresizingFlexibleHeight;
        }

        BOOL recolocar = NO;
        if (g_root.superview != host) {
            [g_root removeFromSuperview];
            g_root.frame = host.bounds;
            [host addSubview:g_root];
            recolocar = YES;
            g_via = "ventana_del_juego";
            NSLog(@"%s UI enganchada a la ventana del juego (nivel=%.0f clase=%@)",
                  MM_TAG, host.windowLevel, NSStringFromClass(host.class));
        }
        if (host.subviews.lastObject != g_root) [host bringSubviewToFront:g_root];

        if (g_btn == nil) mm_build_ui();

        if (g_esp.superview != g_root) {   /* el lienzo va AL FONDO del menu */
            [g_esp removeFromSuperview];
            g_esp.frame = g_root.bounds;
            g_esp.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                                     UIViewAutoresizingFlexibleHeight;
            [g_root insertSubview:g_esp atIndex:0];
        }

        if (g_btn.superview != g_root) {
            [g_btn removeFromSuperview];
            [g_root addSubview:g_btn];
            recolocar = YES;
        }
        if (g_panel.superview != g_root) {
            [g_panel removeFromSuperview];
            [g_root addSubview:g_panel];
            recolocar = YES;
        }

        if (recolocar) {
            CGFloat r = 27.0;
            CGFloat bx = mm_def_float(@"mm_btn_x", 40.0f);
            CGFloat by = mm_def_float(@"mm_btn_y", 150.0f);
            bx = MAX(r + 4.0, MIN(g_root.bounds.size.width  - r - 4.0,  bx));
            by = MAX(r + 44.0, MIN(g_root.bounds.size.height - r - 60.0, by));
            g_btn.center = CGPointMake(bx, by);
            NSLog(@"%s boton+panel listos via=%s", MM_TAG, g_via);
        }

        mm_apply_stream();
        if (g_panel_open) mm_set_panel(YES);

        return YES;
    } @catch (NSException *e) {
        NSLog(@"%s excepcion colocando la UI: %@", MM_TAG, e.reason);
        return NO;
    }
}

/* El latido: coloca la UI, la refresca y deja rastro. Rapido (0.5 s) los
   primeros 60 s; despues lento (5 s) pero PARA SIEMPRE. */
static void mm_tick(void)
{
    @try {
        g_tries++;
        if (!g_ui_ok) g_ui_ok = YES;
        BOOL fast = (g_tries <= MM_FAST_TRIES);
        BOOL ok = mm_place_ui();
        if (g_probe == nil && mm_uptime() > 2.0) mm_probe_run();
        mm_refresh_info();

        if (fast) {
            if (!ok && (g_tries % MM_FAST_LOG_EVERY) == 0)
                NSLog(@"%s esperando escena/ventana... intento %d/%d (escenas=%d ventanas=%d)",
                      MM_TAG, g_tries, MM_FAST_TRIES, mm_scene_count(), mm_window_count());
            if (!ok && g_tries == MM_FAST_TRIES)
                NSLog(@"%s fase rapida agotada; sigo intentando cada %d s",
                      MM_TAG, MM_SLOW_SECS);
        } else {
            NSLog(@"%s latido vivo_s=%d escenas=%d estado=%@ ventanas=%d boton=%s panel=%s via=%s",
                  MM_TAG, (int)mm_uptime(), mm_scene_count(), mm_scene_state(),
                  mm_window_count(), ok ? "SI" : "NO",
                  g_panel_open ? "abierto" : "cerrado", g_via);
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
    g_t0 = [NSDate date].timeIntervalSinceReferenceDate;
    NSLog(@"%s dylib cargada v%s  path=%s  pid=%d",
          MM_TAG, MODMENU_VERSION, mm_my_path(), (int)getpid());
    mm_write_status(@"arranque");

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{ mm_tick(); });
}
