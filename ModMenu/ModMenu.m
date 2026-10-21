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
 *  v0.3.1 (20 oct) - INTERFAZ GLASS NEON (SOLO UI).
 *    - panel y boton con vidrio oscuro (UIBlurEffectStyleDark) + gradiente
 *      animado verde/morado (CAGradientLayer), borde neon que cambia y glow;
 *    - cabecera, pestanas y boton reestilados; los toggles y el ESP no cambian;
 *    - no toca aim, NoJB, SKINS ni anogs y no anade frameworks: UIKit,
 *      QuartzCore y CoreGraphics ya estaban enlazados por el CI.
 *
 *  v0.3.0 (20 oct) - STREAM MODE + PULIDO DEL ESP.
 *    - nueva pagina VIS: Stream Mode (oculta panel y marca de agua; el boton
 *      queda al 10% y sigue tocable para volver a abrirlo), contador de
 *      jugadores/bots dibujados, estilo de caja (completa/esquinas) y tema de
 *      color (clasico/neon/blanco);
 *    - Stream Mode ya NO cierra el panel en cada latido: el operador puede
 *      reabrir el menu con el boton atenuado y apagarlo cuando quiera;
 *    - las nuevas opciones (mm_esp_count, mm_esp_box_style, mm_esp_theme) se
 *      resetean al arranque igual que el resto de opciones.
 *
 *  v0.2.9 (19 oct) - FASE D COMPLETA: SKINS (ARMAS + TRAJE) Y GUEST RESET.
 *    - nueva pagina SKINS: maestro, captura de IDs reales, campos de ID de
 *      arma y de traje, 5 presets verificados (0x0F6951, 0x0F9062, 0x0FB773,
 *      0x0FDE84, 0x100595), boton Aplicar y Dump IDs;
 *    - los hooks de skin se instalan SOLO con el maestro o la captura ON y se
 *      restauran al apagarlos. Antes de escribir se comprueba el prologo de
 *      1.0.57; si no coincide, el sitio se salta (nunca se parchea a ciegas);
 *    - trampolin real (no el de GL): una funcion naked ejecuta los primeros
 *      16 bytes originales y salta a entry+16, asi el hook PUEDE llamar al
 *      original sin recursion. Offsets verificados: 0x2A90084 (arma),
 *      0x587CFD4 (inventario) y 0x1049844 (traje; el 0x1049835 de GL estaba
 *      desalineado y corrompia la funcion anterior);
 *    - captura pasiva: con Capturar ON los hooks llaman al original, registran
 *      los IDs y escriben Documents/CODM_SkinDump.txt (sin cambiar nada);
 *    - MISC: Reset guest con confirmacion; borra Documents, Library/Application
 *      Support, Library/Caches, Library/Preferences y tmp, limpia la keychain
 *      de contrasenas genericas y cierra con _exit(0) tras el aviso;
 *    - las opciones nuevas tambien se resetean en cada arranque (v0.2.7).
 *
 *  v0.2.8b (19 oct) - HOTFIX DEL TEST: SIN ANOGS.
 *    - el test de la 0.2.8 en el equipo crasheo a los pocos segundos de
 *      abrir, justo cuando el hilo NoJB armaba p00/p01 (t = 8 s). Esta build
 *      retira los dos parches: NO se escribe en anogs. Se conservan los 39
 *      swizzles, que no tocan codigo ejecutable de frameworks ajenas;
 *    - el codigo de anogs queda compilado pero apagado con
 *      g_nojb_anogs_enabled = NO, para reactivarlo solo cuando se identifique
 *      la causa (o se migre a dlsym con verificacion de prologo).
 *
 *  v0.2.8 (19 oct) - FASE C, parte 1: NOJB (ANTIDETECT).
 *    - se replican los 39 swizzles ObjC del mod de referencia (GL), leidos de
 *      su dylib en el laboratorio: checksums (APMRemoteConfig.checksumEnabled,
 *      GNLCommonTools._checksumOfCRC32:, QCloudSimplePing...), identificadores
 *      anonimos (AppsFlyer / FBSDK / FBAd), watchdog de hilos de APM y TODOS
 *      los metodos de MSWeakTimer. Todos devuelven 0 o no-op, igual que GL;
 *    - de la tabla de 10 parches de anogs de GL solo se usan los 2 sitios que
 *      en 1.0.57 caen EXACTAMENTE en la entrada de una funcion
 *      (_AnoSDKGetReportData y _AnoSDKDelReportData). Los otros 8 caen a media
 *      funcion: parchearlos ahi dejaria la pila desbalanceada (crash), asi que
 *      NO se tocan; queda anotado para futuras versiones;
 *    - todo con guardas: clase/metodo ausente = se salta y se registra; nunca
 *      se toca un metodo heredado de NSObject (swizzlearlo romperia la app);
 *      antes de escribir en anogs se comparan los bytes del sitio con los
 *      esperados de 1.0.57 y, si no coinciden, NO se escribe nada;
 *    - reintentos en segundo plano (las frameworks cargan tarde) y resultado
 *      visible en la pagina INFO y en Documents/modmenu_status.txt (nojb=).
 *
 *  v0.2.7 (19 oct) - OPCIONES A FABRICA EN CADA ARRANQUE + FIX DEL PARPADEO.
 *    - pedido del operador: "que las opciones aparezcan desactivadas cada vez
 *      que se inicia el juego" (se quedaban guardadas como se dejaron). Al
 *      cargar el dylib se borran las claves de opciones (mm_esp_* y
 *      mm_stream) y todo arranca apagado, incluidos los filtros
 *      Jugadores/Bots (antes venian en ON por defecto). Se conservan solo las
 *      POSICIONES (boton y panel): son comodidad de arrastre, no opciones.
 *    - fix del parpadeo del menu: mm_place_ui() volvia a llamar a
 *      mm_set_panel(YES) en CADA latido (0.5 s al principio, 5 s despues) y
 *      eso re-disparaba la animacion de entrada desde alpha 0 con el panel
 *      abierto: el menu parecia parpadear. Ahora el latido solo se asegura de
 *      que el panel siga visible (alpha 1) sin animar de nuevo.
 *
 *  v0.2.6 (19 oct) - SALUD VISIBLE (pedido del test de la 0.2.5: "la salud de
 *  los jugadores no se ve"; el resto bien).
 *    - la barra de salud ya no depende del toggle "Cajas" (en la 0.2.5 se
 *      apagaba con el; ahora es solo del toggle "Salud", como el resto);
 *    - mas visible: 4 px de ancho, marco negro, fondo oscuro y color por
 *      tramos (verde/ambar/rojo); se dibuja tambien con vida 0 (se ve el
 *      marco) a la izquierda de la caja, de la cabeza a los pies;
 *    - lectura de la salud tolerante al ABI: el getter del juego puede
 *      devolver int (w0) o float (s0) - no estaba confirmado. Se llama con
 *      las dos firmas (lecturas puras) y se elige el valor plausible: entero
 *      sano 1..100000, float sano 0.001..100000 (las bandas no se solapan);
 *      los dos numeros crudos del primer jugador quedan en INFO/status para
 *      confirmar en el equipo cual era el tipo real.
 *
 *  v0.2.5 (19 oct) - ESP parte 4: CAJA DE CUERPO COMPLETO + TOGGLES + LINEAS.
 *    - la caja ya no se queda pegada a la cabeza: la posicion del pawn cae a
 *      la altura del cuello (verificado en captura), y el +0.5 de clip del mod
 *      de referencia solo movia la cabeza unos pixeles (caja diminuta). Ahora
 *      se proyectan dos puntos del mundo, cabeza (pos + 0.25 m) y pies
 *      (pos - 1.52 m), asi que la caja cubre todo el cuerpo a cualquier
 *      distancia;
 *    - el toggle "Cajas" ahora SI manda: el lienzo no leia mm_esp_box y
 *      dibujaba las cajas siempre. Con Cajas OFF se apagan caja, relleno y
 *      barra de salud ligada a la caja (nombres, distancia y lineas siguen
 *      siendo independientes);
 *    - nuevo toggle "Lineas desde arriba": con ON las lineas salen del borde
 *      superior de la pantalla y terminan en la cabeza de la caja; con OFF
 *      (por defecto) salen desde abajo y terminan en los pies, como antes;
 *    - auditoria de los 9 toggles anteriores: todos tienen efecto real en el
 *      escaneo o en el lienzo (Jugadores/Bots en el escaneo; el resto al
 *      pintar).
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
 *      Jose Lopez @l0pez9801" abajo a la izquierda (tenue, no recibe toques;
 *      v0.3.0: Stream Mode la oculta del todo);
 *    - rango (19 oct): escaneo de hasta 200 pawns como el mod de referencia
 *      (antes se cortaba a 24) y fuera el minimo de 4 px que ocultaba a los
 *      lejanos; slider hasta 500 m;
 *    - dibujo (19 oct): cajas y lineas con contorno negro y trazo grueso,
 *      filtros Jugadores/Bots y relleno opcional; suavizado por pawn para que
 *      las cajas/lineas no salten al cambiar el orden de la lista;
 *    - panel arrastrable (19 oct): se mueve desde la franja del titulo y
 *      recuerda posicion (mm_panel_pos/x/y).
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
 *    - Stream Mode: atenua el boton casi hasta desaparecer y oculta la
 *      marca de agua (para grabar);
 *    - la ventana overlay DEJA PASAR los toques fuera del boton/panel: el
 *      juego se sigue jugando igual;
 *    - se conserva el instrumental de diagnostico de la fase A: latido en el
 *      log cada 5 s + Documents/modmenu_status.txt + dladdr.
 *============================================================================*/

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <Security/Security.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#include <unistd.h>
#include <mach/mach.h>
#include <mach/vm_map.h>
#include <mach/vm_region.h>
#include <mach-o/dyld.h>
#include <libkern/OSCacheControl.h>
#include <pthread.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>

#define MODMENU_VERSION     "0.3.1-glass"
#define MM_TAG              "[MODMENU]"
#define MM_FAST_TRIES       120             /* 120 x 0.5 s = 60 s rapidos  */
#define MM_FAST_LOG_EVERY   20              /* log de espera cada 10 s     */
#define MM_SLOW_SECS        5               /* luego un latido cada 5 s    */
#define MM_PANEL_W          300.0
#define MM_PANEL_H          430.0

/* v0.2.5: la posicion del pawn proyecta a la altura del cuello/cabeza. La
   caja se completa con dos puntos del mundo para cubrir el cuerpo entero:
   +0.25 m hasta la coronilla y -1.52 m hasta los pies (1.77 m de alto). */
#define MM_BOX_TOP_UP       0.25f
#define MM_BOX_FEET_DN      1.52f

/* Marcador global: el CI lo verifica para confirmar que este fuente llego al
   binario (el constructor es static y no sirve como prueba de presencia). */
const char *modmenu_build_id = "modmenu-glass-0.3.1";

/* --- objetos de UI (globales, creados una sola vez) --- */
static UIView   *g_root  = nil;   /* capa transparente sobre la ventana juego */
static UIButton *g_btn   = nil;   /* boton flotante                           */
static UIView   *g_panel = nil;   /* panel desplegable                        */
static CAGradientLayer *g_panel_neon = nil; /* v0.3.1: fondo glass neon       */
static UIVisualEffectView *g_panel_blur = nil;
static UIView   *g_panel_shade = nil;
static CAGradientLayer *g_btn_neon = nil;   /* v0.3.1: boton glass neon       */
static UISegmentedControl *g_seg = nil;
static UILabel  *g_marca  = nil;  /* marca de agua v0.2.4 (identidad) */
static UIView   *g_p_esp  = nil;
static UIView   *g_p_vis  = nil;  /* v0.3.0: Stream Mode + pulido ESP */
static UIView   *g_p_misc = nil;
static UIView   *g_p_skins = nil;
static UIView   *g_p_info = nil;
static UILabel  *g_info   = nil;  /* texto vivo de la pagina INFO             */
static UILabel  *g_range_val = nil;
static NSMutableArray *g_sub_switches = nil;  /* switches bajo el maestro    */

/* v0.2.9: controles de la pagina SKINS */
static UISwitch *g_skin_master_sw = nil;
static UISwitch *g_skin_capture_sw = nil;
static UITextField *g_skin_weapon_tf = nil;
static UITextField *g_skin_char_tf = nil;
static UISegmentedControl *g_skin_preset_seg = nil;
static UILabel *g_skin_status = nil;

/* Presets verificados en el dylib de GL (kPresetWeaponSkins, 0x51b30). */
static const uint32_t g_skin_presets[6] = {
    0u, 0x0F6951u, 0x0F9062u, 0x0FB773u, 0x0FDE84u, 0x100595u
};

static const char *g_via   = "-";     /* donde quedo colgada la UI        */
static BOOL  g_panel_open  = NO;
static CGPoint g_panel_drag0;         /* v0.2.4: inicio de arrastre panel */
static int   g_tries       = 0;
static NSTimeInterval g_t0 = 0;
static BOOL  g_ui_ok       = NO;      /* UIApplication ya es segura       */

