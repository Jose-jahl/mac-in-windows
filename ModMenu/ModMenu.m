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
 *  v0.2.4 (19 oct) - ESP parte 3: SALUD + NOMBRE REAL.
 *    - barra de salud real: con el toggle "Salud" ON se llama a GetHealth
 *      del juego (VA 0x1018B5524, la misma llamada que hace el mod de
 *      referencia) solo para jugadores que ya pasaron todas las guardas; la
 *      vida maxima sale del objeto de salud (*(pawn+0x78) + 0x38, tambien
 *      como GL), todo con las mismas lecturas protegidas;
 *    - nombre real del jugador en la etiqueta: string C# de la entidad
 *      (entidad+0x160 -> longitud en +0x10 -> caracteres UTF-16 en +0x14,
 *      valido con longitud 1..63 como GL); si no hay nombre valido se queda
 *      BOT / JUGADOR;
 *    - si el puntero de GetHealth no valida, el ESP sigue funcionando sin
 *      salud (no tumba la cadena);
 *    - identidad (19 oct): menu en verde + marca de agua "Desarrollado por
 *      Jose Lopez @l0pez9801" abajo a la izquierda (tenue, no recibe toques,
 *      se atenua con Stream Mode).
 *
 *  v0.2.3 (19 oct) - ESP parte 2: DATOS REALES.
 *    - fuera las cajas DEMO; con el ESP maestro ON se leen los jugadores de
 *      verdad y se dibujan sus cajas (color segun jugador/bot, mas etiqueta y
 *      distancia opcionales y lineas opcionales);
 *    - la cadena de datos es la del mod de referencia, verificada en el
 *      laboratorio para la version 1.0.57 del juego: camara -> matrices de
 *      vista/proyeccion -> gameplay -> List<Pawn> -> por cada pawn su vivo,
 *      transform y posicion; la matematica de pantalla es identica a la suya
 *      (misma normalizacion y mismos chequeos), para que los cuadros caigan
 *      donde caen en su mod;
 *    - TODAS las lecturas usan vm_read_overwrite (direccion fuera de mapa =
 *      error, nunca crash) y los 6 punteros de funcion del juego se validan
 *      con dladdr contra la imagen del juego ANTES de llamarlos;
 *    - si la cadena falla en algun paso queda el motivo en la pagina INFO
 *      (linea esp2) y en Documents/modmenu_status.txt (linea esp_real).
 *
 *  v0.2.2 (19 oct) - ESP parte 1: MOTOR DE DIBUJO + SONDA.
 *    - capa de dibujo propia (MMCanvasView) DENTRO de la ventana del juego,
 *      por debajo del boton/panel: pinta cajas con nombre/distancia a ~30 fps
 *      (CADisplayLink);
 *    - sonda de SOLO LECTURA de la tabla methodPointers del juego: lee con
 *      vm_read_overwrite (si una direccion no vale, devuelve error en vez de
 *      tumbar la app) y comprueba que los punteros caen en el binario del
 *      juego; resultado en Documents/modmenu_status.txt (linea probe=).
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

#define MODMENU_VERSION     "0.2.4-esp"
#define MM_TAG              "[MODMENU]"
#define MM_FAST_TRIES       120             /* 120 x 0.5 s = 60 s rapidos  */
#define MM_FAST_LOG_EVERY   20              /* log de espera cada 10 s     */
#define MM_SLOW_SECS        5               /* luego un latido cada 5 s    */
#define MM_PANEL_W          300.0
#define MM_PANEL_H          430.0

/* Marcador global: el CI lo verifica para confirmar que este fuente llego al
   binario (el constructor es static y no sirve como prueba de presencia). */
const char *modmenu_build_id = "modmenu-esp-0.2.4";

/* --- objetos de UI (globales, creados una sola vez) --- */
static UIView   *g_root  = nil;   /* capa transparente sobre la ventana juego */
static UIButton *g_btn   = nil;   /* boton flotante                           */
static UIView   *g_panel = nil;   /* panel desplegable                        */
static UISegmentedControl *g_seg = nil;
static UILabel  *g_marca  = nil;  /* marca de agua v0.2.4 (identidad) */
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