/* --- ESP: lienzo + cajas + sonda --- */
#define MM_MAX_BOXES 32
typedef struct {
    uint64_t pawn;              /* v0.2.4: dueno de la caja (estabilidad) */
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
static int          g_count_players = 0; /* v0.3.0: dibujados por tipo     */
static int          g_count_bots = 0;
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
static float mm_def_float(NSString *k, float d);
static void mm_esp_frame(double t);
static void mm_esp_collect_real(void);
static void mm_probe_run(void);

/* v0.2.9: fase D (skins + guest reset) */
static void mm_skin_apply(void);
static void mm_skin_refresh_status(void);
static void mm_skin_sync_ui(void);
static NSString *mm_skin_resumen(void);
static NSString *mm_skin_dump_write(void);
static int mm_skin_count(void);
static uint32_t mm_skin_parse_field(UITextField *tf);
static void mm_skin_set_weapon(uint32_t v);
static void mm_skin_set_char(uint32_t v);
static void mm_guest_reset_prompt(void);
static void mm_show_alert(NSString *titulo, NSString *msg);

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
 * v0.3.0: ayudas de dibujo del pulido ESP.
 *   - tema 0 clasico: jugador rojo / bot ambar;
 *   - tema 1 neon:    jugador verde / bot cian;
 *   - tema 2 blanco:  jugador blanco / bot gris claro.
 *--------------------------------------------------------------------------*/
static void mm_esp_color(int robot, int tema, CGFloat *r, CGFloat *g, CGFloat *b)
{
    if (tema == 1) {
        if (robot) { *r = 0.20; *g = 0.85; *b = 1.00; }
        else       { *r = 0.30; *g = 1.00; *b = 0.45; }
    } else if (tema == 2) {
        if (robot) { *r = 0.78; *g = 0.84; *b = 0.90; }
        else       { *r = 1.00; *g = 1.00; *b = 1.00; }
    } else {
        if (robot) { *r = 1.00; *g = 0.72; *b = 0.20; }
        else       { *r = 1.00; *g = 0.25; *b = 0.25; }
    }
}

/* Caja completa o solo esquinas. Deja el path en el contexto; el llamador
   decide el grosor/color y hace el stroke. */
static void mm_esp_box_path(CGContextRef ctx, CGRect r, int estilo)
{
    CGContextBeginPath(ctx);
    if (estilo != 1) {
        CGContextAddRect(ctx, r);
        return;
    }

    CGFloat x0 = CGRectGetMinX(r), x1 = CGRectGetMaxX(r);
    CGFloat y0 = CGRectGetMinY(r), y1 = CGRectGetMaxY(r);
    CGFloat len = MIN(16.0, MIN(r.size.width, r.size.height) * 0.30);
    CGFloat maxLen = MIN(r.size.width, r.size.height) * 0.50;
    if (maxLen < 1.0) maxLen = 1.0;
    if (len > maxLen) len = maxLen;
    if (len < 1.0) len = 1.0;

    /* superior izquierda */
    CGContextMoveToPoint(ctx, x0, y0 + len);
    CGContextAddLineToPoint(ctx, x0, y0);
    CGContextAddLineToPoint(ctx, x0 + len, y0);
    /* superior derecha */
    CGContextMoveToPoint(ctx, x1 - len, y0);
    CGContextAddLineToPoint(ctx, x1, y0);
    CGContextAddLineToPoint(ctx, x1, y0 + len);
    /* inferior derecha */
    CGContextMoveToPoint(ctx, x1, y1 - len);
    CGContextAddLineToPoint(ctx, x1, y1);
    CGContextAddLineToPoint(ctx, x1 - len, y1);
    /* inferior izquierda */
    CGContextMoveToPoint(ctx, x0 + len, y1);
    CGContextAddLineToPoint(ctx, x0, y1);
    CGContextAddLineToPoint(ctx, x0, y1 - len);
}

/* Contador pequeno arriba a la izquierda: cuantos jugadores y bots se estan
   dibujando en esta pasada (no la lista total del juego). */
static void mm_draw_esp_count(CGContextRef ctx)
{
    UIFont *f = [UIFont fontWithName:@"Menlo-Bold" size:12.0];
    if (f == nil) f = [UIFont boldSystemFontOfSize:12.0];
    NSString *s = [NSString stringWithFormat:@"JUG %d   BOT %d",
                   g_count_players, g_count_bots];
    NSDictionary *attr = @{ NSFontAttributeName: f,
        NSForegroundColorAttributeName:
            [UIColor colorWithRed:0.88 green:1.0 blue:0.90 alpha:1.0] };
    CGSize ts = [s sizeWithAttributes:attr];
    CGFloat x = 12.0, y = 42.0;
    CGRect bg = CGRectMake(x, y, ts.width + 16.0, ts.height + 8.0);
    CGContextSetRGBFillColor(ctx, 0.0, 0.0, 0.0, 0.58);
    CGContextFillRect(ctx, bg);
    CGContextSetLineWidth(ctx, 1.0);
    CGContextSetRGBStrokeColor(ctx, 0.16, 0.88, 0.38, 0.55);
    CGContextStrokeRect(ctx, bg);
    [s drawAtPoint:CGPointMake(x + 8.0, y + 4.0) withAttributes:attr];
}

/*---------------------------------------------------------------------------
 * Lienzo del ESP (v0.2.2): pinta las cajas ENCIMA del juego pero DEBAJO del
 * boton y del panel (va el primero dentro de la capa). No recibe toques.
 *--------------------------------------------------------------------------*/
@interface MMCanvasView : UIView @end

@implementation MMCanvasView
- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (ctx == NULL) return;

    CGRect bs = self.bounds;
    UIFont *f = [UIFont fontWithName:@"Menlo-Bold" size:11.0];
    if (f == nil) f = [UIFont boldSystemFontOfSize:11.0];

    BOOL conCajas  = mm_def_bool(@"mm_esp_box", NO);          /* v0.2.5 */
    BOOL conNombre = mm_def_bool(@"mm_esp_name", NO);
    BOOL conDist   = mm_def_bool(@"mm_esp_dist", NO);
    BOOL conLineas = mm_def_bool(@"mm_esp_lines", NO);
    BOOL lineasTop = mm_def_bool(@"mm_esp_lines_top", NO);    /* v0.2.5 */
    BOOL conSalud  = mm_def_bool(@"mm_esp_health", NO);
    BOOL conRelleno = mm_def_bool(@"mm_esp_fill", NO);
    BOOL conCuenta  = mm_def_bool(@"mm_esp_count", NO);       /* v0.3.0 */
    int  estiloCaja = (int)mm_def_float(@"mm_esp_box_style", 0.0f);
    int  tema       = (int)mm_def_float(@"mm_esp_theme", 0.0f);
    if (estiloCaja != 1) estiloCaja = 0;
    if (tema < 0 || tema > 2) tema = 0;

    if (g_box_count <= 0) {
        if (conCuenta) mm_draw_esp_count(ctx);
        return;
    }

    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextSetLineJoin(ctx, kCGLineJoinRound);

    CGContextSetLineWidth(ctx, 1.6);
    for (int i = 0; i < g_box_count && i < MM_MAX_BOXES; i++) {
        MMEspBox *b = &g_boxes[i];
        if (!b->alive) continue;
        CGRect r = CGRectMake(b->x, b->y, b->w, b->h);

        CGFloat cr = 1.00, cg = 0.25, cb = 0.25;
        mm_esp_color(b->robot, tema, &cr, &cg, &cb);

        if (conLineas) {
            /* v0.2.5: origen elegible. OFF = borde inferior -> pies de la caja;
               ON = borde superior -> cabeza de la caja. */
            CGPoint desde = CGPointMake(bs.size.width / 2.0,
                                        lineasTop ? 0.0 : bs.size.height);
            CGPoint hasta = CGPointMake(CGRectGetMidX(r),
                                        lineasTop ? CGRectGetMinY(r)
                                                  : CGRectGetMaxY(r));
            /* v0.2.4: contorno negro + trazo grueso (antes se veia debil) */
            CGContextSetLineWidth(ctx, 4.2);
            CGContextSetRGBStrokeColor(ctx, 0.0, 0.0, 0.0, 0.45);
            CGContextMoveToPoint(ctx, desde.x, desde.y);
            CGContextAddLineToPoint(ctx, hasta.x, hasta.y);
            CGContextStrokePath(ctx);
            CGContextSetLineWidth(ctx, 1.8);
            CGContextSetRGBStrokeColor(ctx, cr, cg, cb, 0.95);
            CGContextMoveToPoint(ctx, desde.x, desde.y);
            CGContextAddLineToPoint(ctx, hasta.x, hasta.y);
            CGContextStrokePath(ctx);
        }

        /* v0.2.5: TODO lo que cuelga de la caja respeta el toggle "Cajas".
           Antes se dibujaba siempre (el switch parecia no responder). Los
           nombres y la distancia quedan fuera: son toggles independientes. */
        if (conCajas) {
            if (conRelleno) {
                CGContextSetRGBFillColor(ctx, cr, cg, cb, 0.12);
                CGContextFillRect(ctx, r);
            }
            /* v0.3.0: borde completo o solo esquinas, con el mismo contorno
               negro para que se lea sobre cualquier fondo. */
            CGContextSetLineWidth(ctx, 3.4);
            CGContextSetRGBStrokeColor(ctx, 0.0, 0.0, 0.0, 0.55);
            mm_esp_box_path(ctx, r, estiloCaja);
            CGContextStrokePath(ctx);
            CGContextSetLineWidth(ctx, 1.7);
            CGContextSetRGBStrokeColor(ctx, cr, cg, cb, 0.95);
            mm_esp_box_path(ctx, r, estiloCaja);
            CGContextStrokePath(ctx);
        }

        /* v0.2.6: barra de salud INDEPENDIENTE del toggle "Cajas" (en la
           0.2.5 yo la habia ligado a el y con Cajas OFF desaparecia; el
           test la reporto como "no se ve"). Manda solo el toggle "Salud".
           Ahora mas visible: marco negro + fondo + relleno por tramos
           (verde/ambar/rojo); se dibuja tambien con vida 0 (se ve el marco)
           a la izquierda de la caja, de pies a cabeza. */
        if (conSalud && b->hp >= 0.0f && b->hpMax > 1.0f) {
            float fr = b->hp / b->hpMax;
            if (fr < 0.0f) fr = 0.0f;
            if (fr > 1.0f) fr = 1.0f;
            CGFloat bwv = 4.0;
            CGFloat bx  = r.origin.x - 8.0;
            CGFloat by  = r.origin.y;
            CGFloat bhh = r.size.height;
            if (bhh < 6.0) bhh = 6.0;  /* minimo para que se vea de lejos */
            /* marco negro alrededor de toda la barra */
            CGContextSetRGBFillColor(ctx, 0.0, 0.0, 0.0, 0.80);
            CGContextFillRect(ctx, CGRectMake(bx - 1.5, by - 1.5,
                                              bwv + 3.0, bhh + 3.0));
            /* fondo oscuro (se ve aunque la vida este en 0) */
            CGContextSetRGBFillColor(ctx, 0.06, 0.10, 0.06, 0.90);
            CGContextFillRect(ctx, CGRectMake(bx, by, bwv, bhh));
            /* relleno segun la vida */
            CGFloat rr2 = 1.00, gg2 = 0.20;
            if (fr > 0.5f)       { rr2 = 0.20; gg2 = 1.00; }
            else if (fr > 0.25f) { rr2 = 1.00; gg2 = 0.75; }
            CGFloat fh2 = bhh * fr;
            if (fh2 > 0.0f) {
                CGContextSetRGBFillColor(ctx, rr2, gg2, 0.20, 0.98);
                CGContextFillRect(ctx, CGRectMake(bx, by + bhh - fh2,
                                                  bwv, fh2));
            }
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

    if (conCuenta) mm_draw_esp_count(ctx);
}
@end

/*---------------------------------------------------------------------------
 * Callbacks de la UI (un singleton para target/action).
 *--------------------------------------------------------------------------*/
@interface MMTargets : NSObject
+ (MMTargets *)shared;
- (void)onFrame:(CADisplayLink *)link;
- (void)onPanelPan:(UIPanGestureRecognizer *)g;
- (void)onSkinApply;
- (void)onSkinDump;
- (void)onSkinWeaponSet;
- (void)onSkinCharSet;
- (void)onSkinPreset:(UISegmentedControl *)s;
- (void)onBoxStyle:(UISegmentedControl *)s;
- (void)onTheme:(UISegmentedControl *)s;
- (void)onTextDone:(id)sender;
- (void)onGuestReset;
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

- (void)onClose
{
    if (g_skin_weapon_tf != nil) [g_skin_weapon_tf resignFirstResponder];
    if (g_skin_char_tf != nil) [g_skin_char_tf resignFirstResponder];
    mm_set_panel(NO);
}

/* v0.2.4: arrastre del panel por su franja superior, con memoria. */
- (void)onPanelPan:(UIPanGestureRecognizer *)g
{
    @try {
        UIView *p = g_panel;
        if (p == nil || p.superview == nil) return;
        UIView *root = p.superview;
        if (g.state == UIGestureRecognizerStateBegan) g_panel_drag0 = p.center;
        CGPoint t = [g translationInView:root];
        CGPoint c = CGPointMake(g_panel_drag0.x + t.x, g_panel_drag0.y + t.y);
        CGFloat hw = p.bounds.size.width / 2.0;
        CGFloat hh = p.bounds.size.height / 2.0;
        c.x = MAX(hw + 4.0, MIN(root.bounds.size.width  - hw - 4.0, c.x));
        c.y = MAX(hh + 4.0, MIN(root.bounds.size.height - hh - 4.0, c.y));
        p.center = c;
        if (g.state == UIGestureRecognizerStateEnded ||
            g.state == UIGestureRecognizerStateCancelled) {
            NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
            [ud setFloat:c.x forKey:@"mm_panel_x"];
            [ud setFloat:c.y forKey:@"mm_panel_y"];
            [ud setBool:YES forKey:@"mm_panel_pos"];
            mm_write_status(@"panel movido");
        }
    } @catch (NSException *e) {
        NSLog(@"%s onPanelPan: %@", MM_TAG, e.reason);
    }
}

- (void)onSeg:(UISegmentedControl *)s
{
    NSInteger i = s.selectedSegmentIndex;
    if (g_skin_weapon_tf != nil) [g_skin_weapon_tf resignFirstResponder];
    if (g_skin_char_tf != nil) [g_skin_char_tf resignFirstResponder];
    if (g_p_esp   != nil) g_p_esp.hidden   = (i != 0);
    if (g_p_vis   != nil) g_p_vis.hidden   = (i != 1);
    if (g_p_misc  != nil) g_p_misc.hidden  = (i != 2);
    if (g_p_skins != nil) g_p_skins.hidden = (i != 3);
    if (g_p_info  != nil) g_p_info.hidden  = (i != 4);
}

- (void)onSwitch:(UISwitch *)s
{
    NSString *k = s.accessibilityIdentifier;
    if (k.length == 0) return;
    [[NSUserDefaults standardUserDefaults] setBool:s.on forKey:k];
    if ([k isEqualToString:@"mm_esp_master"]) mm_apply_esp_lock();
    if ([k isEqualToString:@"mm_stream"]) {
        mm_apply_stream();
        /* Al activarlo desde VIS se cierra el panel para dejar limpia la
           grabacion; al reabrirlo con el boton atenuado ya no se vuelve a
           cerrar solo (v0.3.0). */
        if (s.on) mm_set_panel(NO);
    }
    if ([k hasPrefix:@"mm_skin_"])            mm_skin_apply();
    mm_write_status(@"ajuste");
}

- (void)onSlider:(UISlider *)s
{
    [[NSUserDefaults standardUserDefaults] setFloat:s.value forKey:s.accessibilityIdentifier];
    if (g_range_val != nil)
        g_range_val.text = [NSString stringWithFormat:@"%d m", (int)(s.value + 0.5f)];
    mm_write_status(@"ajuste");
}

/* v0.3.0: estilo de caja y tema de color del ESP. El lienzo lee la clave en
   cada repintado, asi que el cambio es inmediato. */
- (void)onBoxStyle:(UISegmentedControl *)s
{
    NSInteger v = (s.selectedSegmentIndex == 1) ? 1 : 0;
    [[NSUserDefaults standardUserDefaults] setInteger:v forKey:@"mm_esp_box_style"];
    mm_write_status(@"estilo caja");
}

- (void)onTheme:(UISegmentedControl *)s
{
    NSInteger v = s.selectedSegmentIndex;
    if (v < 0 || v > 2) v = 0;
    [[NSUserDefaults standardUserDefaults] setInteger:v forKey:@"mm_esp_theme"];
    mm_write_status(@"tema esp");
}

/* v0.2.9: fase D. Aplicar los dos IDs, activar el maestro si hay alguno y
   (re)instalar los hooks. */
- (void)onSkinApply
{
    uint32_t w = mm_skin_parse_field(g_skin_weapon_tf);
    uint32_t c = mm_skin_parse_field(g_skin_char_tf);
    mm_skin_set_weapon(w);
    mm_skin_set_char(c);
    if (w != 0 || c != 0) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"mm_skin_master"];
        if (g_skin_master_sw != nil) g_skin_master_sw.on = YES;
    }
    mm_skin_apply();
    mm_show_alert(@"Skins", [NSString stringWithFormat:@"arma  %u\ntraje %u\n%@",
                             w, c, mm_skin_resumen()]);
}

- (void)onSkinWeaponSet
{
    uint32_t v = mm_skin_parse_field(g_skin_weapon_tf);
    mm_skin_set_weapon(v);
    if (v != 0) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"mm_skin_master"];
        if (g_skin_master_sw != nil) g_skin_master_sw.on = YES;
    }
    mm_skin_apply();
}

- (void)onSkinCharSet
{
    uint32_t v = mm_skin_parse_field(g_skin_char_tf);
    mm_skin_set_char(v);
    if (v != 0) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"mm_skin_master"];
        if (g_skin_master_sw != nil) g_skin_master_sw.on = YES;
    }
    mm_skin_apply();
}

- (void)onSkinPreset:(UISegmentedControl *)s
{
    NSInteger i = s.selectedSegmentIndex;
    if (i < 0 || i >= 6) return;
    uint32_t v = g_skin_presets[i];
    mm_skin_set_weapon(v);
    if (v != 0) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"mm_skin_master"];
        if (g_skin_master_sw != nil) g_skin_master_sw.on = YES;
    }
    mm_skin_apply();
}

- (void)onSkinDump
{
    NSString *p = mm_skin_dump_write();
    if (p != nil) {
        mm_show_alert(@"Dump de skins",
                      [NSString stringWithFormat:@"%d IDs capturados\n%@",
                       mm_skin_count(), p]);
    } else {
        mm_show_alert(@"Dump de skins",
                      @"No se pudo escribir CODM_SkinDump.txt");
    }
}

- (void)onTextDone:(id)sender
{
    if (g_skin_weapon_tf != nil) [g_skin_weapon_tf resignFirstResponder];
    if (g_skin_char_tf != nil) [g_skin_char_tf resignFirstResponder];
}

- (void)onGuestReset
{
    mm_guest_reset_prompt();
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

/* v0.2.7: las OPCIONES no se recuerdan entre partidas. En cada arranque del
   juego se borran las claves de opciones y todo vuelve al estado de fabrica
   (apagado). El operador lo pidio asi: preferia que nada quedara activado de
   la sesion anterior. Las POSICIONES del boton y del panel SI se conservan:
   son comodidad de arrastre, no opciones. */
static void mm_reset_options(void)
{
    @try {
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        NSArray *keys = @[ @"mm_esp_master", @"mm_esp_box", @"mm_esp_players",
                           @"mm_esp_bots", @"mm_esp_name", @"mm_esp_dist",
                           @"mm_esp_health", @"mm_esp_lines", @"mm_esp_lines_top",
                           @"mm_esp_fill", @"mm_esp_range", @"mm_stream",
                           @"mm_esp_count", @"mm_esp_box_style", @"mm_esp_theme",
                           @"mm_skin_master", @"mm_skin_capture",
                           @"mm_skin_weapon", @"mm_skin_char" ];
        for (NSString *k in keys) [ud removeObjectForKey:k];
        [ud synchronize];
    } @catch (NSException *e) {
        NSLog(@"[MODMENU] reset de opciones: %@", e.reason);
    }
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
 * FASE C v0.2.8 - NOJB (antidetect).
 *
 * Receta replicada del mod de referencia (GL), leida de su dylib en el
 * laboratorio (msdk_gl):
 *   - 39 swizzles ObjC que devuelven 0 / no-op: checksums (APMRemoteConfig,
 *     GNLCommonTools, QCloudSimplePing), identificadores anonimos (AppsFlyer,
 *     FBSDK, FBAd), watchdog de hilos (APMTimeoutThreadManager) y todos los
 *     metodos de MSWeakTimer (temporizador interno de las capas de proteccion);
 *   - 2 parches de codigo en anogs (AnoSDK): _AnoSDKGetReportData devuelve 0 y
 *     _AnoSDKDelReportData hace ret. Son los dos unicos sitios de la tabla de
 *     GL que en 1.0.57 caen justo en la entrada de una funcion; los otros 8
 *     caen a media funcion y parchearlos corromperia la pila (no se tocan).
 *
 * Reglas de esta fase (defensivas):
 *   - clase o metodo ausente => se salta y se anota (se reintenta en el
 *     siguiente pase, porque las frameworks cargan tarde);
 *   - nunca se swizzlea un metodo heredado de NSObject/NSProxy: el Method
 *     seria el del root y romperia toda la app (p.ej. -init);
 *   - antes de escribir en anogs se comparan los bytes del sitio con los
 *     esperados de 1.0.57; si no coinciden NO se escribe nada;
 *   - al escribir se guarda la proteccion original con vm_region_64, se pone
 *     RW, se escribe, se invalida la cache de instrucciones y se restaura;
 *   - resultado en INFO (linea nojb) y en modmenu_status.txt (nojb=).
 *--------------------------------------------------------------------------*/

typedef struct {
    const char *cls;
    const char *sel;
    int         isClass;   /* 1 = metodo de clase (+)                */
    IMP         rep;       /* sustituto: devuelve 0 o no hace nada   */
} MMNojbHook;

#define MM_NOJB_COUNT 39

static signed char g_nojb_state[MM_NOJB_COUNT]; /* 0 pendiente / 1 puesto / -1 skip */
static int         g_nojb_passes = 0;
static int         g_nojb_anogs[2];             /* 0 pend / 1 armado / -1 skip / -2 fallo */
static int         g_nojb_anogs_log[2];         /* para no repetir el aviso       */
static BOOL        g_nojb_started = NO;

/* v0.2.8b: anogs OFF. La 0.2.8 crasheo a los pocos segundos en el test,
   justo cuando el hilo NoJB armaba p00/p01 (t = 8 s). No se escribe en anogs
   hasta identificar la causa. Poner YES solo con un fix verificado. */
static const BOOL  g_nojb_anogs_enabled = NO;

/* Sustitutos genericos. En arm64 los cero viajan en x0/w0 y en d0, asi que
   sirven tanto para BOOL/objeto/puntero como para double. */
static id     mm_hk_obj(id self, SEL _cmd, ...)  { (void)self; (void)_cmd; return nil; }
static BOOL   mm_hk_no(id self, SEL _cmd, ...)   { (void)self; (void)_cmd; return NO; }
static double mm_hk_dbl(id self, SEL _cmd, ...)  { (void)self; (void)_cmd; return 0.0; }
static void   mm_hk_void(id self, SEL _cmd, ...) { (void)self; (void)_cmd; }

/* Orden y comportamiento identicos a la tabla de GL (msdk_gl). */
static const MMNojbHook g_nojb_hooks[MM_NOJB_COUNT] = {
    { "APMRemoteConfig",       "checksumEnabled",                     0, (IMP)mm_hk_no   },
    { "GNLCommonTools",        "_checksumOfCRC32:",                   1, (IMP)mm_hk_obj  },
    { "QCloudSimplePing",      "pingPacketWithType:payload:requiresChecksum:", 0, (IMP)mm_hk_obj },
    { "AppsFlyerLib",          "anonymizeUser",                       0, (IMP)mm_hk_no   },
    { "AppsFlyerLib",          "setAnonymizeUser:",                   0, (IMP)mm_hk_void },
    { "AppsFlyerUtils",        "retrievePersistedAnonymousID",        1, (IMP)mm_hk_obj  },
    { "FBSDKAppEvents",        "anonymousID",                         0, (IMP)mm_hk_obj  },
    { "FBSDKBasicUtility",     "anonymousID",                         1, (IMP)mm_hk_obj  },
    { "FBSDKBasicUtility",     "retrievePersistedAnonymousID",        1, (IMP)mm_hk_obj  },
    { "FBSDKBasicUtility",     "persistAnonymousID:",                 1, (IMP)mm_hk_void },
    { "MSWeakTimer",           "initWithTimeInterval:target:selector:userInfo:repeats:dispatchQueue:", 0, (IMP)mm_hk_obj },
    { "MSWeakTimer",           "init",                                0, (IMP)mm_hk_obj  },
    { "MSWeakTimer",           "setTolerance:",                       0, (IMP)mm_hk_void },
    { "MSWeakTimer",           "resetTimerProperties",                0, (IMP)mm_hk_void },
    { "MSWeakTimer",           "description",                         0, (IMP)mm_hk_obj  },
    { "MSWeakTimer",           "tolerance",                           0, (IMP)mm_hk_dbl  },
    { "MSWeakTimer",           "invalidate",                          0, (IMP)mm_hk_void },
    { "MSWeakTimer",           "setTimeInterval:",                    0, (IMP)mm_hk_void },
    { "MSWeakTimer",           "target",                              0, (IMP)mm_hk_obj  },
    { "MSWeakTimer",           "timeInterval",                        0, (IMP)mm_hk_dbl  },
    { "MSWeakTimer",           "setTarget:",                          0, (IMP)mm_hk_void },
    { "MSWeakTimer",           "userInfo",                            0, (IMP)mm_hk_obj  },
    { "MSWeakTimer",           "setUserInfo:",                        0, (IMP)mm_hk_void },
    { "MSWeakTimer",           "repeats",                             0, (IMP)mm_hk_no   },
    { "MSWeakTimer",           "setRepeats:",                         0, (IMP)mm_hk_void },
    { "MSWeakTimer",           "privateSerialQueue",                  0, (IMP)mm_hk_obj  },
    { "MSWeakTimer",           "setPrivateSerialQueue:",              0, (IMP)mm_hk_void },
    { "MSWeakTimer",           "timer",                               0, (IMP)mm_hk_obj  },
    { "MSWeakTimer",           "setTimer:",                           0, (IMP)mm_hk_void },
    { "MSWeakTimer",           "scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:dispatchQueue:", 1, (IMP)mm_hk_obj },
    { "FBAdUtility",           "anonymousIdentifier",                 1, (IMP)mm_hk_obj  },
    { "FBAdBasicUtility",      "persistAnonymousID:",                 1, (IMP)mm_hk_void },
    { "FBAdBasicUtility",      "retrievePersistedAnonymousID",        1, (IMP)mm_hk_obj  },
    { "FBAdBasicUtility",      "anonymousID",                         1, (IMP)mm_hk_obj  },
    { "TssReachability",       "reachabilityWithHostName:",           1, (IMP)mm_hk_obj  },
    { "APMDeviceInfoSupportFrameworkLoad", "load",                    1, (IMP)mm_hk_void },
    { "APMTimeoutThreadManager", "updateThread",                      0, (IMP)mm_hk_void },
    { "APMTimeoutThreadManager", "checkTimeoutThreadAndWriteBacktrace", 0, (IMP)mm_hk_void },
    { "APMTimeoutThreadManager", "pushBlockInfo:thread:findBlockTime:passedTime:dumptime:dumpAllThread:", 0, (IMP)mm_hk_void },
};

/* Sitios de anogs (offsets desde la base de la imagen; __TEXT vmaddr = 0 en
   1.0.57). expect = primeros `words*4` bytes originales (verificados en el
   laboratorio contra el anogs del IPA base, sha256 28A31BC48BFE1DD4...). */
typedef struct {
    uint32_t off;
    uint32_t words;      /* 2 = mov x0,#0;ret (8 B) / 1 = ret (4 B)      */
    uint64_t expect;     /* bytes originales esperados (little endian)    */
    uint32_t patch[2];
    const char *name;
} MMAnogsSite;

static const MMAnogsSite g_anogs_sites[2] = {
    { 0x0F2304, 2, 0x910003FDA9BF7BFDULL, { 0xD2800000, 0xD65F03C0 }, "p00" },
    { 0x0F2320, 1, 0x00000000A9BF7BFDULL, { 0xD65F03C0, 0x00000000 }, "p01" },
};

/* Base de anogs por su nombre de imagen (mismo criterio que GL: sufijo). */
static uintptr_t mm_anogs_base(void)
{
    static const char *names[2] = { "anogs.framework/anogs", "anogs" };
    uint32_t n = _dyld_image_count();
    for (uint32_t i = 0; i < n; i++) {
        const char *nm = _dyld_get_image_name(i);
        if (nm == NULL) continue;
        size_t ln = strlen(nm);
        for (int k = 0; k < 2; k++) {
            size_t ls = strlen(names[k]);
            if (ls <= ln && strcmp(nm + (ln - ls), names[k]) == 0)
                return (uintptr_t)_dyld_get_image_header(i);
        }
    }
    return 0;
}

/* Proteccion actual de la pagina que contiene addr (R+X si no se puede leer). */
static vm_prot_t mm_orig_prot(uintptr_t addr)
{
    vm_address_t region = (vm_address_t)addr;
    vm_size_t size = 0;
    vm_region_basic_info_data_64_t info;
    mach_msg_type_number_t count = VM_REGION_BASIC_INFO_COUNT_64;
    mach_port_t object = MACH_PORT_NULL;
    if (vm_region_64(mach_task_self(), &region, &size, VM_REGION_BASIC_INFO_64,
                     (vm_region_info_t)&info, &count, &object) == KERN_SUCCESS) {
        if (object != MACH_PORT_NULL) mach_port_deallocate(mach_task_self(), object);
        return info.protection;
    }
    return VM_PROT_READ | VM_PROT_EXECUTE;
}

/* Escritura verificada en memoria ejecutable: devuelve 1 ok, <0 fallo. */
static int mm_mem_write(uintptr_t addr, const void *src, size_t len)
{
    if (addr == 0 || src == NULL || len == 0) return -1;
    vm_prot_t prot = mm_orig_prot(addr);
    if (vm_protect(mach_task_self(), (vm_address_t)addr, (vm_size_t)len,
                   FALSE, prot | VM_PROT_WRITE) != KERN_SUCCESS)
        return -2;
    memcpy((void *)addr, src, len);
    sys_icache_invalidate((void *)addr, len);
    if (vm_protect(mach_task_self(), (vm_address_t)addr, (vm_size_t)len,
                   FALSE, prot) != KERN_SUCCESS)
        return -3;
    return (memcmp((void *)addr, src, len) == 0) ? 1 : 0;
}

static int mm_nojb_try_swizzles(void)
{
    int done = 0;
    for (int i = 0; i < MM_NOJB_COUNT; i++) {
        if (g_nojb_state[i] == 1) { done++; continue; }
        if (g_nojb_state[i] == -1) continue;   /* heredado del root: no se toca */
        const MMNojbHook *h = &g_nojb_hooks[i];
        Class cls = objc_getClass(h->cls);
        if (cls == NULL) continue;             /* aun no cargada: otro pase */
        SEL sel = sel_registerName(h->sel);
        Method m = h->isClass ? class_getClassMethod(cls, sel)
                              : class_getInstanceMethod(cls, sel);
        if (m == NULL) continue;               /* aun sin el metodo: otro pase */
        Method base = h->isClass ? class_getClassMethod([NSObject class], sel)
                                 : class_getInstanceMethod([NSObject class], sel);
        if (base == m) {
            g_nojb_state[i] = -1;
            NSLog(@"%s nojb: %s%s %s es heredado de NSObject, se salta",
                  MM_TAG, h->isClass ? "+" : "-", h->cls, h->sel);
            continue;
        }
        IMP prev = method_setImplementation(m, h->rep);
        g_nojb_state[i] = 1;
        done++;
        NSLog(@"%s nojb: swz %s%s %s (antes=%p) -> 0",
              MM_TAG, h->isClass ? "+" : "-", h->cls, h->sel, (void *)prev);
    }
    return done;
}

static void mm_nojb_try_anogs(void)
{
    uintptr_t base = mm_anogs_base();
    if (base == 0) return;                     /* anogs aun no cargada */

    for (int i = 0; i < 2; i++) {
        if (g_nojb_anogs[i] != 0) continue;
        const MMAnogsSite *s = &g_anogs_sites[i];
        uintptr_t a = base + (uintptr_t)s->off;
        size_t len = (size_t)s->words * 4;
        uint64_t cur = 0;
        uint64_t patched = (uint64_t)s->patch[0] | ((uint64_t)s->patch[1] << 32);

        memcpy(&cur, (const void *)a, len);
        if (cur == patched) {                  /* ya estaba puesto (otro pase) */
            g_nojb_anogs[i] = 1;
            continue;
        }
        if (cur != s->expect) {
            g_nojb_anogs[i] = -1;              /* no es el anogs de 1.0.57 */
            NSLog(@"%s nojb: %s NO coincide (esperado 0x%llX, leido 0x%llX); no se escribe",
                  MM_TAG, s->name, (unsigned long long)s->expect,
                  (unsigned long long)cur);
            continue;
        }
        int r = mm_mem_write(a, s->patch, len);
        if (r == 1) {
            g_nojb_anogs[i] = 1;
            NSLog(@"%s nojb: %s armado en 0x%X (%zu B)", MM_TAG, s->name, s->off, len);
        } else if (g_nojb_anogs_log[i] == 0) {
            g_nojb_anogs_log[i] = 1;
            NSLog(@"%s nojb: %s fallo al escribir (r=%d); se reintenta",
                  MM_TAG, s->name, r);
        }
    }
}

/* Resumen para INFO y modmenu_status.txt. */
static NSString *mm_nojb_resumen(void)
{
    int swz = 0;
    for (int i = 0; i < MM_NOJB_COUNT; i++) if (g_nojb_state[i] == 1) swz++;

    if (!g_nojb_anogs_enabled) {
        return [NSString stringWithFormat:@"swz=%d/%d anogs=off img=%s",
                swz, MM_NOJB_COUNT,
                (mm_anogs_base() != 0) ? "si" : "no"];
    }

    const char *e0 = "pend", *e1 = "pend";
    if (g_nojb_anogs[0] == 1) e0 = "ok";
    else if (g_nojb_anogs[0] == -1) e0 = "skip";
    else if (g_nojb_anogs[0] == -2) e0 = "fail";
    if (g_nojb_anogs[1] == 1) e1 = "ok";
    else if (g_nojb_anogs[1] == -1) e1 = "skip";
    else if (g_nojb_anogs[1] == -2) e1 = "fail";
    int armed = (g_nojb_anogs[0] == 1) + (g_nojb_anogs[1] == 1);

    return [NSString stringWithFormat:@"swz=%d/%d anogs=%d/2(%s,%s) img=%s",
            swz, MM_NOJB_COUNT, armed, e0, e1,
            (mm_anogs_base() != 0) ? "si" : "no"];
}

static void mm_nojb_step(void);

static void mm_nojb_step(void)
{
    @autoreleasepool {
        g_nojb_passes++;
        int done = mm_nojb_try_swizzles();
        if (g_nojb_anogs_enabled && mm_uptime() >= 8.0) mm_nojb_try_anogs();

        BOOL todo = (done >= MM_NOJB_COUNT);
        if (g_nojb_anogs_enabled)
            todo = todo && (g_nojb_anogs[0] != 0) && (g_nojb_anogs[1] != 0);
        if (todo || g_nojb_passes >= 90) {
            NSLog(@"%s nojb fin: %@ (pasadas=%d)", MM_TAG, mm_nojb_resumen(), g_nojb_passes);
            return;
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                       dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
                           mm_nojb_step();
                       });
    }
}

static void mm_nojb_start(void)
{
    if (g_nojb_started) return;
    g_nojb_started = YES;
    NSLog(@"%s nojb: inicio (fase C v0.2.9, anogs OFF)", MM_TAG);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                   dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
                       mm_nojb_step();
                   });
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
typedef float   (*MMGetFltFn)(void *self);