/* --- ESP: lienzo + cajas + sonda --- */
#define MM_MAX_BOXES 24
typedef struct {
    CGFloat x, y, w, h;
    float   dist;
    float   hp;                 /* v0.2.4: salud actual (-1 = sin dato) */
    float   hpMax;              /* v0.2.4: salud maxima (100 por defecto)*/
    int     robot;
    int     alive;
    int     hasName;            /* v0.2.4: 1 si name trae nombre real   */
    char    name[64];           /* v0.2.4: nombre UTF-8 del jugador     */
} MMEspBox;
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
static void mm_esp_collect_real(void);
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

    CGRect bs = self.bounds;
    UIFont *f = [UIFont fontWithName:@"Menlo-Bold" size:11.0];
    if (f == nil) f = [UIFont boldSystemFontOfSize:11.0];

    BOOL conNombre = mm_def_bool(@"mm_esp_name", NO);
    BOOL conDist   = mm_def_bool(@"mm_esp_dist", NO);
    BOOL conLineas = mm_def_bool(@"mm_esp_lines", NO);
    BOOL conSalud  = mm_def_bool(@"mm_esp_health", NO);

    CGContextSetLineWidth(ctx, 1.6);
    for (int i = 0; i < g_box_count && i < MM_MAX_BOXES; i++) {
        MMEspBox *b = &g_boxes[i];
        if (!b->alive) continue;
        CGRect r = CGRectMake(b->x, b->y, b->w, b->h);

        CGFloat cr = 1.00, cg = 0.25, cb = 0.25;            /* jugador: rojo  */
        if (b->robot) { cr = 1.00; cg = 0.72; cb = 0.20; }  /* bot: ambar     */

        if (conLineas) {
            CGContextSetRGBStrokeColor(ctx, cr, cg, cb, 0.55);
            CGContextMoveToPoint(ctx, bs.size.width / 2.0, bs.size.height);
            CGContextAddLineToPoint(ctx, CGRectGetMidX(r), CGRectGetMaxY(r));
            CGContextStrokePath(ctx);
        }

        CGContextSetRGBStrokeColor(ctx, cr, cg, cb, 0.95);
        CGContextStrokeRect(ctx, r);

        /* v0.2.4: barra de salud a la izquierda de la caja */
        if (conSalud && b->hp >= 0.0f && b->hpMax > 1.0f) {
            float fr = b->hp / b->hpMax;
            if (fr < 0.0f) fr = 0.0f;
            if (fr > 1.0f) fr = 1.0f;
            CGFloat bwv = 3.0;
            CGFloat bx  = r.origin.x - 6.0;
            CGFloat by  = r.origin.y;
            CGFloat bhh = r.size.height;
            CGContextSetRGBFillColor(ctx, 0.0, 0.0, 0.0, 0.45);
            CGContextFillRect(ctx, CGRectMake(bx, by, bwv, bhh));
            CGFloat rr2 = 1.00, gg2 = 0.25;
            if (fr > 0.5f)       { rr2 = 0.25; gg2 = 1.00; }
            else if (fr > 0.25f) { rr2 = 1.00; gg2 = 0.80; }
            CGFloat fh2 = bhh * fr;
            CGContextSetRGBFillColor(ctx, rr2, gg2, 0.25, 0.95);
            CGContextFillRect(ctx, CGRectMake(bx, by + bhh - fh2, bwv, fh2));
        }

        NSDictionary *attr = @{ NSFontAttributeName: f,
            NSForegroundColorAttributeName:
                [UIColor colorWithRed:cr green:cg blue:cb alpha:1.0] };
        if (conNombre) {
            NSString *nm = nil;
            if (b->hasName) nm = [NSString stringWithUTF8String:b->name];
            if (nm == nil || nm.length == 0)
                nm = (b->robot ? @"BOT" : @"JUGADOR");
            [nm drawAtPoint:CGPointMake(r.origin.x, r.origin.y - 15.0)
             withAttributes:attr];
        }
        if (conDist && b->dist > 0.5f)
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
 * ESP v0.2.3 - motor de dibujo.
 *  El CADisplayLink llama a mm_esp_frame() ~30 veces por segundo: los datos
 *  del juego se leen a ~15 Hz (mm_esp_collect_real, bloque mas abajo) y el
 *  lienzo se repinta a 30 fps. Sin el maestro ON no se toca NADA del juego.
 *--------------------------------------------------------------------------*/
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

        static int s_tick = 0;              /* datos ~15 Hz, pintado a 30 fps */
        if ((s_tick++ & 1) == 0) mm_esp_collect_real();
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

/*---------------------------------------------------------------------------
 * ESP v0.2.3 - DATOS REALES (cadena verificada para la version 1.0.57).
 *
 *  camera   = Camera.get_main()                     (thunk del motor)
 *  view     = camera.worldToCameraMatrix_Injected() (4x4; x0 = camara, x1 = salida)
 *  proj     = camera.projectionMatrix_Injected()    (4x4; x0 = camara, x1 = salida)
 *  gameplay = GetGameplayInstance()                 (singleton)
 *  lista    = *(gameplay + 0x178)                   List<Pawn>
 *  items    = *(lista + 0x10)                       array IL2CPP (datos en +0x20)
 *  n        = *(int *)(lista + 0x18)
 *  por pawn: vivo = byte[pawn+0x548]; transform = *(pawn+0x308);
 *            entidad = *(pawn+0x5C0); robot = byte[entidad+0x298];
 *            pos = Transform.get_position_Injected(transform, &v3)
 *
 *  Lecturas SIEMPRE con vm_read_overwrite (direccion fuera de mapa = error,
 *  no crash) y los punteros de funcion se validan con dladdr contra la
 *  imagen del juego antes de llamarlos. La proyeccion a pantalla replica la
 *  matematica del mod de referencia (matrices + clip.z >= 0.01 + division por
 *  clip.w y el mismo mapeo a pixeles).
 *--------------------------------------------------------------------------*/

#define MM_GAME_DELTA(va)   ((uintptr_t)((va) - 0x100000000ULL))

#define VA_GAMEPLAY         0x1023DD388ULL  /* GetGameplayInstance()            */
#define VA_LOCALPAWN        0x1023DE550ULL  /* getLocalPawn()                   */
#define VA_MAINCAM          0x108BDBE98ULL  /* Camera.get_main() (thunk)        */
#define VA_W2C_INJ          0x108BDABC0ULL  /* worldToCameraMatrix_Injected     */
#define VA_PROJ_INJ         0x108BDACF8ULL  /* projectionMatrix_Injected        */
#define VA_TRANSPOS         0x108C63B10ULL  /* Transform.get_position_Injected  */
#define VA_HEALTH           0x1018B5524ULL  /* GetHealth() (x0=pawn -> w0 int)  */

#define OFF_GP_LIST         0x178   /* gameplay -> List<Pawn>               */
#define OFF_LIST_ITEMS      0x10    /* List -> array IL2CPP                 */
#define OFF_LIST_SIZE       0x18    /* List -> int size                     */
#define OFF_ARR_DATA        0x20    /* array IL2CPP -> primer elemento      */
#define OFF_PAWN_ALIVE      0x548   /* pawn -> byte vivo                    */
#define OFF_PAWN_TRANSFORM  0x308   /* pawn -> Transform                    */
#define OFF_PAWN_ENTITY     0x5C0   /* pawn -> entidad                      */
#define OFF_ENT_ROBOT       0x298   /* entidad -> byte robot                */
#define OFF_PAWN_MODEL      0x78    /* pawn -> objeto de salud              */
#define OFF_MODEL_MAXHP     0x38    /* objeto de salud -> float vida maxima */
#define OFF_ENT_NAME        0x160   /* entidad -> string C# del nombre      */
#define OFF_STR_LEN         0x10    /* string -> int longitud               */
#define OFF_STR_CHARS       0x14    /* string -> chars UTF-16               */

typedef void *(*MMGetPtrFn)(void);
typedef void  (*MMMatFn)(void *self, void *out64);
typedef void  (*MMVec3Fn)(void *self, float *out3);
typedef int32_t (*MMGetIntFn)(void *self);

static uintptr_t  g_game_base    = 0;
static MMGetPtrFn g_fp_gameplay  = NULL;
static MMGetPtrFn g_fp_localpawn = NULL;
static MMGetPtrFn g_fp_maincam   = NULL;
static MMMatFn    g_fp_w2c       = NULL;
static MMMatFn    g_fp_proj      = NULL;
static MMVec3Fn   g_fp_transpos  = NULL;
static MMGetIntFn g_fp_health    = NULL; /* opcional: si no valida, sin salud */
static int        g_fp_state     = -1;  /* -1 sin probar / 0 error / 1 ok */
static NSString  *g_esp_diag     = nil; /* motivo del ultimo fallo / ok   */
static int        g_esp_players  = 0;   /* ultima cuenta de la lista      */

/* lectura protegida de un rango (misma idea que la sonda de la v0.2.2) */
static BOOL mm_vm_read(uintptr_t addr, void *dst, size_t n)
{
    vm_size_t outsz = 0;
    kern_return_t kr = vm_read_overwrite(mach_task_self(), (vm_address_t)addr,
                                         (vm_size_t)n, (vm_address_t)dst, &outsz);
    return (kr == KERN_SUCCESS && outsz == (vm_size_t)n);
}

static BOOL mm_r64(uintptr_t addr, uint64_t *out)
{
    BOOL ok = NO;
    uint64_t v = mm_safe_read64(addr, &ok);
    if (ok && out != NULL) *out = v;
    return ok;
}

/* el puntero cae dentro de la imagen del juego? Acepta dos senales (dladdr
   es read-only): que la base coincida, o que el nombre de la imagen sea el
   del binario del juego (la sonda v0.2.2 comprobo en el equipo que dladdr
   sobre punteros del juego devuelve la imagen "cod"). */
static BOOL mm_ptr_en_imagen(const void *p, uintptr_t base)
{
    Dl_info di;
    if (p == NULL || base == 0) return NO;
    if (!dladdr(p, &di)) return NO;
    if ((uintptr_t)di.dli_fbase == base) return YES;
    if (di.dli_fname != NULL) {
        const char *bn = strrchr(di.dli_fname, '/');
        bn = (bn != NULL) ? (bn + 1) : di.dli_fname;
        if (strcmp(bn, "cod") == 0) return YES;
    }
    return NO;
}

/* Resuelve los 6 punteros del juego validandolos uno a uno. Prueba primero
   la imagen 0 (probada buena por la sonda v0.2.2) y si no cuaja busca la
   imagen "UserAssembly" (el nombre que usa el mod de referencia). */
static void mm_game_resolve(void)
{
    @try {
        g_fp_state = 0;
        uintptr_t head0 = (uintptr_t)_dyld_get_image_header(0);
        uintptr_t ua = 0;
        uint32_t nimg = _dyld_image_count();
        for (uint32_t i = 0; i < nimg; i++) {
            const char *nm = _dyld_get_image_name(i);
            if (nm != NULL && strstr(nm, "UserAssembly") != NULL) {
                ua = (uintptr_t)_dyld_get_image_header(i);
                break;
            }
        }
        uintptr_t bases[2];
        int nb = 0;
        if (head0 != 0) bases[nb++] = head0;
        if (ua != 0 && ua != head0) bases[nb++] = ua;

        for (int k = 0; k < nb; k++) {
            uintptr_t b = bases[k];
            MMGetPtrFn fp0 = (MMGetPtrFn)(b + MM_GAME_DELTA(VA_GAMEPLAY));
            MMGetPtrFn fp1 = (MMGetPtrFn)(b + MM_GAME_DELTA(VA_LOCALPAWN));
            MMGetPtrFn fp2 = (MMGetPtrFn)(b + MM_GAME_DELTA(VA_MAINCAM));
            MMMatFn    fp3 = (MMMatFn)(b + MM_GAME_DELTA(VA_W2C_INJ));
            MMMatFn    fp4 = (MMMatFn)(b + MM_GAME_DELTA(VA_PROJ_INJ));
            MMVec3Fn   fp5 = (MMVec3Fn)(b + MM_GAME_DELTA(VA_TRANSPOS));
            MMGetIntFn fp6 = (MMGetIntFn)(b + MM_GAME_DELTA(VA_HEALTH));

            if (!mm_ptr_en_imagen((const void *)fp0, b) ||
                !mm_ptr_en_imagen((const void *)fp1, b) ||
                !mm_ptr_en_imagen((const void *)fp2, b) ||
                !mm_ptr_en_imagen((const void *)fp3, b) ||
                !mm_ptr_en_imagen((const void *)fp4, b) ||
                !mm_ptr_en_imagen((const void *)fp5, b))
                continue;

            /* el de salud es OPCIONAL: si no valida, el ESP sigue sin barra */
            BOOL hpOk = mm_ptr_en_imagen((const void *)fp6, b);

            g_game_base    = b;
            g_fp_gameplay  = fp0;
            g_fp_localpawn = fp1;
            g_fp_maincam   = fp2;
            g_fp_w2c       = fp3;
            g_fp_proj      = fp4;
            g_fp_transpos  = fp5;
            g_fp_health    = hpOk ? fp6 : NULL;
            g_fp_state     = 1;
            NSLog(@"%s ESP cadena lista: base=0x%lX imagen=%d cam=%p gp=%p pawn=%p tr=%p cams=%p/%p hp=%s",
                  MM_TAG, (unsigned long)b, k,
                  (void *)g_fp_maincam,
                  (void *)g_fp_gameplay,
                  (void *)g_fp_localpawn,
                  (void *)g_fp_transpos,
                  (void *)g_fp_w2c,
                  (void *)g_fp_proj,
                  hpOk ? "ok" : "no");
            return;
        }

        g_esp_diag = @"punteros fuera de la imagen del juego";
        NSLog(@"%s ESP: no pude validar los punteros del juego (imagenes=%d)", MM_TAG, (int)nimg);
    } @catch (NSException *e) {
        g_fp_state = 0;
        g_esp_diag = [NSString stringWithFormat:@"resolver: %@", e.reason];
    }
}

/* Proyeccion mundo->pantalla IDENTICA al mod de referencia:
     view = M * (x,y,z,1)            (columnas; chunks de 16 bytes)
     clip = P * view
     si !(clip.z >= 0.01) -> fuera
     cabeza: clip.y += 0.5
     ndc  = clip.xyz / clip.w        (si |w| <= 0.001 -> 0)
     px   = ndc.x + W/2 + ndc.x*(W/2)
     py   = ndc.y + H/2 - ndc.y*(H/2) */
static BOOL mm_w2s(const float *view, const float *proj, const float p[3],
                   BOOL cabeza, CGFloat W, CGFloat H, CGPoint *out)
{
    float x = p[0], y = p[1], z = p[2];
    float vx = view[0] * x + view[4] * y + view[8]  * z + view[12];
    float vy = view[1] * x + view[5] * y + view[9]  * z + view[13];
    float vz = view[2] * x + view[6] * y + view[10] * z + view[14];
    float vw = view[3] * x + view[7] * y + view[11] * z + view[15];

    float cx = proj[0] * vx + proj[4] * vy + proj[8]  * vz + proj[12] * vw;
    float cy = proj[1] * vx + proj[5] * vy + proj[9]  * vz + proj[13] * vw;
    float cz = proj[2] * vx + proj[6] * vy + proj[10] * vz + proj[14] * vw;
    float cw = proj[3] * vx + proj[7] * vy + proj[11] * vz + proj[15] * vw;

    if (!(cz >= 0.01f)) return NO;
    if (cabeza) cy += 0.5f;

    float nx = 0.0f, ny = 0.0f;
    if (cw >= 0.001f || cw <= -0.001f) { nx = cx / cw; ny = cy / cw; }
    if (!isfinite(nx) || !isfinite(ny)) return NO;

    out->x = (CGFloat)(nx + (float)W / 2.0f + nx * ((float)W / 2.0f));
    out->y = (CGFloat)(ny + (float)H / 2.0f - ny * ((float)H / 2.0f));
    return YES;
}

/* Una pasada de ESP real (~15 Hz). Deja el motivo en g_esp_diag. */
static void mm_esp_collect_real(void)
{
    g_box_count = 0;
    g_esp_players = 0;
    if (g_fp_state != 1) mm_game_resolve();
    if (g_fp_state != 1) return;

    CGFloat W = 0.0, H = 0.0;
    @try {
        CGSize sz = UIScreen.mainScreen.bounds.size;
        W = sz.width;
        H = sz.height;
    } @catch (NSException *e) {}
    if (W < 10.0 || H < 10.0) {
        W = (g_esp != nil) ? g_esp.bounds.size.width  : 0.0;
        H = (g_esp != nil) ? g_esp.bounds.size.height : 0.0;
    }
    if (W < 10.0 || H < 10.0) { g_esp_diag = @"sin medidas de pantalla"; return; }

    float view[16], proj[16];

    /* camara + matrices de vista/proyeccion */
    void *cam = g_fp_maincam();
    uint64_t chk = 0;
    if (cam == NULL) { g_esp_diag = @"esperando camara"; return; }
    if (!mm_r64((uintptr_t)cam, &chk)) { g_esp_diag = @"camara ilegible"; return; }
    g_fp_w2c(cam, view);
    g_fp_proj(cam, proj);

    /* gameplay + lista de jugadores */
    void *gp = g_fp_gameplay();
    if (gp == NULL) { g_esp_diag = @"esperando partida (gameplay)"; return; }
    uint64_t lst = 0;
    if (!mm_r64((uintptr_t)gp + OFF_GP_LIST, &lst) || lst == 0) {
        g_esp_diag = @"esperando partida (lista)";
        return;
    }
    uint8_t lh[0x20];
    if (!mm_vm_read((uintptr_t)lst, lh, sizeof(lh))) { g_esp_diag = @"lista ilegible"; return; }
    uint64_t items = 0;
    uint32_t sz = 0;
    memcpy(&items, lh + OFF_LIST_ITEMS, 8);
    memcpy(&sz,    lh + OFF_LIST_SIZE,  4);
    if (items == 0) { g_esp_diag = @"lista sin datos"; return; }
    int total = (int)sz;
    if (total < 0) total = 0;
    if (total > 999) total = 999;
    g_esp_players = total;
    int loopn = (total > MM_MAX_BOXES) ? MM_MAX_BOXES : total;

    /* jugador local: para la distancia y para no dibujarlo */
    void *localPawn = g_fp_localpawn();
    float lpos[3] = { 0.0f, 0.0f, 0.0f };
    BOOL haveLocal = NO;
    if (localPawn != NULL) {
        uint64_t ltr = 0, lchk = 0;
        if (mm_r64((uintptr_t)localPawn + OFF_PAWN_TRANSFORM, &ltr) && ltr != 0 &&
            mm_r64((uintptr_t)ltr, &lchk)) {
            g_fp_transpos((void *)(uintptr_t)ltr, lpos);
            haveLocal = isfinite(lpos[0]) && isfinite(lpos[1]) && isfinite(lpos[2]);
        }
    }

    float rango = mm_def_float(@"mm_esp_range", 150.0f);
    BOOL conSalud = mm_def_bool(@"mm_esp_health", NO);   /* v0.2.4 */
    int drawn = 0;

    for (int i = 0; i < loopn && drawn < MM_MAX_BOXES; i++) {
        uint64_t pawn = 0;
        if (!mm_r64((uintptr_t)items + OFF_ARR_DATA + (uintptr_t)i * 8, &pawn) || pawn == 0)
            continue;
        if (localPawn != NULL && (void *)(uintptr_t)pawn == localPawn) continue;

        uint64_t a = 0;
        if (!mm_r64((uintptr_t)pawn + OFF_PAWN_ALIVE, &a) || (a & 0xFF) == 0) continue;

        int robot = 0;
        uint64_t ent = 0;
        if (mm_r64((uintptr_t)pawn + OFF_PAWN_ENTITY, &ent) && ent != 0) {
            uint64_t rb = 0;
            if (mm_r64((uintptr_t)ent + OFF_ENT_ROBOT, &rb)) robot = (int)(rb & 0xFF);
        }

        uint64_t tr = 0, tchk = 0;
        if (!mm_r64((uintptr_t)pawn + OFF_PAWN_TRANSFORM, &tr) || tr == 0) continue;
        if (!mm_r64((uintptr_t)tr, &tchk)) continue;

        float wp[3] = { 0.0f, 0.0f, 0.0f };
        g_fp_transpos((void *)(uintptr_t)tr, wp);
        if (!isfinite(wp[0]) || !isfinite(wp[1]) || !isfinite(wp[2])) continue;
        if (fabsf(wp[0]) > 20000.0f || fabsf(wp[1]) > 20000.0f || fabsf(wp[2]) > 20000.0f)
            continue;

        float dist = 0.0f;
        if (haveLocal) {
            float dx = wp[0] - lpos[0], dy = wp[1] - lpos[1], dz = wp[2] - lpos[2];
            dist = sqrtf(dx * dx + dy * dy + dz * dz);
            if (dist > rango) continue;
        }

        CGPoint pies, cab;
        if (!mm_w2s(view, proj, wp, NO,  W, H, &pies)) continue;
        if (!mm_w2s(view, proj, wp, YES, W, H, &cab))  continue;
        if (pies.x < -W || pies.x > 2.0 * W || pies.y < -H || pies.y > 2.0 * H) continue;

        CGFloat bh = pies.y - cab.y;
        if (bh < 4.0 || bh > 2.0 * H) continue;
        CGFloat bw = bh * 0.45;

        /* --- v0.2.4: salud (solo con el toggle ON; misma llamada que GL,
           despues de todas las guardas: pawn mapeado y vivo) --- */
        float hp = -1.0f;
        float hpMax = 100.0f;
        if (conSalud && g_fp_health != NULL) {
            uint64_t pk = 0;
            if (mm_r64((uintptr_t)pawn, &pk)) {
                int32_t h = g_fp_health((void *)(uintptr_t)pawn);
                if (h >= 0 && h <= 1000000) hp = (float)h;
            }
            uint64_t mdl = 0;
            if (mm_r64((uintptr_t)pawn + OFF_PAWN_MODEL, &mdl) && mdl != 0) {
                float m = 0.0f;
                if (mm_vm_read((uintptr_t)mdl + OFF_MODEL_MAXHP, &m, sizeof(m)) &&
                    isfinite(m) && m > 0.5f && m < 100000.0f)
                    hpMax = m;
            }
        }

        /* --- v0.2.4: nombre real (entidad+0x160; string C#: len 1..63) --- */
        char nm[64] = { 0 };
        if (ent != 0) {
            uint64_t so = 0;
            if (mm_r64((uintptr_t)ent + OFF_ENT_NAME, &so) && so != 0) {
                int32_t slen = 0;
                if (mm_vm_read((uintptr_t)so + OFF_STR_LEN, &slen, sizeof(slen)) &&
                    slen >= 1 && slen <= 63) {
                    uint16_t wbuf[64];
                    if (mm_vm_read((uintptr_t)so + OFF_STR_CHARS, wbuf,
                                   (size_t)slen * 2)) {
                        BOOL legible = YES;
                        for (int32_t c = 0; c < slen; c++) {
                            uint16_t ch = wbuf[c];
                            if (ch < 0x20 || ch == 0x7F) { legible = NO; break; }
                        }
                        if (legible) {
                            NSString *s = [[NSString alloc]
                                initWithCharacters:(const unichar *)wbuf
                                length:(NSUInteger)slen];
                            const char *u8 = s.UTF8String;
                            if (u8 != NULL) {
                                strncpy(nm, u8, sizeof(nm) - 1);
                                nm[sizeof(nm) - 1] = 0;
                            }
                        }
                    }
                }
            }
        }

        MMEspBox *b = &g_boxes[drawn];
        b->x = cab.x - bw / 2.0;
        b->y = cab.y;
        b->w = bw;
        b->h = bh;
        b->dist = dist;
        b->hp = hp;
        b->hpMax = hpMax;
        b->robot = robot;
        b->alive = 1;
        b->hasName = (nm[0] != 0) ? 1 : 0;
        memcpy(b->name, nm, sizeof(b->name));
        drawn++;
    }

    g_box_count = drawn;
    g_esp_diag = [NSString stringWithFormat:@"cam=ok lista=%d cajas=%d hp=%s",
                  total, drawn, (g_fp_health != NULL) ? "ok" : "no"];
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
            @"esp_real=%@ jugadores=%d\n"
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
            (g_esp_diag != nil) ? g_esp_diag : @"-", g_esp_players,
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

/* Verde de identidad (19 oct): tema del menu + detalles. */
static UIColor *mm_verde(void)
{
    return [UIColor colorWithRed:0.16 green:0.88 blue:0.38 alpha:1.0];
}

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
    sw.onTintColor = mm_verde();
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
        g_btn.backgroundColor = [UIColor colorWithRed:0.02 green:0.10 blue:0.04 alpha:0.72];
        g_btn.layer.cornerRadius = 27.0;
        g_btn.layer.borderWidth = 1.5;
        g_btn.layer.borderColor = mm_verde().CGColor;
        [g_btn setTitle:@"MENU" forState:UIControlStateNormal];
        [g_btn setTitleColor:[UIColor colorWithRed:0.78 green:1.0 blue:0.84 alpha:1.0]
                    forState:UIControlStateNormal];
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
    g_panel.backgroundColor = [UIColor colorWithRed:0.02 green:0.09 blue:0.04 alpha:0.93];
    g_panel.layer.cornerRadius = 14.0;
    g_panel.layer.borderWidth = 1.2;
    g_panel.layer.borderColor = [UIColor colorWithRed:0.16 green:0.88 blue:0.38 alpha:0.65].CGColor;
    g_panel.clipsToBounds = YES;
    g_panel.hidden = YES;
    g_panel.alpha = 0.0;

    UILabel *h = [[UILabel alloc] initWithFrame:CGRectMake(14.0, 9.0, 220.0, 20.0)];
    h.text = [NSString stringWithFormat:@"ModMenu %s", MODMENU_VERSION];
    h.textColor = [UIColor colorWithRed:0.55 green:1.0 blue:0.66 alpha:1.0];
    h.font = [UIFont boldSystemFontOfSize:15.0];
    [g_panel addSubview:h];

    UIButton *x = [UIButton buttonWithType:UIButtonTypeCustom];
    x.frame = CGRectMake(MM_PANEL_W - 46.0, 5.0, 40.0, 28.0);
    [x setTitle:@"X" forState:UIControlStateNormal];
    [x setTitleColor:[UIColor colorWithRed:0.55 green:1.0 blue:0.66 alpha:1.0] forState:UIControlStateNormal];
    x.titleLabel.font = [UIFont boldSystemFontOfSize:15.0];
    [x addTarget:[MMTargets shared] action:@selector(onClose)
        forControlEvents:UIControlEventTouchUpInside];
    [g_panel addSubview:x];

    g_seg = [[UISegmentedControl alloc] initWithItems:@[@"ESP", @"MISC", @"INFO"]];
    g_seg.frame = CGRectMake(10.0, 36.0, MM_PANEL_W - 20.0, 30.0);
    g_seg.selectedSegmentIndex = 0;
    if ([g_seg respondsToSelector:@selector(setSelectedSegmentTintColor:)])
        g_seg.selectedSegmentTintColor =
            [UIColor colorWithRed:0.10 green:0.55 blue:0.25 alpha:1.0];
    else
        g_seg.tintColor = mm_verde();
    [g_seg setTitleTextAttributes:@{ NSForegroundColorAttributeName:
            [UIColor colorWithWhite:0.88 alpha:1.0] }
                          forState:UIControlStateNormal];
    [g_seg setTitleTextAttributes:@{ NSForegroundColorAttributeName:
            [UIColor whiteColor] }
                          forState:UIControlStateSelected];
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
        sw.onTintColor = mm_verde();
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
    sl.tintColor = mm_verde();
    sl.thumbTintColor = [UIColor colorWithRed:0.80 green:1.0 blue:0.86 alpha:1.0];
    [sl addTarget:[MMTargets shared] action:@selector(onSlider:)
        forControlEvents:UIControlEventValueChanged];
    [g_p_esp addSubview:sl];

    UILabel *na = [[UILabel alloc] initWithFrame:CGRectMake(6.0, 292.0, 272.0, 40.0)];
    na.text = @"v0.2.4: datos reales + salud y nombre real. Rojo = jugador, ambar = bot. Si no aparecen cajas mira INFO (esp2) o modmenu_status.txt.";
    na.textColor = [UIColor colorWithWhite:0.65 alpha:1.0];
    na.font = [UIFont systemFontOfSize:10.5];
    na.numberOfLines = 3;
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
    if (g_marca != nil) g_marca.alpha = on ? 0.15 : 1.0;
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
            @"esp2     %@\n"
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
            (g_esp_diag != nil) ? g_esp_diag : @"-",
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

        /* marca de agua (v0.2.4): credito tenue abajo a la izquierda. No
           recibe toques (UILabel no interactivo => el juego sigue vivo) y
           va POR DEBAJO del boton/panel (indice 1; el lienzo esta en 0). */
        if (g_marca == nil) {
            g_marca = [[UILabel alloc] init];
            g_marca.text = @"Desarrollado por Jose Lopez  @l0pez9801";
            g_marca.font = [UIFont boldSystemFontOfSize:10.0];
            g_marca.textColor =
                [UIColor colorWithRed:0.16 green:0.88 blue:0.38 alpha:0.38];
            g_marca.backgroundColor = [UIColor clearColor];
            g_marca.userInteractionEnabled = NO;
        }
        if (g_marca.superview != g_root) {
            [g_marca removeFromSuperview];
            [g_root insertSubview:g_marca atIndex:1];
        }
        [g_marca sizeToFit];
        {
            CGRect rm = g_marca.frame;
            rm.origin.x = 12.0;
            rm.origin.y = g_root.bounds.size.height - rm.size.height - 10.0;
            g_marca.frame = rm;
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