static uintptr_t  g_game_base    = 0;
static MMGetPtrFn g_fp_gameplay  = NULL;
static MMGetPtrFn g_fp_localpawn = NULL;
static MMGetPtrFn g_fp_maincam   = NULL;
static MMMatFn    g_fp_w2c       = NULL;
static MMMatFn    g_fp_proj      = NULL;
static MMVec3Fn   g_fp_transpos  = NULL;
static MMGetIntFn g_fp_health    = NULL; /* opcional: si no valida, sin salud */
static MMGetFltFn g_fp_health_f  = NULL; /* v0.2.6: misma direccion, tipo float */
static int        g_fp_state     = -1;  /* -1 sin probar / 0 error / 1 ok */
static NSString  *g_esp_diag     = nil; /* motivo del ultimo fallo / ok   */
static NSString  *g_hp_diag      = nil; /* v0.2.6: muestra cruda de salud */
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
            g_fp_health_f  = hpOk ? (MMGetFltFn)fp6 : NULL;   /* v0.2.6 */
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
             (v0.2.5: ya no se usa para la caja; la coronilla y los pies se
              proyectan como puntos del mundo con MM_BOX_TOP_UP/FEET_DN)
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
    g_count_players = 0;
    g_count_bots = 0;
    g_esp_players = 0;
    g_hp_diag = nil;                       /* v0.2.6: muestra nueva por pasada */
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
    int loopn = total;

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

    float rango = mm_def_float(@"mm_esp_range", 300.0f);
    BOOL conSalud  = mm_def_bool(@"mm_esp_health", NO);   /* v0.2.4 */
    BOOL conJug    = mm_def_bool(@"mm_esp_players", NO);  /* v0.2.7: a fabrica */
    BOOL conBots   = mm_def_bool(@"mm_esp_bots", NO);     /* v0.2.7: a fabrica */
    int drawn = 0;
    MMEspBox nuevos[MM_MAX_BOXES];
    memset(nuevos, 0, sizeof(nuevos));

    /* v0.2.4: GL escanea hasta 200 pawns; el tope de cajas es solo para
       DIBUJAR. Antes se recortaba el escaneo a 24 y se perdia rango real. */
    if (loopn > 200) loopn = 200;

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

        /* v0.2.4: filtros por tipo */
        if (robot && !conBots) continue;
        if (!robot && !conJug) continue;

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

        /* v0.2.5: caja de cuerpo completo. La posicion del pawn proyecta a la
           altura del cuello, no a los pies (verificado en captura): el +0.5
           de clip que usa GL para la "cabeza" solo separaba unos pixeles y
           dejaba un cuadrito pegado a la cara. Se proyectan dos puntos del
           mundo, coronilla (pos + 0.25 m) y pies (pos - 1.52 m); asi la caja
           cubre el cuerpo entero a cualquier distancia. */
        float wpTop[3]  = { wp[0], wp[1] + MM_BOX_TOP_UP,  wp[2] };
        float wpFeet[3] = { wp[0], wp[1] - MM_BOX_FEET_DN, wp[2] };
        CGPoint cab, pies;
        if (!mm_w2s(view, proj, wpTop,  NO, W, H, &cab))  continue;
        if (!mm_w2s(view, proj, wpFeet, NO, W, H, &pies)) continue;
        if (cab.x  < -W || cab.x  > 2.0 * W || cab.y  < -H || cab.y  > 2.0 * H) continue;
        if (pies.x < -W || pies.x > 2.0 * W || pies.y < -H || pies.y > 2.0 * H) continue;

        CGFloat bh = pies.y - cab.y;
        /* v0.2.4: antes 4 px dejaba fuera a los lejanos (cajas pequenas) */
        if (bh < 3.0 || bh > 2.0 * H) continue;
        CGFloat bw = bh * 0.45;
        CGFloat cx = (cab.x + pies.x) * 0.5;

        /* --- v0.2.6: salud (solo con el toggle ON; misma llamada que GL,
           despues de todas las guardas: pawn mapeado y vivo). El getter del
           juego puede devolver int (w0) o float (s0) - no estaba confirmado:
           se llama con las dos firmas (lecturas puras) y se elige el valor
           plausible. Las bandas no se solapan: los bits de un entero pequeno
           leidos como float son un numero microscopico, y los de un float
           normal leidos como entero son gigantes. --- */
        float hp = -1.0f;
        float hpMax = 100.0f;
        if (conSalud && g_fp_health != NULL) {
            uint32_t hp_i = 0;
            float    hp_f = 0.0f;
            uint64_t pk = 0;
            if (mm_r64((uintptr_t)pawn, &pk)) {
                hp_i = (uint32_t)g_fp_health((void *)(uintptr_t)pawn);
                if (g_fp_health_f != NULL)
                    hp_f = g_fp_health_f((void *)(uintptr_t)pawn);
                if (hp_i >= 1 && hp_i <= 100000) {
                    hp = (float)hp_i;
                } else if (isfinite(hp_f) && hp_f > 0.001f && hp_f <= 100000.0f) {
                    hp = hp_f;
                } else if (hp_i == 0 && hp_f == 0.0f) {
                    hp = 0.0f;
                }
            }
            uint64_t mdl = 0;
            if (mm_r64((uintptr_t)pawn + OFF_PAWN_MODEL, &mdl) && mdl != 0) {
                float m = 0.0f;
                if (mm_vm_read((uintptr_t)mdl + OFF_MODEL_MAXHP, &m, sizeof(m)) &&
                    isfinite(m) && m > 0.5f && m < 100000.0f)
                    hpMax = m;
            }
            /* muestra cruda del primer pawn para confirmar el ABI en el equipo */
            if (g_hp_diag == nil)
                g_hp_diag = [NSString stringWithFormat:@"i=%u f=%.2f mx=%.0f",
                             (unsigned)hp_i, (double)hp_f, (double)hpMax];
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

        MMEspBox nb;
        memset(&nb, 0, sizeof(nb));
        nb.pawn = pawn;
        nb.x = cx - bw / 2.0;
        nb.y = cab.y;
        nb.w = bw;
        nb.h = bh;
        nb.dist = dist;
        nb.hp = hp;
        nb.hpMax = hpMax;
        nb.robot = robot;
        nb.alive = 1;
        nb.hasName = (nm[0] != 0) ? 1 : 0;
        memcpy(nb.name, nm, sizeof(nb.name));

        /* v0.2.4: estabilidad por pawn. La lista cambia de orden y las cajas
           saltaban; cada pawn conserva su caja y se interpola suavemente. */
        for (int q = 0; q < g_box_count; q++) {
            if (g_boxes[q].pawn != pawn || !g_boxes[q].alive) continue;
            nb.x = g_boxes[q].x * 0.55 + nb.x * 0.45;
            nb.y = g_boxes[q].y * 0.55 + nb.y * 0.45;
            nb.w = g_boxes[q].w * 0.55 + nb.w * 0.45;
            nb.h = g_boxes[q].h * 0.55 + nb.h * 0.45;
            break;
        }
        nuevos[drawn++] = nb;
        if (robot) g_count_bots++;
        else       g_count_players++;
    }

    memcpy(g_boxes, nuevos, sizeof(MMEspBox) * (size_t)drawn);
    g_box_count = drawn;
    g_esp_diag = [NSString stringWithFormat:
                  @"cam=ok lista=%d cajas=%d jug=%d bot=%d hp=%s%@",
                  total, drawn, g_count_players, g_count_bots,
                  (g_fp_health != NULL) ? "ok" : "no",
                  (g_hp_diag != nil)
                      ? [NSString stringWithFormat:@" [%@]", g_hp_diag]
                      : @""];
}

/*---------------------------------------------------------------------------
 * FASE D v0.2.9 - SKINS (armas + traje) Y DUMP.
 *
 * Los tres sitios son las funciones que usa el mod de referencia (GL) para
 * cambiar la skin en cliente. Verificados contra cod 1.0.57:
 *   0x2A90084  GetWeaponSkinID        (4 args, devuelve skin en w0/x0)
 *   0x587CFD4  GetWeaponSkinId_Inv    (inventario/loadout)
 *   0x1049844  GetSuitId              (2 args; el 0x1049835 de GL esta 15
 *                                      bytes antes, a media instruccion, y su
 *                                      escritura de 16 bytes rompia la funcion
 *                                      anterior: aqui se usa la entrada real)
 *
 * El trampolin es una funcion naked que ejecuta los primeros 16 bytes
 * originales y salta a entry+16. Asi el hook puede llamar al original sin
 * recursion (el ApplyARM64Hook de GL dejaba orig = entrada parcheada).
 *--------------------------------------------------------------------------*/

#define MM_SKIN_RVA_W     0x2A90084ULL
#define MM_SKIN_RVA_INV   0x587CFD4ULL
#define MM_SKIN_RVA_SUIT  0x1049844ULL
#define MM_SKIN_LOG_MAX   256

static const uint8_t mm_skin_pro_w[16] = {
    0xF6, 0x57, 0xBD, 0xA9, 0xF4, 0x4F, 0x01, 0xA9,
    0xFD, 0x7B, 0x02, 0xA9, 0xFD, 0x83, 0x00, 0x91
};
static const uint8_t mm_skin_pro_inv[16] = {
    0xFC, 0x6F, 0xBA, 0xA9, 0xFA, 0x67, 0x01, 0xA9,
    0xF8, 0x5F, 0x02, 0xA9, 0xF6, 0x57, 0x03, 0xA9
};
static const uint8_t mm_skin_pro_suit[16] = {
    0xF6, 0x57, 0xBD, 0xA9, 0xF4, 0x4F, 0x01, 0xA9,
    0xFD, 0x7B, 0x02, 0xA9, 0xFD, 0x83, 0x00, 0x91
};

/* Destinos del trampolin (entry+16). Deben tener enlace externo para que el
   ensamblador pueda referenciarlos con @PAGE/@PAGEOFF. */
__attribute__((visibility("hidden"))) volatile uintptr_t g_mm_skin_tramp_w = 0;
__attribute__((visibility("hidden"))) volatile uintptr_t g_mm_skin_tramp_inv = 0;
__attribute__((visibility("hidden"))) volatile uintptr_t g_mm_skin_tramp_suit = 0;

/* Trampolines naked: replican el prologo exacto y saltan al cuerpo original
   (entry+16). No usan pila propia ni guardan x30: el retorno del original va
   directo al hook que lo llamo. */
__asm__(
    ".text\n"
    ".p2align 2\n"
    ".globl _mm_skin_orig_w\n"
    "_mm_skin_orig_w:\n"
    "stp x22, x21, [sp, #-0x30]!\n"
    "stp x20, x19, [sp, #0x10]\n"
    "stp x29, x30, [sp, #0x20]\n"
    "add x29, sp, #0x20\n"
    "adrp x16, _g_mm_skin_tramp_w@PAGE\n"
    "ldr x16, [x16, _g_mm_skin_tramp_w@PAGEOFF]\n"
    "br x16\n"
    ".globl _mm_skin_orig_inv\n"
    "_mm_skin_orig_inv:\n"
    "stp x28, x27, [sp, #-0x60]!\n"
    "stp x26, x25, [sp, #0x10]\n"
    "stp x24, x23, [sp, #0x20]\n"
    "stp x22, x21, [sp, #0x30]\n"
    "adrp x16, _g_mm_skin_tramp_inv@PAGE\n"
    "ldr x16, [x16, _g_mm_skin_tramp_inv@PAGEOFF]\n"
    "br x16\n"
    ".globl _mm_skin_orig_suit\n"
    "_mm_skin_orig_suit:\n"
    "stp x22, x21, [sp, #-0x30]!\n"
    "stp x20, x19, [sp, #0x10]\n"
    "stp x29, x30, [sp, #0x20]\n"
    "add x29, sp, #0x20\n"
    "adrp x16, _g_mm_skin_tramp_suit@PAGE\n"
    "ldr x16, [x16, _g_mm_skin_tramp_suit@PAGEOFF]\n"
    "br x16\n"
    ".text\n"
);

extern uint32_t mm_skin_orig_w(void *, uintptr_t, uintptr_t, uintptr_t);
extern uint32_t mm_skin_orig_inv(void *, uintptr_t, uintptr_t, uintptr_t);
extern uint64_t mm_skin_orig_suit(void *, void *);

static volatile int      g_mm_skin_on = 0;
static volatile int      g_mm_skin_capture = 0;
static volatile uint32_t g_mm_skin_weapon_id = 0;
static volatile uint32_t g_mm_skin_char_id = 0;
static volatile int      g_mm_skin_installed = 0;
static int               g_mm_skin_hooks_ok = 0;
static uintptr_t         g_mm_skin_base = 0;
static NSString         *g_mm_skin_diag = nil;
static NSString         *g_mm_skin_last_dump = nil;

typedef struct {
    uint32_t kind;      /* 1 arma / 2 inventario / 3 traje */
    uint32_t a;
    uint32_t b;
} MMSkinLog;

static MMSkinLog g_mm_skin_log[MM_SKIN_LOG_MAX];
static int g_mm_skin_log_n = 0;
static int g_mm_skin_log_drop = 0;
static pthread_mutex_t g_mm_skin_log_mtx = PTHREAD_MUTEX_INITIALIZER;

static const char *mm_skin_kind_name(uint32_t k)
{
    switch (k) {
        case 1: return "WeaponSkin";
        case 2: return "LoadoutSkin";
        case 3: return "CharacterSuit";
        default: return "?";
    }
}

static void mm_skin_log_add(uint32_t kind, uint32_t a, uint32_t b)
{
    if (!g_mm_skin_capture || b == 0) return;
    pthread_mutex_lock(&g_mm_skin_log_mtx);
    for (int i = 0; i < g_mm_skin_log_n; i++) {
        if (g_mm_skin_log[i].kind == kind &&
            g_mm_skin_log[i].a == a &&
            g_mm_skin_log[i].b == b) {
            pthread_mutex_unlock(&g_mm_skin_log_mtx);
            return;
        }
    }
    if (g_mm_skin_log_n < MM_SKIN_LOG_MAX) {
        g_mm_skin_log[g_mm_skin_log_n].kind = kind;
        g_mm_skin_log[g_mm_skin_log_n].a = a;
        g_mm_skin_log[g_mm_skin_log_n].b = b;
        g_mm_skin_log_n++;
    } else {
        g_mm_skin_log_drop++;
    }
    pthread_mutex_unlock(&g_mm_skin_log_mtx);
}

__attribute__((noinline, used))
static uint32_t mm_hook_skin_w(void *a, uintptr_t b, uintptr_t c, uintptr_t d)
{
    /* GL no llama al original cuando ya va a devolver el ID custom; la funcion
       de arma tiene efectos laterales (1088 B) y asi se evita duplicarlos. */
    uint32_t real = 0;
    if (!(g_mm_skin_on && g_mm_skin_weapon_id != 0)) {
        real = mm_skin_orig_w(a, b, c, d);
    }
    mm_skin_log_add(1, (uint32_t)(uintptr_t)a, (uint32_t)(b ? b : real));
    if (g_mm_skin_on && g_mm_skin_weapon_id != 0) return g_mm_skin_weapon_id;
    return real;
}

__attribute__((noinline, used))
static uint32_t mm_hook_skin_inv(void *a, uintptr_t b, uintptr_t c, uintptr_t d)
{
    uint32_t real = mm_skin_orig_inv(a, b, c, d);
    mm_skin_log_add(2, (uint32_t)b, real);
    if (g_mm_skin_on && g_mm_skin_weapon_id != 0) return g_mm_skin_weapon_id;
    return real;
}

__attribute__((noinline, used))
static uint64_t mm_hook_skin_suit(void *a, void *b)
{
    uint64_t real = mm_skin_orig_suit(a, b);
    mm_skin_log_add(3, 0, (uint32_t)real);
    if (g_mm_skin_on && g_mm_skin_char_id != 0) return (uint64_t)g_mm_skin_char_id;
    return real;
}

typedef struct {
    uint64_t rva;
    const uint8_t *expect;
    void *hook;
    const char *name;
    int installed;
    uint8_t saved[16];
} MMSkinSite;

static MMSkinSite g_mm_skin_sites[3];

static void mm_skin_sites_init(void)
{
    static int done = 0;
    if (done) return;
    done = 1;
    memset(g_mm_skin_sites, 0, sizeof(g_mm_skin_sites));

    g_mm_skin_sites[0].rva = MM_SKIN_RVA_W;
    g_mm_skin_sites[0].expect = mm_skin_pro_w;
    g_mm_skin_sites[0].hook = (void *)mm_hook_skin_w;
    g_mm_skin_sites[0].name = "arma";

    g_mm_skin_sites[1].rva = MM_SKIN_RVA_INV;
    g_mm_skin_sites[1].expect = mm_skin_pro_inv;
    g_mm_skin_sites[1].hook = (void *)mm_hook_skin_inv;
    g_mm_skin_sites[1].name = "inventario";

    g_mm_skin_sites[2].rva = MM_SKIN_RVA_SUIT;
    g_mm_skin_sites[2].expect = mm_skin_pro_suit;
    g_mm_skin_sites[2].hook = (void *)mm_hook_skin_suit;
    g_mm_skin_sites[2].name = "traje";
}

/* Escritura de 16 bytes con proteccion de pagina completa. */
static int mm_skin_write16(uintptr_t addr, const void *src)
{
    if (addr == 0 || src == NULL) return -1;
    size_t ps = (size_t)getpagesize();
    uintptr_t page = addr & ~(uintptr_t)(ps - 1);
    uintptr_t end = addr + 16;
    size_t span = (size_t)(((end + ps - 1) & ~(uintptr_t)(ps - 1)) - page);
    vm_prot_t prot = mm_orig_prot(addr);

    kern_return_t kr = vm_protect(mach_task_self(), (vm_address_t)page,
                                  (vm_size_t)span, FALSE, prot | VM_PROT_WRITE);
    if (kr != KERN_SUCCESS) return -2;
    memcpy((void *)addr, src, 16);
    sys_icache_invalidate((void *)addr, 16);
    kr = vm_protect(mach_task_self(), (vm_address_t)page,
                    (vm_size_t)span, FALSE, prot);
    if (kr != KERN_SUCCESS) return -3;
    return (memcmp((void *)addr, src, 16) == 0) ? 0 : -4;
}

/* La base es la imagen principal (cod). Si existiera UserAssembly o
   UnityFramework, se prueba tambien; nunca se acepta una base sin verificar
   los dos prologos de las funciones de arma. */
static uintptr_t mm_skin_find_base(void)
{
    uintptr_t h0 = (uintptr_t)_dyld_get_image_header(0);
    uint32_t n = _dyld_image_count();
    uintptr_t cand[32];
    int nc = 0;

    if (h0 != 0) cand[nc++] = h0;
    for (uint32_t i = 0; i < n && nc < 32; i++) {
        const char *nm = _dyld_get_image_name(i);
        if (nm == NULL) continue;
        if (strstr(nm, "UserAssembly") == NULL &&
            strstr(nm, "UnityFramework") == NULL &&
            strstr(nm, "/cod") == NULL) continue;
        uintptr_t h = (uintptr_t)_dyld_get_image_header(i);
        if (h == 0 || h == h0) continue;
        cand[nc++] = h;
    }

    for (int i = 0; i < nc; i++) {
        uint8_t b[16];
        if (!mm_vm_read(cand[i] + MM_SKIN_RVA_W, b, 16)) continue;
        if (memcmp(b, mm_skin_pro_w, 16) != 0) continue;
        if (!mm_vm_read(cand[i] + MM_SKIN_RVA_INV, b, 16)) continue;
        if (memcmp(b, mm_skin_pro_inv, 16) != 0) continue;
        return cand[i];
    }
    return 0;
}

static int mm_skin_install_all(void)
{
    mm_skin_sites_init();
    if (g_mm_skin_base == 0) g_mm_skin_base = mm_skin_find_base();
    if (g_mm_skin_base == 0) {
        g_mm_skin_diag = @"base no encontrada";
        NSLog(@"%s skins: base no encontrada", MM_TAG);
        return 0;
    }

    g_mm_skin_tramp_w    = g_mm_skin_base + MM_SKIN_RVA_W + 16;
    g_mm_skin_tramp_inv  = g_mm_skin_base + MM_SKIN_RVA_INV + 16;
    g_mm_skin_tramp_suit = g_mm_skin_base + MM_SKIN_RVA_SUIT + 16;

    int ok = 0;
    for (int i = 0; i < 3; i++) {
        MMSkinSite *site = &g_mm_skin_sites[i];
        uintptr_t target = g_mm_skin_base + (uintptr_t)site->rva;
        uint8_t cur[16];
        if (!mm_vm_read(target, cur, 16)) {
            g_mm_skin_diag = [NSString stringWithFormat:@"%s ilegible", site->name];
            NSLog(@"%s skins: %s ilegible en 0x%lX", MM_TAG, site->name,
                  (unsigned long)target);
            continue;
        }
        if (memcmp(cur, site->expect, 16) != 0) {
            g_mm_skin_diag = [NSString stringWithFormat:@"%s prologo distinto", site->name];
            NSLog(@"%s skins: %s prologo distinto en 0x%lX", MM_TAG, site->name,
                  (unsigned long)target);
            continue;
        }
        memcpy(site->saved, cur, 16);
        uint8_t patch[16];
        uint64_t stub = 0xD61F020058000050ULL;  /* ldr x16,#8 ; br x16 */
        memcpy(patch, &stub, 8);
        uintptr_t hp = (uintptr_t)site->hook;
        memcpy(patch + 8, &hp, 8);
        if (mm_skin_write16(target, patch) != 0) {
            g_mm_skin_diag = [NSString stringWithFormat:@"%s no se pudo escribir", site->name];
            NSLog(@"%s skins: %s no se pudo escribir en 0x%lX", MM_TAG, site->name,
                  (unsigned long)target);
            continue;
        }
        site->installed = 1;
        ok++;
    }

    g_mm_skin_hooks_ok = ok;
    g_mm_skin_installed = (ok > 0) ? 1 : 0;
    if (ok > 0) g_mm_skin_diag = [NSString stringWithFormat:@"hooks %d/3", ok];
    NSLog(@"%s skins: hooks %d/3 base=0x%lX", MM_TAG, ok,
          (unsigned long)g_mm_skin_base);
    return ok;
}

static void mm_skin_uninstall_all(void)
{
    for (int i = 0; i < 3; i++) {
        MMSkinSite *site = &g_mm_skin_sites[i];
        if (!site->installed) continue;
        uintptr_t target = g_mm_skin_base + (uintptr_t)site->rva;
        if (mm_skin_write16(target, site->saved) != 0)
            NSLog(@"%s skins: no se pudo restaurar %s", MM_TAG, site->name);
        site->installed = 0;
    }
    g_mm_skin_installed = 0;
    g_mm_skin_hooks_ok = 0;
    g_mm_skin_diag = @"off";
    NSLog(@"%s skins: hooks restaurados (off)", MM_TAG);
}

static void mm_skin_read_state(void)
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    g_mm_skin_on = [ud boolForKey:@"mm_skin_master"] ? 1 : 0;
    g_mm_skin_capture = [ud boolForKey:@"mm_skin_capture"] ? 1 : 0;
    g_mm_skin_weapon_id = (uint32_t)[ud integerForKey:@"mm_skin_weapon"];
    g_mm_skin_char_id = (uint32_t)[ud integerForKey:@"mm_skin_char"];
}

static int mm_skin_count(void)
{
    return g_mm_skin_log_n;
}

static NSString *mm_skin_resumen(void)
{
    const char *modo = g_mm_skin_on ? "ON" : (g_mm_skin_capture ? "captura" : "off");
    return [NSString stringWithFormat:@"skins=%s hooks=%d/3 arma=%u traje=%u ids=%d",
            modo, g_mm_skin_hooks_ok,
            (unsigned)g_mm_skin_weapon_id, (unsigned)g_mm_skin_char_id,
            g_mm_skin_log_n];
}

static void mm_skin_set_weapon(uint32_t v)
{
    g_mm_skin_weapon_id = v;
    [[NSUserDefaults standardUserDefaults] setInteger:(NSInteger)v
                                               forKey:@"mm_skin_weapon"];
    if (g_skin_weapon_tf != nil)
        g_skin_weapon_tf.text = (v != 0) ? [NSString stringWithFormat:@"%u", v] : @"";
}

static void mm_skin_set_char(uint32_t v)
{
    g_mm_skin_char_id = v;
    [[NSUserDefaults standardUserDefaults] setInteger:(NSInteger)v
                                               forKey:@"mm_skin_char"];
    if (g_skin_char_tf != nil)
        g_skin_char_tf.text = (v != 0) ? [NSString stringWithFormat:@"%u", v] : @"";
}

static uint32_t mm_skin_parse_field(UITextField *tf)
{
    if (tf == nil || tf.text.length == 0) return 0;
    NSString *s = [tf.text stringByTrimmingCharactersInSet:
                   [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (s.length == 0) return 0;
    const char *c = s.UTF8String;
    if (c == NULL || c[0] == '-') return 0;
    char *end = NULL;
    unsigned long long v = strtoull(c, &end, 0);
    if (end == c || v > 0xFFFFFFFFULL) return 0;
    return (uint32_t)v;
}

static void mm_skin_sync_ui(void)
{
    if (g_skin_master_sw != nil) g_skin_master_sw.on = g_mm_skin_on ? YES : NO;
    if (g_skin_capture_sw != nil) g_skin_capture_sw.on = g_mm_skin_capture ? YES : NO;
    if (g_skin_weapon_tf != nil && !g_skin_weapon_tf.isFirstResponder)
        g_skin_weapon_tf.text = (g_mm_skin_weapon_id != 0)
            ? [NSString stringWithFormat:@"%u", g_mm_skin_weapon_id] : @"";
    if (g_skin_char_tf != nil && !g_skin_char_tf.isFirstResponder)
        g_skin_char_tf.text = (g_mm_skin_char_id != 0)
            ? [NSString stringWithFormat:@"%u", g_mm_skin_char_id] : @"";
    if (g_skin_preset_seg != nil) {
        int sel = 0;
        for (int i = 1; i < 6; i++)
            if (g_skin_presets[i] == g_mm_skin_weapon_id) sel = i;
        g_skin_preset_seg.selectedSegmentIndex = sel;
    }
}

static void mm_skin_refresh_status(void)
{
    if (g_skin_status == nil) return;
    @try {
        NSString *base = (g_mm_skin_base != 0)
            ? [NSString stringWithFormat:@"0x%lX", (unsigned long)g_mm_skin_base]
            : @"-";
        g_skin_status.text = [NSString stringWithFormat:
            @"hooks %d/3  base %@\narma %u  traje %u\ncapturados %d  %@\n%@",
            g_mm_skin_hooks_ok, base,
            (unsigned)g_mm_skin_weapon_id, (unsigned)g_mm_skin_char_id,
            g_mm_skin_log_n,
            g_mm_skin_on ? @"ON" : (g_mm_skin_capture ? @"captura" : @"off"),
            g_mm_skin_diag ?: @"-"];
    } @catch (NSException *e) {}
}

static NSString *mm_skin_dump_write(void)
{
    @try {
        NSString *docs = mm_docs_dir();
        if (docs.length == 0) {
            g_mm_skin_diag = @"sin Documents";
            return nil;
        }

        NSMutableString *s = [NSMutableString string];
        [s appendFormat:@"CODM ModMenu %s - Skin ID dump\n", MODMENU_VERSION];
        [s appendFormat:@"fecha\t%@\n", [NSDate date]];
        [s appendFormat:@"arma_sel\t%u\n", (unsigned)g_mm_skin_weapon_id];
        [s appendFormat:@"traje_sel\t%u\n", (unsigned)g_mm_skin_char_id];
        [s appendFormat:@"hooks\t%d/3\tbase\t0x%lX\n\n", g_mm_skin_hooks_ok,
         (unsigned long)g_mm_skin_base];
        [s appendString:@"# tipo\tid1\tid2\n"];

        pthread_mutex_lock(&g_mm_skin_log_mtx);
        int n = g_mm_skin_log_n;
        for (int i = 0; i < n; i++) {
            [s appendFormat:@"%s\t%u\t%u\n",
             mm_skin_kind_name(g_mm_skin_log[i].kind),
             (unsigned)g_mm_skin_log[i].a,
             (unsigned)g_mm_skin_log[i].b];
        }
        int drop = g_mm_skin_log_drop;
        pthread_mutex_unlock(&g_mm_skin_log_mtx);

        [s appendFormat:@"\n# total\t%d\tperdidos\t%d\n", n, drop];
        NSString *path = [docs stringByAppendingPathComponent:@"CODM_SkinDump.txt"];
        NSError *err = nil;
        if (![s writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&err]) {
            g_mm_skin_diag = [NSString stringWithFormat:@"error dump: %@",
                              err.localizedDescription ?: @"?"];
            NSLog(@"%s skins: dump fallo: %@", MM_TAG, err.localizedDescription);
            return nil;
        }
        g_mm_skin_last_dump = path;
        g_mm_skin_diag = [NSString stringWithFormat:@"dump %d IDs", n];
        NSLog(@"%s skins: dump %d IDs en %@", MM_TAG, n, path);
        mm_skin_refresh_status();
        mm_write_status(@"dump skins");
        return path;
    } @catch (NSException *e) {
        NSLog(@"%s skins: excepcion en dump: %@", MM_TAG, e.reason);
        return nil;
    }
}

/*---------------------------------------------------------------------------
 * FASE D v0.2.9 - GUEST RESET.
 * Replica el mecanismo de GL: borra los datos locales y la keychain de
 * contrasenas genericas, avisa y cierra con _exit(0). El operador debe
 * probarlo en un equipo desechable y con cuenta de invitado.
 *--------------------------------------------------------------------------*/

static UIViewController *mm_top_vc(void)
{
    @try {
        UIWindow *w = mm_host_window();
        UIViewController *vc = (w != nil) ? w.rootViewController : nil;
        while (vc.presentedViewController != nil) vc = vc.presentedViewController;
        return vc;
    } @catch (NSException *e) {
        return nil;
    }
}

static void mm_show_alert(NSString *titulo, NSString *msg)
{
    @try {
        UIViewController *vc = mm_top_vc();
        if (vc == nil) {
            NSLog(@"%s alerta sin VC: %@ / %@", MM_TAG, titulo, msg);
            return;
        }
        UIAlertController *a = [UIAlertController alertControllerWithTitle:titulo
                                                                  message:msg
                                                           preferredStyle:UIAlertControllerStyleAlert];
        [a addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];
        [vc presentViewController:a animated:YES completion:nil];
    } @catch (NSException *e) {
        NSLog(@"%s alerta: %@", MM_TAG, e.reason);
    }
}

static void mm_guest_wipe(void)
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *home = NSHomeDirectory();
    NSArray *paths = @[
        [home stringByAppendingPathComponent:@"Documents"],
        [home stringByAppendingPathComponent:@"Library/Application Support"],
        [home stringByAppendingPathComponent:@"Library/Caches"],
        [home stringByAppendingPathComponent:@"Library/Preferences"],
        [home stringByAppendingPathComponent:@"tmp"]
    ];
    for (NSString *p in paths) {
        NSError *err = nil;
        BOOL ok = [fm removeItemAtPath:p error:&err];
        NSLog(@"%s guest: %@ (%@)", MM_TAG, p,
              ok ? @"borrado" : (err.localizedDescription ?: @"no existia"));
    }

    NSDictionary *q = @{ (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword };
    OSStatus st = SecItemDelete((__bridge CFDictionaryRef)q);
    NSLog(@"%s guest: keychain generic=%d", MM_TAG, (int)st);
}

static void mm_guest_countdown(UIAlertController *a, int sec)
{
    if (a != nil) {
        a.message = [NSString stringWithFormat:
                     @"Fresh guest on relaunch in %d seconds.", sec];
    }
    if (sec <= 0) {
        NSLog(@"%s guest: _exit(0)", MM_TAG);
        _exit(0);
        return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)NSEC_PER_SEC),
                   dispatch_get_main_queue(), ^{
        mm_guest_countdown(a, sec - 1);
    });
}

static void mm_guest_start_exit(void)
{
    UIViewController *vc = mm_top_vc();
    UIAlertController *a = nil;
    if (vc != nil) {
        a = [UIAlertController alertControllerWithTitle:@"Guest Reset Done"
                                                message:@"Fresh guest on relaunch in 3 seconds."
                                         preferredStyle:UIAlertControllerStyleAlert];
        [a addAction:[UIAlertAction actionWithTitle:@"Cerrar ahora"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *x) {
            _exit(0);
        }]];
        [vc presentViewController:a animated:YES completion:nil];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        mm_guest_countdown(a, 3);
    });
}

static void mm_guest_reset_prompt(void)
{
    @try {
        UIViewController *vc = mm_top_vc();
        if (vc == nil) {
            mm_guest_wipe();
            _exit(0);
            return;
        }
        UIAlertController *a = [UIAlertController
            alertControllerWithTitle:@"Reset guest"
                             message:@"Borra Documents, Library, tmp y la keychain. "
                                     @"El juego se cerrara y al reabrir entrara como invitado nuevo."
                      preferredStyle:UIAlertControllerStyleAlert];
        [a addAction:[UIAlertAction actionWithTitle:@"Cancelar"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
        [a addAction:[UIAlertAction actionWithTitle:@"Borrar y cerrar"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *x) {
            mm_guest_wipe();
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                         (int64_t)(0.35 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                mm_guest_start_exit();
            });
        }]];
        [vc presentViewController:a animated:YES completion:nil];
    } @catch (NSException *e) {
        NSLog(@"%s guest reset: %@", MM_TAG, e.reason);
    }
}

static void mm_skin_apply(void)
{
    mm_skin_read_state();
    BOOL want = (g_mm_skin_on || g_mm_skin_capture);
    if (want) {
        if (!g_mm_skin_installed) mm_skin_install_all();
    } else if (g_mm_skin_installed) {
        mm_skin_uninstall_all();
    }
    mm_skin_sync_ui();
    mm_skin_refresh_status();
    mm_write_status(@"skins");
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
            @"esp=%d cajas=%d nombres=%d distancia=%d salud=%d lineas=%d arriba=%d rango=%d contador=%d estilo=%d tema=%d\n"
            @"stream=%d\n"
            @"render=%s cajas=%d link=%s\n"
            @"probe=%s\n"
            @"esp_real=%@ lista=%d dibujados=%d jug=%d bot=%d\n"
            @"skins=%d cap=%d hooks=%d/3 arma=%u traje=%u ids=%d\n"
            @"skindump=%@\n"
            @"nojb=%@\n"
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
            (int)mm_def_bool(@"mm_esp_lines_top", NO),
            (int)mm_def_float(@"mm_esp_range", 300.0f),
            (int)mm_def_bool(@"mm_esp_count", NO),
            (int)mm_def_float(@"mm_esp_box_style", 0.0f),
            (int)mm_def_float(@"mm_esp_theme", 0.0f),
            (int)mm_def_bool(@"mm_stream", NO),
            (g_esp != nil && g_esp.superview != nil && !g_esp.hidden) ? "on" : "off",
            g_box_count,
            (g_link != nil && !g_link.paused) ? "activo" : "parado",
            g_probe != nil ? g_probe.UTF8String : "pendiente",
            (g_esp_diag != nil) ? g_esp_diag : @"-",
            g_esp_players, g_box_count, g_count_players, g_count_bots,
            (int)g_mm_skin_on, (int)g_mm_skin_capture, g_mm_skin_hooks_ok,
            (unsigned)g_mm_skin_weapon_id, (unsigned)g_mm_skin_char_id,
            g_mm_skin_log_n,
            (g_mm_skin_last_dump != nil) ? g_mm_skin_last_dump : @"-",
            mm_nojb_resumen(),
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

/*---------------------------------------------------------------------------
 * v0.3.1: estetica glass neon (SOLO UI).
 *   - verde/morado con CAGradientLayer animado y borde que cambia de color;
 *   - blur publico de UIKit, sin private APIs y sin frameworks nuevos.
 *--------------------------------------------------------------------------*/
static UIColor *mm_neon_green(void)
{
    return [UIColor colorWithRed:0.20 green:1.00 blue:0.58 alpha:1.0];
}

static UIColor *mm_neon_purple(void)
{
    return [UIColor colorWithRed:0.63 green:0.30 blue:1.00 alpha:1.0];
}

static void mm_start_neon_gradient(CAGradientLayer *g)
{
    if (g == nil || g.colors.count < 2) return;
    if ([g animationForKey:@"mmNeonColors"] == nil) {
        CABasicAnimation *a = [CABasicAnimation animationWithKeyPath:@"colors"];
        a.fromValue = g.colors;
        a.toValue = [[g.colors reverseObjectEnumerator] allObjects];
        a.duration = 9.0;
        a.autoreverses = YES;
        a.repeatCount = HUGE_VALF;
        a.timingFunction = [CAMediaTimingFunction
                            functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [g addAnimation:a forKey:@"mmNeonColors"];
    }
    if ([g animationForKey:@"mmNeonStart"] == nil) {
        CABasicAnimation *a = [CABasicAnimation animationWithKeyPath:@"startPoint"];
        a.fromValue = [NSValue valueWithCGPoint:g.startPoint];
        a.toValue = [NSValue valueWithCGPoint:CGPointMake(1.0, 0.0)];
        a.duration = 7.0;
        a.autoreverses = YES;
        a.repeatCount = HUGE_VALF;
        a.timingFunction = [CAMediaTimingFunction
                            functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [g addAnimation:a forKey:@"mmNeonStart"];
    }
    if ([g animationForKey:@"mmNeonEnd"] == nil) {
        CABasicAnimation *a = [CABasicAnimation animationWithKeyPath:@"endPoint"];
        a.fromValue = [NSValue valueWithCGPoint:g.endPoint];
        a.toValue = [NSValue valueWithCGPoint:CGPointMake(0.0, 1.0)];
        a.duration = 7.0;
        a.autoreverses = YES;
        a.repeatCount = HUGE_VALF;
        a.timingFunction = [CAMediaTimingFunction
                            functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [g addAnimation:a forKey:@"mmNeonEnd"];
    }
}

static void mm_start_neon_border(CALayer *l, UIColor *a, UIColor *b,
                                 CFTimeInterval duracion)
{
    if (l == nil || a == nil || b == nil) return;
    if ([l animationForKey:@"mmNeonBorder"] != nil) return;
    CABasicAnimation *x = [CABasicAnimation animationWithKeyPath:@"borderColor"];
    x.fromValue = (__bridge id)a.CGColor;
    x.toValue = (__bridge id)b.CGColor;
    x.duration = duracion;
    x.autoreverses = YES;
    x.repeatCount = HUGE_VALF;
    x.timingFunction = [CAMediaTimingFunction
                        functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [l addAnimation:x forKey:@"mmNeonBorder"];
}

static void mm_layout_panel_glass(void)
{
    if (g_panel == nil) return;
    CGRect b = g_panel.bounds;
    if (g_panel_neon != nil)  g_panel_neon.frame = b;
    if (g_panel_blur != nil)  g_panel_blur.frame = b;
    if (g_panel_shade != nil) g_panel_shade.frame = b;
    g_panel.layer.shadowPath =
        [UIBezierPath bezierPathWithRoundedRect:b cornerRadius:18.0].CGPath;
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

/* v0.2.9: barra "Listo" para cerrar el teclado numerico de los campos de ID. */
static UIToolbar *mm_skin_done_bar(void)
{
    UIToolbar *tb = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    tb.barStyle = UIBarStyleBlack;
    tb.items = @[
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                      target:nil action:nil],
        [[UIBarButtonItem alloc] initWithTitle:@"Listo"
                                         style:UIBarButtonItemStyleDone
                                        target:[MMTargets shared]
                                        action:@selector(onTextDone:)]
    ];
    return tb;
}

/* Crea boton flotante + panel (una sola vez). */
static void mm_build_ui(void)
{
    /* --- boton flotante (v0.3.1: glass neon) --- */
    if (g_btn == nil) {
        g_btn = [UIButton buttonWithType:UIButtonTypeCustom];
        g_btn.bounds = CGRectMake(0, 0, 54.0, 54.0);
        g_btn.backgroundColor = [UIColor colorWithRed:0.02 green:0.08 blue:0.05 alpha:0.86];
        g_btn.layer.cornerRadius = 27.0;
        g_btn.layer.borderWidth = 1.2;
        g_btn.layer.borderColor =
            [mm_neon_green() colorWithAlphaComponent:0.90].CGColor;
        g_btn.layer.shadowColor =
            [mm_neon_purple() colorWithAlphaComponent:0.95].CGColor;
        g_btn.layer.shadowOpacity = 0.55;
        g_btn.layer.shadowRadius = 12.0;
        g_btn.layer.shadowOffset = CGSizeZero;
        g_btn.clipsToBounds = NO;
        [g_btn setTitle:@"MENU" forState:UIControlStateNormal];
        [g_btn setTitleColor:[UIColor colorWithWhite:0.97 alpha:1.0]
                    forState:UIControlStateNormal];
        UIFont *bf = [UIFont fontWithName:@"Menlo-Bold" size:10.0];
        if (bf == nil) bf = [UIFont boldSystemFontOfSize:10.0];
        g_btn.titleLabel.font = bf;
        [g_btn addTarget:[MMTargets shared] action:@selector(onTap)
        forControlEvents:UIControlEventTouchUpInside];
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]
            initWithTarget:[MMTargets shared] action:@selector(onPan:)];
        [g_btn addGestureRecognizer:pan];

        g_btn_neon = [CAGradientLayer layer];
        g_btn_neon.frame = g_btn.bounds;
        g_btn_neon.cornerRadius = 27.0;
        g_btn_neon.masksToBounds = YES;
        g_btn_neon.startPoint = CGPointMake(0.0, 0.0);
        g_btn_neon.endPoint = CGPointMake(1.0, 1.0);
        g_btn_neon.locations = @[@0.0, @0.38, @0.72, @1.0];
        CGColorRef bg1 = [UIColor colorWithRed:0.02 green:0.20 blue:0.10 alpha:0.96].CGColor;
        CGColorRef bg2 = [UIColor colorWithRed:0.05 green:0.48 blue:0.30 alpha:0.90].CGColor;
        CGColorRef bg3 = [UIColor colorWithRed:0.34 green:0.09 blue:0.58 alpha:0.96].CGColor;
        CGColorRef bg4 = [UIColor colorWithRed:0.09 green:0.28 blue:0.17 alpha:0.94].CGColor;
        g_btn_neon.colors = @[(__bridge id)bg1, (__bridge id)bg2,
                              (__bridge id)bg3, (__bridge id)bg4];
        [g_btn.layer insertSublayer:g_btn_neon atIndex:0];

        CAGradientLayer *shine = [CAGradientLayer layer];
        shine.frame = g_btn.bounds;
        shine.cornerRadius = 27.0;
        shine.startPoint = CGPointMake(0.0, 0.0);
        shine.endPoint = CGPointMake(0.0, 1.0);
        CGColorRef sh1 = [UIColor colorWithWhite:1.0 alpha:0.20].CGColor;
        CGColorRef sh2 = [UIColor colorWithWhite:1.0 alpha:0.0].CGColor;
        shine.colors = @[(__bridge id)sh1, (__bridge id)sh2];
        [g_btn.layer insertSublayer:shine atIndex:1];

        g_btn.layer.shadowPath =
            [UIBezierPath bezierPathWithOvalInRect:g_btn.bounds].CGPath;
        mm_start_neon_gradient(g_btn_neon);
        mm_start_neon_border(g_btn.layer, mm_neon_green(), mm_neon_purple(), 6.0);

        CABasicAnimation *pulse =
            [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
        pulse.fromValue = @0.35;
        pulse.toValue = @0.78;
        pulse.duration = 3.2;
        pulse.autoreverses = YES;
        pulse.repeatCount = HUGE_VALF;
        pulse.timingFunction = [CAMediaTimingFunction
                                functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [g_btn.layer addAnimation:pulse forKey:@"mmNeonPulse"];
    }

    /* --- lienzo del ESP + latido de dibujo (~30 fps) --- */
    if (g_esp == nil) {
        g_esp = [[MMCanvasView alloc] initWithFrame:CGRectZero];
        g_esp.backgroundColor = [UIColor clearColor];
        g_esp.opaque = NO;   /* v0.2.7: sin fondo opaco (evita restos/parpadeo) */
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

    /* --- panel (v0.3.1: vidrio oscuro + gradiente neon animado) --- */
    g_panel = [[UIView alloc] initWithFrame:CGRectMake(0, 0, MM_PANEL_W, MM_PANEL_H)];
    g_panel.backgroundColor = [UIColor colorWithRed:0.01 green:0.02 blue:0.03 alpha:0.42];
    g_panel.layer.cornerRadius = 18.0;
    g_panel.layer.borderWidth = 1.1;
    g_panel.layer.borderColor =
        [mm_neon_green() colorWithAlphaComponent:0.78].CGColor;
    g_panel.layer.shadowColor =
        [mm_neon_purple() colorWithAlphaComponent:0.90].CGColor;
    g_panel.layer.shadowOpacity = 0.55;
    g_panel.layer.shadowRadius = 18.0;
    g_panel.layer.shadowOffset = CGSizeMake(0.0, 8.0);
    g_panel.clipsToBounds = NO;
    g_panel.hidden = YES;
    g_panel.alpha = 0.0;

    g_panel_neon = [CAGradientLayer layer];
    g_panel_neon.frame = g_panel.bounds;
    g_panel_neon.cornerRadius = 18.0;
    g_panel_neon.masksToBounds = YES;
    g_panel_neon.startPoint = CGPointMake(0.0, 0.0);
    g_panel_neon.endPoint = CGPointMake(1.0, 1.0);
    g_panel_neon.locations = @[@0.0, @0.35, @0.68, @1.0];
    CGColorRef p1 = [UIColor colorWithRed:0.08 green:0.88 blue:0.45 alpha:0.72].CGColor;
    CGColorRef p2 = [UIColor colorWithRed:0.00 green:0.62 blue:0.72 alpha:0.42].CGColor;
    CGColorRef p3 = [UIColor colorWithRed:0.58 green:0.18 blue:1.00 alpha:0.68].CGColor;
    CGColorRef p4 = [UIColor colorWithRed:0.22 green:0.03 blue:0.52 alpha:0.58].CGColor;
    g_panel_neon.colors = @[(__bridge id)p1, (__bridge id)p2,
                            (__bridge id)p3, (__bridge id)p4];
    [g_panel.layer insertSublayer:g_panel_neon atIndex:0];

    g_panel_blur = [[UIVisualEffectView alloc] initWithEffect:
                    [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    g_panel_blur.frame = g_panel.bounds;
    g_panel_blur.userInteractionEnabled = NO;
    g_panel_blur.alpha = 0.85;
    g_panel_blur.layer.cornerRadius = 18.0;
    g_panel_blur.clipsToBounds = YES;
    [g_panel addSubview:g_panel_blur];

    g_panel_shade = [[UIView alloc] initWithFrame:g_panel.bounds];
    g_panel_shade.backgroundColor =
        [UIColor colorWithRed:0.01 green:0.015 blue:0.025 alpha:0.54];
    g_panel_shade.userInteractionEnabled = NO;
    g_panel_shade.layer.cornerRadius = 18.0;
    g_panel_shade.clipsToBounds = YES;
    g_panel_shade.layer.borderWidth = 0.8;
    g_panel_shade.layer.borderColor =
        [mm_neon_purple() colorWithAlphaComponent:0.30].CGColor;
    [g_panel addSubview:g_panel_shade];

    mm_layout_panel_glass();
    mm_start_neon_gradient(g_panel_neon);
    mm_start_neon_border(g_panel.layer, mm_neon_green(), mm_neon_purple(), 8.0);

    /* v0.2.4: zona de arrastre del panel (franja superior). Va ANTES que el
       titulo y la X para no taparlos. */
    UIView *dz = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, MM_PANEL_W, 32.0)];
    dz.backgroundColor = [UIColor clearColor];
    dz.userInteractionEnabled = YES;
    UIPanGestureRecognizer *dpan = [[UIPanGestureRecognizer alloc]
        initWithTarget:[MMTargets shared] action:@selector(onPanelPan:)];
    [dz addGestureRecognizer:dpan];
    [g_panel addSubview:dz];

    UILabel *h = [[UILabel alloc] initWithFrame:CGRectMake(14.0, 8.0, 222.0, 20.0)];
    UIFont *hf = [UIFont fontWithName:@"Menlo-Bold" size:13.5];
    if (hf == nil) hf = [UIFont boldSystemFontOfSize:13.5];
    UIFont *vf = [UIFont fontWithName:@"Menlo-Bold" size:9.5];
    if (vf == nil) vf = [UIFont boldSystemFontOfSize:9.5];
    NSMutableAttributedString *ht = [[NSMutableAttributedString alloc]
        initWithString:@"MODMENU"
            attributes:@{ NSFontAttributeName: hf,
                          NSForegroundColorAttributeName: mm_neon_green(),
                          NSKernAttributeName: @1.2 }];
    [ht appendAttributedString:[[NSAttributedString alloc]
        initWithString:@"  "
            attributes:@{ NSFontAttributeName: hf }]];
    [ht appendAttributedString:[[NSAttributedString alloc]
        initWithString:[NSString stringWithFormat:@"%s", MODMENU_VERSION]
            attributes:@{ NSFontAttributeName: vf,
                          NSForegroundColorAttributeName:
                              [mm_neon_purple() colorWithAlphaComponent:0.95],
                          NSKernAttributeName: @0.3 }]];
    h.attributedText = ht;
    h.adjustsFontSizeToFitWidth = YES;
    h.minimumScaleFactor = 0.8;
    [g_panel addSubview:h];

    UIButton *x = [UIButton buttonWithType:UIButtonTypeCustom];
    x.frame = CGRectMake(MM_PANEL_W - 46.0, 5.0, 40.0, 28.0);
    x.backgroundColor = [UIColor colorWithWhite:0.05 alpha:0.55];
    x.layer.cornerRadius = 14.0;
    x.layer.borderWidth = 0.7;
    x.layer.borderColor =
        [mm_neon_purple() colorWithAlphaComponent:0.55].CGColor;
    x.clipsToBounds = YES;
    [x setTitle:@"X" forState:UIControlStateNormal];
    [x setTitleColor:[UIColor colorWithWhite:0.94 alpha:1.0]
             forState:UIControlStateNormal];
    x.titleLabel.font = [UIFont boldSystemFontOfSize:13.0];
    [x addTarget:[MMTargets shared] action:@selector(onClose)
        forControlEvents:UIControlEventTouchUpInside];
    [g_panel addSubview:x];

    g_seg = [[UISegmentedControl alloc] initWithItems:@[@"ESP", @"VIS", @"MISC", @"SKINS", @"INFO"]];
    g_seg.frame = CGRectMake(10.0, 36.0, MM_PANEL_W - 20.0, 30.0);
    g_seg.selectedSegmentIndex = 0;
    g_seg.backgroundColor = [UIColor colorWithWhite:0.02 alpha:0.50];
    g_seg.layer.cornerRadius = 9.0;
    g_seg.layer.masksToBounds = YES;
    g_seg.layer.borderWidth = 0.6;
    g_seg.layer.borderColor =
        [mm_neon_purple() colorWithAlphaComponent:0.35].CGColor;
    if ([g_seg respondsToSelector:@selector(setSelectedSegmentTintColor:)])
        g_seg.selectedSegmentTintColor =
            [UIColor colorWithRed:0.42 green:0.15 blue:0.78 alpha:0.92];
    else
        g_seg.tintColor = mm_neon_purple();
    [g_seg setTitleTextAttributes:@{ NSForegroundColorAttributeName:
            [UIColor colorWithWhite:0.86 alpha:1.0],
            NSFontAttributeName: [UIFont boldSystemFontOfSize:11.0] }
                          forState:UIControlStateNormal];
    [g_seg setTitleTextAttributes:@{ NSForegroundColorAttributeName:
            [UIColor whiteColor],
            NSFontAttributeName: [UIFont boldSystemFontOfSize:11.0] }
                          forState:UIControlStateSelected];
    [g_seg addTarget:[MMTargets shared] action:@selector(onSeg:)
        forControlEvents:UIControlEventValueChanged];
    [g_panel addSubview:g_seg];

    g_p_esp  = [[UIView alloc] initWithFrame:CGRectMake(8.0, 74.0, 284.0, 348.0)];
    g_p_vis  = [[UIView alloc] initWithFrame:CGRectMake(8.0, 74.0, 284.0, 348.0)];
    g_p_misc = [[UIView alloc] initWithFrame:CGRectMake(8.0, 74.0, 284.0, 348.0)];
    g_p_skins = [[UIView alloc] initWithFrame:CGRectMake(8.0, 74.0, 284.0, 348.0)];
    g_p_info = [[UIView alloc] initWithFrame:CGRectMake(8.0, 74.0, 284.0, 348.0)];
    g_p_vis.hidden = YES;
    g_p_misc.hidden = YES;
    g_p_skins.hidden = YES;
    g_p_info.hidden = YES;
    [g_panel addSubview:g_p_esp];
    [g_panel addSubview:g_p_vis];
    [g_panel addSubview:g_p_misc];
    [g_panel addSubview:g_p_skins];
    [g_panel addSubview:g_p_info];

    /* --- pagina ESP --- */
    NSArray *keys = @[@"mm_esp_master", @"mm_esp_box", @"mm_esp_players",
                      @"mm_esp_bots", @"mm_esp_name", @"mm_esp_dist",
                      @"mm_esp_health", @"mm_esp_lines", @"mm_esp_lines_top",
                      @"mm_esp_fill"];
    NSArray *titulos = @[@"ESP maestro", @"Cajas", @"Jugadores",
                         @"Bots", @"Nombres", @"Distancia",
                         @"Salud", @"Lineas", @"Lineas desde arriba",
                         @"Relleno"];
    g_sub_switches = [NSMutableArray array];
    for (NSUInteger i = 0; i < keys.count; i++) {
        UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 51.0, 31.0)];
        /* v0.2.7: todo arranca apagado, tambien Jugadores/Bots (antes venian
           ON por defecto). Con el reseteo de arranque la clave casi nunca
           existe al construir; el default queda como red de seguridad. */
        sw.on = mm_def_bool(keys[i], NO);
        sw.onTintColor = mm_verde();
        sw.accessibilityIdentifier = keys[i];
        /* v0.2.5: 10 filas; el switch se reduce al 90% para que la fila de
           29.5 pt no se solape con la siguiente y quepa el nuevo toggle. */
        sw.transform = CGAffineTransformMakeScale(0.9, 0.9);
        [sw addTarget:[MMTargets shared] action:@selector(onSwitch:)
            forControlEvents:UIControlEventValueChanged];
        UIView *row = mm_row(titulos[i], sw);
        row.frame = CGRectMake(0, (CGFloat)i * 29.5, 284.0, 31.0);
        [g_p_esp addSubview:row];
        if (i > 0) [g_sub_switches addObject:sw];
    }

    float rng = mm_def_float(@"mm_esp_range", 300.0f);

    UILabel *rt = [[UILabel alloc] initWithFrame:CGRectMake(6.0, 298.0, 190.0, 18.0)];
    rt.text = @"Rango ESP (m)";
    rt.textColor = [UIColor whiteColor];
    rt.font = [UIFont systemFontOfSize:13.0];
    [g_p_esp addSubview:rt];

    g_range_val = [[UILabel alloc] initWithFrame:CGRectMake(200.0, 298.0, 78.0, 18.0)];
    g_range_val.text = [NSString stringWithFormat:@"%d m", (int)(rng + 0.5f)];
    g_range_val.textColor = [UIColor colorWithWhite:0.8 alpha:1.0];
    g_range_val.font = [UIFont systemFontOfSize:12.0];
    g_range_val.textAlignment = NSTextAlignmentRight;
    [g_p_esp addSubview:g_range_val];

    UISlider *sl = [[UISlider alloc] initWithFrame:CGRectMake(6.0, 315.0, 272.0, 30.0)];
    sl.minimumValue = 20.0f;
    sl.maximumValue = 500.0f;
    sl.value = rng;
    sl.accessibilityIdentifier = @"mm_esp_range";
    sl.tintColor = mm_verde();
    sl.thumbTintColor = [UIColor colorWithRed:0.80 green:1.0 blue:0.86 alpha:1.0];
    [sl addTarget:[MMTargets shared] action:@selector(onSlider:)
        forControlEvents:UIControlEventValueChanged];
    [g_p_esp addSubview:sl];

    /* --- pagina VIS (v0.3.0: Stream Mode + pulido ESP) --- */
    UIView *vr = mm_switch_row(@"Stream Mode (ocultar UI)", @"mm_stream", NO);
    vr.frame = CGRectMake(0, 2.0, 284.0, 34.0);
    [g_p_vis addSubview:vr];

    UILabel *vd = [[UILabel alloc] initWithFrame:CGRectMake(6.0, 40.0, 272.0, 44.0)];
    vd.text = @"Cierra el panel y oculta la marca de agua. El boton MENU "
              @"queda al 10% y sigue tocable para volver.";
    vd.numberOfLines = 0;
    vd.textColor = [UIColor colorWithWhite:0.72 alpha:1.0];
    vd.font = [UIFont systemFontOfSize:10.5];
    [g_p_vis addSubview:vd];

    UILabel *vh = [[UILabel alloc] initWithFrame:CGRectMake(6.0, 90.0, 272.0, 18.0)];
    vh.text = @"ESP EN PANTALLA";
    vh.textColor = [UIColor colorWithRed:0.55 green:1.0 blue:0.66 alpha:1.0];
    vh.font = [UIFont boldSystemFontOfSize:11.0];
    [g_p_vis addSubview:vh];

    UISwitch *cs = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 51.0, 31.0)];
    cs.on = mm_def_bool(@"mm_esp_count", NO);
    cs.onTintColor = mm_verde();
    cs.accessibilityIdentifier = @"mm_esp_count";
    cs.transform = CGAffineTransformMakeScale(0.9, 0.9);
    [cs addTarget:[MMTargets shared] action:@selector(onSwitch:)
        forControlEvents:UIControlEventValueChanged];
    UIView *csr = mm_row(@"Contador JUG / BOT", cs);
    csr.frame = CGRectMake(0, 108.0, 284.0, 31.0);
    [g_p_vis addSubview:csr];
    [g_sub_switches addObject:cs];

    UILabel *vsl = [[UILabel alloc] initWithFrame:CGRectMake(6.0, 144.0, 272.0, 15.0)];
    vsl.text = @"Estilo de caja";
    vsl.textColor = [UIColor colorWithWhite:0.80 alpha:1.0];
    vsl.font = [UIFont systemFontOfSize:11.0];
    [g_p_vis addSubview:vsl];

    UISegmentedControl *bs = [[UISegmentedControl alloc]
        initWithItems:@[@"Completa", @"Esquinas"]];
    bs.frame = CGRectMake(6.0, 160.0, 272.0, 30.0);
    bs.selectedSegmentIndex =
        ((int)mm_def_float(@"mm_esp_box_style", 0.0f) == 1) ? 1 : 0;
    if ([bs respondsToSelector:@selector(setSelectedSegmentTintColor:)])
        bs.selectedSegmentTintColor =
            [UIColor colorWithRed:0.10 green:0.55 blue:0.25 alpha:1.0];
    else
        bs.tintColor = mm_verde();
    [bs setTitleTextAttributes:@{ NSForegroundColorAttributeName:
            [UIColor colorWithWhite:0.88 alpha:1.0],
            NSFontAttributeName: [UIFont systemFontOfSize:11.0] }
                      forState:UIControlStateNormal];
    [bs setTitleTextAttributes:@{ NSForegroundColorAttributeName:
            [UIColor whiteColor],
            NSFontAttributeName: [UIFont systemFontOfSize:11.0] }
                      forState:UIControlStateSelected];
    [bs addTarget:[MMTargets shared] action:@selector(onBoxStyle:)
        forControlEvents:UIControlEventValueChanged];
    [g_p_vis addSubview:bs];

    UILabel *vtl = [[UILabel alloc] initWithFrame:CGRectMake(6.0, 196.0, 272.0, 15.0)];
    vtl.text = @"Tema de color";
    vtl.textColor = [UIColor colorWithWhite:0.80 alpha:1.0];
    vtl.font = [UIFont systemFontOfSize:11.0];
    [g_p_vis addSubview:vtl];

    UISegmentedControl *ts = [[UISegmentedControl alloc]
        initWithItems:@[@"Clasico", @"Neon", @"Blanco"]];
    ts.frame = CGRectMake(6.0, 212.0, 272.0, 30.0);
    {
        int t = (int)mm_def_float(@"mm_esp_theme", 0.0f);
        if (t < 0 || t > 2) t = 0;
        ts.selectedSegmentIndex = t;
    }
    if ([ts respondsToSelector:@selector(setSelectedSegmentTintColor:)])
        ts.selectedSegmentTintColor =
            [UIColor colorWithRed:0.10 green:0.55 blue:0.25 alpha:1.0];
    else
        ts.tintColor = mm_verde();
    [ts setTitleTextAttributes:@{ NSForegroundColorAttributeName:
            [UIColor colorWithWhite:0.88 alpha:1.0],
            NSFontAttributeName: [UIFont systemFontOfSize:11.0] }
                      forState:UIControlStateNormal];
    [ts setTitleTextAttributes:@{ NSForegroundColorAttributeName:
            [UIColor whiteColor],
            NSFontAttributeName: [UIFont systemFontOfSize:11.0] }
                      forState:UIControlStateSelected];
    [ts addTarget:[MMTargets shared] action:@selector(onTheme:)
        forControlEvents:UIControlEventValueChanged];
    [g_p_vis addSubview:ts];

    UILabel *vn = [[UILabel alloc] initWithFrame:CGRectMake(6.0, 252.0, 272.0, 76.0)];
    vn.text = @"El contador refleja solo lo que se esta dibujando, despues "
              @"de los filtros Jugadores/Bots y del rango. El estilo y el tema "
              @"se aplican al instante.";
    vn.numberOfLines = 0;
    vn.textColor = [UIColor colorWithWhite:0.60 alpha:1.0];
    vn.font = [UIFont systemFontOfSize:10.5];
    [g_p_vis addSubview:vn];

    /* --- pagina MISC --- */
    UILabel *d1 = [[UILabel alloc] initWithFrame:CGRectMake(6.0, 6.0, 272.0, 18.0)];
    d1.text = @"Cuenta / datos locales";
    d1.textColor = [UIColor colorWithRed:0.55 green:1.0 blue:0.66 alpha:1.0];
    d1.font = [UIFont boldSystemFontOfSize:12.0];
    [g_p_misc addSubview:d1];

    UIButton *gr = [UIButton buttonWithType:UIButtonTypeCustom];
    gr.frame = CGRectMake(6.0, 28.0, 272.0, 36.0);
    gr.backgroundColor = [UIColor colorWithRed:0.48 green:0.08 blue:0.08 alpha:0.95];
    gr.layer.cornerRadius = 8.0;
    gr.layer.borderWidth = 1.0;
    gr.layer.borderColor = [UIColor colorWithRed:1.0 green:0.45 blue:0.45 alpha:0.7].CGColor;
    [gr setTitle:@"Reset guest (borrar datos)" forState:UIControlStateNormal];
    [gr setTitleColor:[UIColor colorWithRed:1.0 green:0.9 blue:0.9 alpha:1.0]
             forState:UIControlStateNormal];
    gr.titleLabel.font = [UIFont boldSystemFontOfSize:13.0];
    [gr addTarget:[MMTargets shared] action:@selector(onGuestReset)
        forControlEvents:UIControlEventTouchUpInside];
    [g_p_misc addSubview:gr];

    UILabel *d2 = [[UILabel alloc] initWithFrame:CGRectMake(6.0, 72.0, 272.0, 76.0)];
    d2.text = @"Borra Documents, Library, tmp y la keychain de invitado. "
              @"El juego se cierra y al reabrir entra como invitado nuevo. "
              @"Usar solo en un equipo desechable.";
    d2.numberOfLines = 0;
    d2.textColor = [UIColor colorWithWhite:0.72 alpha:1.0];
    d2.font = [UIFont systemFontOfSize:10.5];
    [g_p_misc addSubview:d2];

    UILabel *d3 = [[UILabel alloc] initWithFrame:CGRectMake(6.0, 156.0, 272.0, 44.0)];
    d3.text = @"Skins (armas y traje): pestana SKINS. Stream Mode y ajustes "
              @"visuales del ESP: pestana VIS.";
    d3.numberOfLines = 0;
    d3.textColor = [UIColor colorWithWhite:0.60 alpha:1.0];
    d3.font = [UIFont systemFontOfSize:11.0];
    [g_p_misc addSubview:d3];

    /* --- pagina SKINS (v0.2.9) --- */
    mm_skin_read_state();

    UISwitch *skm = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 51.0, 31.0)];
    skm.on = g_mm_skin_on ? YES : NO;
    skm.onTintColor = mm_verde();
    skm.accessibilityIdentifier = @"mm_skin_master";
    skm.transform = CGAffineTransformMakeScale(0.9, 0.9);
    [skm addTarget:[MMTargets shared] action:@selector(onSwitch:)
        forControlEvents:UIControlEventValueChanged];
    g_skin_master_sw = skm;
    UIView *skmr = mm_row(@"Skin changer (armas)", skm);
    skmr.frame = CGRectMake(0, 0, 284.0, 31.0);
    [g_p_skins addSubview:skmr];

    UISwitch *skc = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 51.0, 31.0)];
    skc.on = g_mm_skin_capture ? YES : NO;
    skc.onTintColor = [UIColor colorWithRed:0.30 green:0.65 blue:1.0 alpha:1.0];
    skc.accessibilityIdentifier = @"mm_skin_capture";
    skc.transform = CGAffineTransformMakeScale(0.9, 0.9);
    [skc addTarget:[MMTargets shared] action:@selector(onSwitch:)
        forControlEvents:UIControlEventValueChanged];
    g_skin_capture_sw = skc;
    UIView *skcr = mm_row(@"Capturar IDs reales", skc);
    skcr.frame = CGRectMake(0, 31.0, 284.0, 31.0);
    [g_p_skins addSubview:skcr];

    UILabel *wl = [[UILabel alloc] initWithFrame:CGRectMake(6.0, 66.0, 272.0, 15.0)];
    wl.text = @"ID de skin (arma)";
    wl.textColor = [UIColor colorWithWhite:0.78 alpha:1.0];
    wl.font = [UIFont systemFontOfSize:11.0];
    [g_p_skins addSubview:wl];

    g_skin_weapon_tf = [[UITextField alloc] initWithFrame:CGRectMake(6.0, 82.0, 186.0, 30.0)];
    g_skin_weapon_tf.backgroundColor = [UIColor colorWithWhite:0.06 alpha:1.0];
    g_skin_weapon_tf.layer.cornerRadius = 6.0;
    g_skin_weapon_tf.layer.borderWidth = 1.0;
    g_skin_weapon_tf.layer.borderColor =
        [UIColor colorWithRed:0.16 green:0.88 blue:0.38 alpha:0.55].CGColor;
    g_skin_weapon_tf.textColor = [UIColor whiteColor];
    g_skin_weapon_tf.font = [UIFont fontWithName:@"Menlo" size:12.0] ?:
                            [UIFont systemFontOfSize:12.0];
    g_skin_weapon_tf.keyboardType = UIKeyboardTypeNumberPad;
    g_skin_weapon_tf.autocorrectionType = UITextAutocorrectionTypeNo;
    g_skin_weapon_tf.spellCheckingType = UITextSpellCheckingTypeNo;
    g_skin_weapon_tf.clearButtonMode = UITextFieldViewModeWhileEditing;
    g_skin_weapon_tf.placeholder = @"ej. 100595";
    g_skin_weapon_tf.text = (g_mm_skin_weapon_id != 0)
        ? [NSString stringWithFormat:@"%u", g_mm_skin_weapon_id] : @"";
    g_skin_weapon_tf.inputAccessoryView = mm_skin_done_bar();
    [g_p_skins addSubview:g_skin_weapon_tf];

    UIButton *wb = [UIButton buttonWithType:UIButtonTypeCustom];
    wb.frame = CGRectMake(196.0, 82.0, 82.0, 30.0);
    wb.backgroundColor = [UIColor colorWithRed:0.08 green:0.42 blue:0.20 alpha:0.95];
    wb.layer.cornerRadius = 6.0;
    [wb setTitle:@"Aplicar" forState:UIControlStateNormal];
    [wb setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    wb.titleLabel.font = [UIFont boldSystemFontOfSize:11.0];
    [wb addTarget:[MMTargets shared] action:@selector(onSkinWeaponSet)
        forControlEvents:UIControlEventTouchUpInside];
    [g_p_skins addSubview:wb];

    UILabel *cl = [[UILabel alloc] initWithFrame:CGRectMake(6.0, 116.0, 272.0, 15.0)];
    cl.text = @"ID de traje (personaje)";
    cl.textColor = [UIColor colorWithWhite:0.78 alpha:1.0];
    cl.font = [UIFont systemFontOfSize:11.0];
    [g_p_skins addSubview:cl];

    g_skin_char_tf = [[UITextField alloc] initWithFrame:CGRectMake(6.0, 132.0, 186.0, 30.0)];
    g_skin_char_tf.backgroundColor = [UIColor colorWithWhite:0.06 alpha:1.0];
    g_skin_char_tf.layer.cornerRadius = 6.0;
    g_skin_char_tf.layer.borderWidth = 1.0;
    g_skin_char_tf.layer.borderColor =
        [UIColor colorWithRed:0.16 green:0.88 blue:0.38 alpha:0.55].CGColor;
    g_skin_char_tf.textColor = [UIColor whiteColor];
    g_skin_char_tf.font = [UIFont fontWithName:@"Menlo" size:12.0] ?:
                          [UIFont systemFontOfSize:12.0];
    g_skin_char_tf.keyboardType = UIKeyboardTypeNumberPad;
    g_skin_char_tf.autocorrectionType = UITextAutocorrectionTypeNo;
    g_skin_char_tf.spellCheckingType = UITextSpellCheckingTypeNo;
    g_skin_char_tf.clearButtonMode = UITextFieldViewModeWhileEditing;
    g_skin_char_tf.placeholder = @"ej. 0";
    g_skin_char_tf.text = (g_mm_skin_char_id != 0)
        ? [NSString stringWithFormat:@"%u", g_mm_skin_char_id] : @"";
    g_skin_char_tf.inputAccessoryView = mm_skin_done_bar();
    [g_p_skins addSubview:g_skin_char_tf];

    UIButton *cb = [UIButton buttonWithType:UIButtonTypeCustom];
    cb.frame = CGRectMake(196.0, 132.0, 82.0, 30.0);
    cb.backgroundColor = [UIColor colorWithRed:0.08 green:0.42 blue:0.20 alpha:0.95];
    cb.layer.cornerRadius = 6.0;
    [cb setTitle:@"Aplicar" forState:UIControlStateNormal];
    [cb setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    cb.titleLabel.font = [UIFont boldSystemFontOfSize:11.0];
    [cb addTarget:[MMTargets shared] action:@selector(onSkinCharSet)
        forControlEvents:UIControlEventTouchUpInside];
    [g_p_skins addSubview:cb];

    UILabel *pl = [[UILabel alloc] initWithFrame:CGRectMake(6.0, 168.0, 272.0, 15.0)];
    pl.text = @"Presets de arma (verificados 1.0.57)";
    pl.textColor = [UIColor colorWithWhite:0.78 alpha:1.0];
    pl.font = [UIFont systemFontOfSize:11.0];
    [g_p_skins addSubview:pl];

    g_skin_preset_seg = [[UISegmentedControl alloc]
        initWithItems:@[@"Off", @"P1", @"P2", @"P3", @"P4", @"P5"]];
    g_skin_preset_seg.frame = CGRectMake(6.0, 184.0, 272.0, 30.0);
    g_skin_preset_seg.selectedSegmentIndex = 0;
    if ([g_skin_preset_seg respondsToSelector:@selector(setSelectedSegmentTintColor:)])
        g_skin_preset_seg.selectedSegmentTintColor =
            [UIColor colorWithRed:0.10 green:0.55 blue:0.25 alpha:1.0];
    else
        g_skin_preset_seg.tintColor = mm_verde();
    [g_skin_preset_seg addTarget:[MMTargets shared] action:@selector(onSkinPreset:)
                 forControlEvents:UIControlEventValueChanged];
    [g_p_skins addSubview:g_skin_preset_seg];

    UIButton *ab = [UIButton buttonWithType:UIButtonTypeCustom];
    ab.frame = CGRectMake(6.0, 220.0, 132.0, 32.0);
    ab.backgroundColor = [UIColor colorWithRed:0.08 green:0.42 blue:0.20 alpha:0.95];
    ab.layer.cornerRadius = 7.0;
    [ab setTitle:@"Aplicar ambos" forState:UIControlStateNormal];
    [ab setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    ab.titleLabel.font = [UIFont boldSystemFontOfSize:11.0];
    [ab addTarget:[MMTargets shared] action:@selector(onSkinApply)
        forControlEvents:UIControlEventTouchUpInside];
    [g_p_skins addSubview:ab];

    UIButton *db = [UIButton buttonWithType:UIButtonTypeCustom];
    db.frame = CGRectMake(146.0, 220.0, 132.0, 32.0);
    db.backgroundColor = [UIColor colorWithRed:0.10 green:0.28 blue:0.48 alpha:0.95];
    db.layer.cornerRadius = 7.0;
    [db setTitle:@"Dump IDs" forState:UIControlStateNormal];
    [db setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    db.titleLabel.font = [UIFont boldSystemFontOfSize:11.0];
    [db addTarget:[MMTargets shared] action:@selector(onSkinDump)
        forControlEvents:UIControlEventTouchUpInside];
    [g_p_skins addSubview:db];

    g_skin_status = [[UILabel alloc] initWithFrame:CGRectMake(6.0, 258.0, 272.0, 86.0)];
    g_skin_status.numberOfLines = 0;
    g_skin_status.textColor = [UIColor colorWithWhite:0.80 alpha:1.0];
    g_skin_status.font = [UIFont fontWithName:@"Menlo" size:9.5] ?:
                         [UIFont systemFontOfSize:9.5];
    g_skin_status.text = @"hooks 0/3  base -\narma 0  traje 0\ncapturados 0  off\n-";
    [g_p_skins addSubview:g_skin_status];

    mm_skin_sync_ui();
    mm_skin_refresh_status();

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
    /* v0.3.0: el boton queda al 10% (no desaparece) para poder reabrir el
       panel y apagar Stream Mode; la marca de agua se oculta de verdad.
       Cerrar el panel es decision de onSwitch, no de este latido. */
    if (g_btn != nil) {
        g_btn.alpha = on ? 0.10 : 1.0;
        g_btn.userInteractionEnabled = YES;
    }
    if (g_marca != nil) {
        g_marca.alpha = on ? 0.0 : 1.0;
        g_marca.hidden = on;
    }
}

static void mm_position_panel(void)
{
    if (g_panel == nil || g_panel.superview == nil || g_btn == nil) return;
    CGRect rb = g_panel.superview.bounds;
    CGFloat w = MM_PANEL_W, h = MM_PANEL_H;

    /* v0.2.4: si el operador movio el panel, se respeta su posicion */
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"mm_panel_pos"]) {
        CGFloat cx = mm_def_float(@"mm_panel_x", w / 2.0 + 8.0);
        CGFloat cy = mm_def_float(@"mm_panel_y", h / 2.0 + 34.0);
        CGFloat px = cx - w / 2.0;
        CGFloat py = cy - h / 2.0;
        px = MAX(4.0, MIN(rb.size.width  - w - 4.0, px));
        py = MAX(4.0, MIN(rb.size.height - h - 4.0, py));
        g_panel.frame = CGRectMake(px, py, w, h);
        mm_layout_panel_glass();
        return;
    }

    CGPoint c = g_btn.center;
    CGFloat x = c.x - w / 2.0;
    CGFloat y = c.y + 34.0;
    x = MAX(8.0, MIN(rb.size.width - w - 8.0, x));
    if (y + h > rb.size.height - 12.0) y = c.y - h - 34.0;   /* si no cabe abajo, arriba */
    y = MAX(34.0, MIN(rb.size.height - h - 12.0, y));
    g_panel.frame = CGRectMake(x, y, w, h);
    mm_layout_panel_glass();
}

static void mm_set_panel(BOOL open)
{
    @try {
        if (g_panel == nil) return;
        g_panel_open = open;
        if (open) {
            mm_position_panel();
            /* v0.3.1: si iOS purgo las animaciones (background), se reanudan. */
            mm_start_neon_gradient(g_panel_neon);
            mm_start_neon_border(g_panel.layer, mm_neon_green(), mm_neon_purple(), 8.0);
            g_panel.hidden = NO;
            g_panel.alpha = 0.0;
            [UIView animateWithDuration:0.15 animations:^{
                g_panel.alpha = 1.0;
            }];
        } else {
            if (g_skin_weapon_tf != nil) [g_skin_weapon_tf resignFirstResponder];
            if (g_skin_char_tf != nil) [g_skin_char_tf resignFirstResponder];
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
    mm_skin_refresh_status();
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
            @"esp      %@   rango %d m   caja %d   tema %d\n"
            @"render   %@   cajas %d   JUG %d   BOT %d\n"
            @"esp2     %@\n"
            @"probe    %@\n"
            @"skins    %@\n"
            @"skindump %@\n"
            @"nojb     %@\n",
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
            (int)mm_def_float(@"mm_esp_range", 300.0f),
            (int)mm_def_float(@"mm_esp_box_style", 0.0f),
            (int)mm_def_float(@"mm_esp_theme", 0.0f),
            (g_esp != nil && g_esp.superview != nil && !g_esp.hidden) ? @"ON" : @"off",
            g_box_count, g_count_players, g_count_bots,
            (g_esp_diag != nil) ? g_esp_diag : @"-",
            (g_probe_ok == 1) ? @"ok" : (g_probe == nil ? @"pendiente" : @"revisar"),
            mm_skin_resumen(),
            (g_mm_skin_last_dump != nil) ? g_mm_skin_last_dump.lastPathComponent : @"-",
            mm_nojb_resumen()];
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
            g_root.opaque = NO;  /* v0.2.7: capa transparente limpia */
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
        /* v0.2.7: NO re-abrir el panel en cada latido. Antes, con el panel
           abierto, cada latido (0.5 s al principio; 5 s despues) volvia a
           llamar a mm_set_panel(YES), que re-disparaba la animacion de
           entrada desde alpha 0: el menu parecia parpadear. Ahora solo se
           asegura de que siga visible, sin animar de nuevo (si el latido
           recoloco la UI, se reposiciona con la memoria de siempre). */
        if (g_panel_open && g_panel != nil) {
            if (recolocar) mm_position_panel();
            if (g_panel.hidden || g_panel.alpha < 0.95) {
                g_panel.hidden = NO;
                g_panel.alpha = 1.0;
            }
        }

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
    mm_reset_options();   /* v0.2.7: opciones a fabrica en cada arranque */
    NSLog(@"%s dylib cargada v%s  path=%s  pid=%d (opciones reseteadas)",
          MM_TAG, MODMENU_VERSION, mm_my_path(), (int)getpid());
    mm_write_status(@"arranque (opciones a fabrica)");
    mm_nojb_start();      /* v0.2.8: fase C (antidetect) en segundo plano */

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{ mm_tick(); });
}
