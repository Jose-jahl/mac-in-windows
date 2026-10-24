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
 *  v0.3.7 (21 oct) - LICENCIA en FusionCore (migra KeyGate): verifica un token
 *    ES256 (firma r||s -> DER -> Security.framework) guardado en el Keychain,
 *    con HWID = SHA256(identifierForVendor + uuid-keychain + sal). Sin 2a dylib
 *    ni claves plist (mata el vector F-04). ENFORCE en modo OBSERVACION por
 *    defecto (g_lic_enforce=NO): verifica y registra, NO bloquea features, hasta
 *    validar en equipo (leccion anogs). La clave publica embebida es placeholder:
 *    `fusion license pubkey` imprime la de produccion. PENDIENTE device.
 *
 *  v0.3.6 (21 oct) - F-02: trampolin de skins con RELOCACION en runtime.
 *    - fuera los trampolines naked con prologo de 16 B hardcodeado; ahora un
 *      relocador arm64 (mm_reloc_one/mm_build_tramp) copia el prologo REAL y
 *      reubica ADR/ADRP/B/BL/B.cond/CBZ/TBZ/LDR-literal; si una instruccion no
 *      es relocable, el sitio NO se instala (feature off, nunca un salto roto);
 *    - para 1.0.57 (prologos stp/add, PC-independientes) la copia es identica,
 *      asi que el comportamiento no cambia; la ganancia es robustez;
 *    - math validada fuera de linea; PENDIENTE prueba en dispositivo (es hook
 *      runtime). No cambia aim, NoJB, anogs(OFF), ESP ni deteccion.
 *
 *  v0.3.5 (21 oct) - UI LIMPIA: sin diagnostico tecnico en pantalla.
 *    - INFO muestra solo presentacion del mod, funciones y contacto;
 *    - SKINS, MISC y los avisos de guest usan textos claros para el usuario;
 *    - el diagnostico sigue en Documents/modmenu_status.txt y en el syslog,
 *      pero ya no aparece dentro del panel;
 *    - logica de SKINS, aim, NoJB, anogs, ESP y deteccion intacta.
 *
 *  v0.3.4 (20 oct) - QA/PERF: mismo look que v0.3.3.
 *    - el ESP deja de crear NSShadow + 2 NSDictionary por caja y por frame;
 *      ahora prepara colores/atributos una vez por frame y los reutiliza;
 *    - sin cambios visuales, de deteccion ni de logica; baja la presion de
 *      autorelease y el coste de CPU con muchas cajas;
 *    - mismas rutas, toggles, aim, NoJB, SKINS y anogs OFF.
 *
 *  v0.3.3 (20 oct) - PULIDO FINAL DE UI (SOLO UI).
 *    - ESP mas fino y discreto: lineas/cajas hairline con sombra suave,
 *      nombres 10.5, distancia 9.5 centrada y salud de 2.8 px;
 *    - contador JUG/BOT redisenado: capsula glass oscura, borde hairline,
 *      sin gradiente animado ni pulso; etiquetas 9 pt, numeros 13 pt y
 *      separador central; conserva ancho dinamico, safe area y no-toques;
 *    - marca de agua "Made by: Jose Lopez" y pie de INFO con autoria +
 *      Telegram @l0pez9801 tappable (https://t.me/l0pez9801);
 *    - sin tocar aim, NoJB, SKINS ni anogs; sin frameworks nuevos.
 *
 *  v0.3.2 (20 oct) - CONTADOR JUG/BOT GLASS (SOLO UI).
 *    - el contador deja de ser un rectangulo plano pintado en el lienzo: pasa
 *      a una vista UIKit centrada arriba, con blur oscuro, gradiente
 *      verde/morado animado, borde neon y glow, igual que panel y boton;
 *    - ancho dinamico segun el texto, respeta la safe area (notch) y se
 *      recentra al girar; no recibe toques y queda debajo de boton/panel;
 *    - solo se muestra con ESP maestro + Contador ON y se oculta en Stream
 *      Mode; no toca aim, NoJB, ESP, SKINS ni anogs.
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
#import <CommonCrypto/CommonCrypto.h>
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

#define MODMENU_VERSION     "0.4.3"

/* v0.4.3 FIX: el contrato de offsets se incluye TEMPRANO (lo usa el version-gate en
   mm_esp_frame). El header tiene include-guard, asi que el 2do include mas abajo es no-op. */
#include "fusion_offsets.generated.h"
#define MM_TAG              "[MODMENU]"
#define MM_FAST_TRIES       120             /* 120 x 0.5 s = 60 s rapidos  */
#define MM_FAST_LOG_EVERY   20              /* log de espera cada 10 s     */
#define MM_SLOW_SECS        5               /* luego un latido cada 5 s    */
#define MM_PANEL_W          300.0
#define MM_PANEL_H          430.0
#define MM_COUNT_H          30.0
#define MM_COUNT_MIN_W      132.0
#define MM_COUNT_PAD_X      16.0

/* v0.2.5: la posicion del pawn proyecta a la altura del cuello/cabeza. La
   caja se completa con dos puntos del mundo para cubrir el cuerpo entero:
   +0.25 m hasta la coronilla y -1.52 m hasta los pies (1.77 m de alto). */
#define MM_BOX_TOP_UP       0.25f
#define MM_BOX_FEET_DN      1.52f

/* Marcador global: el CI lo verifica para confirmar que este fuente llego al
   binario (el constructor es static y no sirve como prueba de presencia). */
const char *modmenu_build_id = "modmenu-glass-0.4.3";

/* --- objetos de UI (globales, creados una sola vez) --- */
static UIView   *g_root  = nil;   /* capa transparente sobre la ventana juego */
static UIButton *g_btn   = nil;   /* boton flotante                           */
static UIView   *g_panel = nil;   /* panel desplegable                        */
static CAGradientLayer *g_panel_neon = nil; /* v0.3.1: fondo glass neon       */
static UIVisualEffectView *g_panel_blur = nil;
static UIView   *g_panel_shade = nil;
static CAGradientLayer *g_btn_neon = nil;   /* v0.3.1: boton glass neon       */
static UIView   *g_count_glass = nil; /* v0.3.2: contador JUG/BOT glass   */
static UIVisualEffectView *g_count_blur = nil;
static UIView   *g_count_shade = nil;
static CAGradientLayer *g_count_neon = nil;
static UILabel  *g_count_label = nil;
static int       g_count_last_players = -1;
static int       g_count_last_bots = -1;
static UISegmentedControl *g_seg = nil;
static UILabel  *g_marca  = nil;  /* marca de agua v0.2.4 (identidad) */
static UIView   *g_p_esp  = nil;
static UIView   *g_p_vis  = nil;  /* v0.3.0: Stream Mode + pulido ESP */
static UIView   *g_p_misc = nil;
static UIView   *g_p_info = nil;
static UIView   *g_p_more = nil;  /* v0.4.0: pagina EXTRA (features nuevas)    */
static UILabel  *g_info   = nil;  /* texto vivo de la pagina INFO             */
static UILabel  *g_range_val = nil;
static NSMutableArray *g_sub_switches = nil;  /* switches bajo el maestro    */

static const char *g_via   = "-";     /* donde quedo colgada la UI        */
static BOOL  g_panel_open  = NO;
static BOOL  g_panic       = NO;  /* v0.4.0 #8: kill-switch (long-press boton)  */
static int   g_profile_slot = 0;  /* v0.4.0 #7: slot de perfil seleccionado     */
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
static void mm_profile_save(int slot);   /* v0.4.0 #7: perfiles de config */
static BOOL mm_profile_load(int slot);
static void mm_esp_collect_real(void);
static void mm_probe_run(void);
static void mm_layout_count_glass(void);
static void mm_refresh_count_glass(void);

/* v0.2.9: fase D (guest reset) */
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

/* v0.3.2: al girar/cambiar de tamano, la vista raiz vuelve a centrar el
   contador y recalcula su safe area sin esperar al siguiente latido. */
- (void)layoutSubviews
{
    [super layoutSubviews];
    mm_layout_count_glass();
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
    CGFloat len = MIN(12.0, MIN(r.size.width, r.size.height) * 0.28);
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

/*---------------------------------------------------------------------------
 * Lienzo del ESP (v0.2.2): pinta las cajas ENCIMA del juego pero DEBAJO del
 * boton y del panel (va el primero dentro de la capa). No recibe toques.
 *--------------------------------------------------------------------------*/
/* v0.4.0: FPS del lienzo (lo actualiza mm_esp_frame a partir del timestamp). */
static double g_fps = 0.0;

/* fwd: el acento del tema se define mas abajo, pero drawRect/helpers lo usan aqui. */
static UIColor *mm_neon_green(void);
static UIColor *mm_neon_purple(void);

/* v0.4.0 (#1 crosshair) + v0.4.2 estilos: 0 cruz+punto · 1 punto · 2 circulo+punto · 3 todo. */
static void mm_draw_crosshair(CGContextRef ctx, CGRect bs, int style, CGFloat cr, CGFloat cg, CGFloat cb)
{
    CGFloat cx = bs.size.width / 2.0, cy = bs.size.height / 2.0;
    CGFloat gap = 4.0, len = 9.0;
    if (style != 1) {
        for (int pass = 0; pass < 2; pass++) {
            if (pass == 0) { CGContextSetLineWidth(ctx, 2.6); CGContextSetRGBStrokeColor(ctx, 0.0, 0.0, 0.0, 0.5); }
            else           { CGContextSetLineWidth(ctx, 1.2); CGContextSetRGBStrokeColor(ctx, cr, cg, cb, 0.95); }
            CGContextMoveToPoint(ctx, cx - gap - len, cy); CGContextAddLineToPoint(ctx, cx - gap, cy);
            CGContextMoveToPoint(ctx, cx + gap, cy);       CGContextAddLineToPoint(ctx, cx + gap + len, cy);
            CGContextMoveToPoint(ctx, cx, cy - gap - len);  CGContextAddLineToPoint(ctx, cx, cy - gap);
            CGContextMoveToPoint(ctx, cx, cy + gap);        CGContextAddLineToPoint(ctx, cx, cy + gap + len);
            CGContextStrokePath(ctx);
        }
    }
    if (style == 2 || style == 3) {
        CGFloat rad = 7.0;
        CGContextSetLineWidth(ctx, 1.4);
        CGContextSetRGBStrokeColor(ctx, cr, cg, cb, 0.9);
        CGContextStrokeEllipseInRect(ctx, CGRectMake(cx - rad, cy - rad, rad * 2.0, rad * 2.0));
    }
    CGContextSetRGBFillColor(ctx, cr, cg, cb, 0.95);
    CGContextFillRect(ctx, CGRectMake(cx - 1.0, cy - 1.0, 2.0, 2.0));
}

/* v0.4.0 (#6 aim ring): anillo proporcional que marca la zona de aim-assist
   (el aim es parche estatico; esto es SOLO un indicador visual, no apunta). */
static void mm_draw_aimring(CGContextRef ctx, CGRect bs, CGFloat cr, CGFloat cg, CGFloat cb)
{
    CGFloat cx = bs.size.width / 2.0, cy = bs.size.height / 2.0;
    CGFloat radio = bs.size.width * 0.14;
    CGContextSetLineWidth(ctx, 1.4);
    CGContextSetRGBStrokeColor(ctx, cr, cg, cb, 0.55);
    CGContextStrokeEllipseInRect(ctx, CGRectMake(cx - radio, cy - radio, radio * 2.0, radio * 2.0));
}

/* v0.4.0 (#2 FPS): medidor del overlay, arriba-izquierda (respeta notch). */
static void mm_draw_fps(CGRect bs)
{
    (void)bs;
    NSString *s = [NSString stringWithFormat:@"%d FPS", (int)(g_fps + 0.5)];
    UIFont *f = [UIFont monospacedDigitSystemFontOfSize:10.0 weight:UIFontWeightSemibold];
    if (f == nil) f = [UIFont boldSystemFontOfSize:10.0];
    NSShadow *sh = [[NSShadow alloc] init];
    sh.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.8];
    sh.shadowBlurRadius = 2.0; sh.shadowOffset = CGSizeMake(0.0, 1.0);
    NSDictionary *a = @{ NSFontAttributeName: f,
        NSForegroundColorAttributeName: [UIColor colorWithWhite:0.92 alpha:1.0],
        NSShadowAttributeName: sh };
    [s drawAtPoint:CGPointMake(10.0, 44.0) withAttributes:a];
}

/* v0.4.2: flecha en el borde apuntando a un objetivo fuera de pantalla. */
static void mm_draw_edge_arrow(CGContextRef ctx, CGRect bs, CGFloat tx, CGFloat ty,
                               CGFloat cr, CGFloat cg, CGFloat cb)
{
    CGFloat cx = bs.size.width / 2.0, cy = bs.size.height / 2.0;
    CGFloat dx = tx - cx, dy = ty - cy;
    CGFloat len = (CGFloat)sqrt(dx * dx + dy * dy);
    if (len < 1.0) return;
    dx /= len; dy /= len;
    CGFloat R = (MIN(bs.size.width, bs.size.height) / 2.0) - 26.0;
    CGFloat px = cx + dx * R, py = cy + dy * R;
    CGFloat a = 9.0, nx = -dy, ny = dx;
    CGContextSetRGBFillColor(ctx, cr, cg, cb, 0.9);
    CGContextMoveToPoint(ctx, px + dx * a, py + dy * a);
    CGContextAddLineToPoint(ctx, px - dx * a + nx * a * 0.7, py - dy * a + ny * a * 0.7);
    CGContextAddLineToPoint(ctx, px - dx * a - nx * a * 0.7, py - dy * a - ny * a * 0.7);
    CGContextClosePath(ctx);
    CGContextFillPath(ctx);
}

/* v0.4.2: borde rojo pulsante cuando hay un enemigo muy cerca. */
static void mm_draw_warn(CGContextRef ctx, CGRect bs)
{
    double t = CACurrentMediaTime();
    CGFloat a = 0.28 + 0.30 * (0.5 + 0.5 * (CGFloat)sin(t * 6.0));
    CGContextSetLineWidth(ctx, 6.0);
    CGContextSetRGBStrokeColor(ctx, 1.0, 0.18, 0.24, a);
    CGContextStrokeRect(ctx, CGRectMake(3.0, 3.0, bs.size.width - 6.0, bs.size.height - 6.0));
}

@interface MMCanvasView : UIView @end

@implementation MMCanvasView
- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (ctx == NULL) return;

    CGRect bs = self.bounds;
    UIFont *fNombre = [UIFont systemFontOfSize:10.5 weight:UIFontWeightSemibold];
    if (fNombre == nil) fNombre = [UIFont boldSystemFontOfSize:10.5];
    UIFont *fDist = [UIFont monospacedDigitSystemFontOfSize:9.5
                                                   weight:UIFontWeightMedium];
    if (fDist == nil) fDist = [UIFont systemFontOfSize:9.5];

    BOOL conCajas  = mm_def_bool(@"mm_esp_box", NO);          /* v0.2.5 */
    BOOL conNombre = mm_def_bool(@"mm_esp_name", NO);
    BOOL conDist   = mm_def_bool(@"mm_esp_dist", NO);
    BOOL conLineas = mm_def_bool(@"mm_esp_lines", NO);
    BOOL lineasTop = mm_def_bool(@"mm_esp_lines_top", NO);    /* v0.2.5 */
    BOOL conSalud  = mm_def_bool(@"mm_esp_health", NO);
    BOOL conRelleno = mm_def_bool(@"mm_esp_fill", NO);
    int  estiloCaja = (int)mm_def_float(@"mm_esp_box_style", 0.0f);
    int  tema       = (int)mm_def_float(@"mm_esp_theme", 0.0f);
    if (estiloCaja != 1) estiloCaja = 0;
    if (tema < 0 || tema > 2) tema = 0;

    /* v0.4.0: features de overlay. Las independientes de las cajas (crosshair,
       anillo de aim, FPS) se dibujan aunque no haya pawns; las por-pawn
       (head dot, color por distancia, vida baja) se leen aca y se usan abajo. */
    BOOL conCross   = mm_def_bool(@"mm_x_cross", NO);
    BOOL conAimRing = mm_def_bool(@"mm_x_aimring", NO);
    BOOL conFps     = mm_def_bool(@"mm_x_fps", NO);
    BOOL conHead    = mm_def_bool(@"mm_x_head", NO);
    BOOL conDistCol = mm_def_bool(@"mm_x_distcol", NO);
    BOOL conLowHp   = mm_def_bool(@"mm_x_lowhp", NO);
    CGFloat ar = 0.2, ag = 1.0, ab = 0.58, aalpha = 1.0;
    [mm_neon_green() getRed:&ar green:&ag blue:&ab alpha:&aalpha];

    /* v0.4.2: features nuevas de solo-lectura (reusan g_boxes). */
    BOOL conHpNum    = mm_def_bool(@"mm_x_hpnum", NO);
    BOOL conPriority = mm_def_bool(@"mm_x_priority", NO);
    BOOL conWarn     = mm_def_bool(@"mm_x_warn", NO);
    BOOL conArrow    = mm_def_bool(@"mm_x_arrow", NO);
    int  crossStyle  = (int)mm_def_float(@"mm_x_cross_style", 0.0f);
    if (crossStyle < 0 || crossStyle > 3) crossStyle = 0;
    int  maxN        = (int)mm_def_float(@"mm_x_maxn", 0.0f);
    if (maxN < 0) maxN = 0; if (maxN > MM_MAX_BOXES) maxN = MM_MAX_BOXES;

    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextSetLineJoin(ctx, kCGLineJoinRound);

    if (conAimRing) mm_draw_aimring(ctx, bs, ar, ag, ab);
    if (conCross)   mm_draw_crosshair(ctx, bs, crossStyle, ar, ag, ab);
    if (conFps)     mm_draw_fps(bs);

    if (g_box_count <= 0) return;

    /* v0.4.2: pre-pass — objetivo prioritario (mas cercano vivo) y umbral closest-N. */
    int priIdx = -1; float priDist = 1e9f; float distThresh = 1e9f;
    for (int i = 0; i < g_box_count && i < MM_MAX_BOXES; i++) {
        if (!g_boxes[i].alive || g_boxes[i].dist <= 0.0f) continue;
        if (g_boxes[i].dist < priDist) { priDist = g_boxes[i].dist; priIdx = i; }
    }
    if (maxN > 0 && maxN < g_box_count) {
        float ds[MM_MAX_BOXES]; int n = 0;
        for (int i = 0; i < g_box_count && i < MM_MAX_BOXES; i++)
            if (g_boxes[i].alive && g_boxes[i].dist > 0.0f) ds[n++] = g_boxes[i].dist;
        for (int a2 = 1; a2 < n; a2++) { float k = ds[a2]; int b2 = a2 - 1;
            while (b2 >= 0 && ds[b2] > k) { ds[b2 + 1] = ds[b2]; b2--; } ds[b2 + 1] = k; }
        if (maxN - 1 >= 0 && maxN - 1 < n) distThresh = ds[maxN - 1];
    }

    /* v0.3.4: colores y atributos de texto se preparan UNA vez por frame.
       Antes se creaba un NSShadow + dos NSDictionary por cada caja a 30 fps;
       con muchas cajas eso generaba presion de autorelease innecesaria. */
    CGFloat crJug = 1.00, cgJug = 0.25, cbJug = 0.25;
    CGFloat crBot = 1.00, cgBot = 0.25, cbBot = 0.25;
    mm_esp_color(0, tema, &crJug, &cgJug, &cbJug);
    mm_esp_color(1, tema, &crBot, &cgBot, &cbBot);

    NSShadow *txtShadow = [[NSShadow alloc] init];
    txtShadow.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.82];
    txtShadow.shadowBlurRadius = 2.0;
    txtShadow.shadowOffset = CGSizeMake(0.0, 1.0);

    NSDictionary *nameJug = @{ NSFontAttributeName: fNombre,
        NSForegroundColorAttributeName:
            [UIColor colorWithRed:crJug green:cgJug blue:cbJug alpha:0.96],
        NSShadowAttributeName: txtShadow };
    NSDictionary *nameBot = @{ NSFontAttributeName: fNombre,
        NSForegroundColorAttributeName:
            [UIColor colorWithRed:crBot green:cgBot blue:cbBot alpha:0.96],
        NSShadowAttributeName: txtShadow };
    NSDictionary *distJug = @{ NSFontAttributeName: fDist,
        NSForegroundColorAttributeName:
            [UIColor colorWithRed:crJug green:cgJug blue:cbJug alpha:0.90],
        NSShadowAttributeName: txtShadow };
    NSDictionary *distBot = @{ NSFontAttributeName: fDist,
        NSForegroundColorAttributeName:
            [UIColor colorWithRed:crBot green:cgBot blue:cbBot alpha:0.90],
        NSShadowAttributeName: txtShadow };

    for (int i = 0; i < g_box_count && i < MM_MAX_BOXES; i++) {
        MMEspBox *b = &g_boxes[i];
        if (!b->alive) continue;
        if (maxN > 0 && b->dist > distThresh + 0.01f) continue;   /* v0.4.2: closest-N */
        CGRect r = CGRectMake(b->x, b->y, b->w, b->h);

        CGFloat cr = b->robot ? crBot : crJug;
        CGFloat cg = b->robot ? cgBot : cgJug;
        CGFloat cb = b->robot ? cbBot : cbJug;

        /* v0.4.0 (#4 color por distancia): atenua y vira a frio al alejarse. */
        if (conDistCol && b->dist > 0.5f) {
            float rng = mm_def_float(@"mm_esp_range", 300.0f);
            if (rng < 40.0f) rng = 40.0f;
            float f = b->dist / rng; if (f < 0.0f) f = 0.0f; if (f > 1.0f) f = 1.0f;
            cr = cr * (1.0f - 0.65f * f);
            cg = cg * (1.0f - 0.35f * f);
            cb = cb + (0.85f - cb) * 0.6f * f;
        }
        /* v0.4.0 (#5 vida baja): resalta en ambar a los de poca vida (<30%). */
        if (conLowHp && b->hp >= 0.0f && b->hpMax > 1.0f && (b->hp / b->hpMax) < 0.30f) {
            cr = 1.0f; cg = 0.78f; cb = 0.12f;
        }

        if (conLineas) {
            /* v0.2.5: origen elegible. OFF = borde inferior -> pies de la caja;
               ON = borde superior -> cabeza de la caja. */
            CGPoint desde = CGPointMake(bs.size.width / 2.0,
                                        lineasTop ? 0.0 : bs.size.height);
            CGPoint hasta = CGPointMake(CGRectGetMidX(r),
                                        lineasTop ? CGRectGetMinY(r)
                                                  : CGRectGetMaxY(r));
            /* v0.3.3: hairline con sombra suave, no trazo grueso. */
            CGContextSetLineWidth(ctx, 2.4);
            CGContextSetRGBStrokeColor(ctx, 0.0, 0.0, 0.0, 0.34);
            CGContextMoveToPoint(ctx, desde.x, desde.y);
            CGContextAddLineToPoint(ctx, hasta.x, hasta.y);
            CGContextStrokePath(ctx);
            CGContextSetLineWidth(ctx, 1.0);
            CGContextSetRGBStrokeColor(ctx, cr, cg, cb, 0.80);
            CGContextMoveToPoint(ctx, desde.x, desde.y);
            CGContextAddLineToPoint(ctx, hasta.x, hasta.y);
            CGContextStrokePath(ctx);
        }

        /* v0.2.5: TODO lo que cuelga de la caja respeta el toggle "Cajas".
           Antes se dibujaba siempre (el switch parecia no responder). Los
           nombres y la distancia quedan fuera: son toggles independientes. */
        if (conCajas) {
            if (conRelleno) {
                CGContextSetRGBFillColor(ctx, cr, cg, cb, 0.06);
                CGContextFillRect(ctx, r);
            }
            /* v0.3.3: borde completo o solo esquinas, hairline + sombra. */
            CGContextSetLineWidth(ctx, 2.0);
            CGContextSetRGBStrokeColor(ctx, 0.0, 0.0, 0.0, 0.38);
            mm_esp_box_path(ctx, r, estiloCaja);
            CGContextStrokePath(ctx);
            CGContextSetLineWidth(ctx, 0.9);
            CGContextSetRGBStrokeColor(ctx, cr, cg, cb, 0.84);
            mm_esp_box_path(ctx, r, estiloCaja);
            CGContextStrokePath(ctx);
        }

        /* v0.4.0 (#3 head dot): punto en la cabeza (borde superior central). */
        if (conHead) {
            CGFloat hx = CGRectGetMidX(r), hy = r.origin.y;
            CGContextSetRGBFillColor(ctx, 0.0, 0.0, 0.0, 0.5);
            CGContextFillEllipseInRect(ctx, CGRectMake(hx - 3.0, hy - 3.0, 6.0, 6.0));
            CGContextSetRGBFillColor(ctx, cr, cg, cb, 0.98);
            CGContextFillEllipseInRect(ctx, CGRectMake(hx - 2.2, hy - 2.2, 4.4, 4.4));
        }

        /* v0.4.2 (prioridad): resalta en cian el objetivo mas cercano. */
        if (conPriority && i == priIdx) {
            CGRect hr = CGRectInset(r, -3.0, -3.0);
            CGContextSetLineWidth(ctx, 2.2);
            CGContextSetRGBStrokeColor(ctx, 0.20, 0.95, 1.0, 0.95);
            CGContextStrokeRect(ctx, hr);
        }
        /* v0.4.2 (vida numerica): HP sobre la caja, arriba-derecha. */
        if (conHpNum && b->hp >= 0.0f && b->hpMax > 1.0f) {
            NSString *hs = [NSString stringWithFormat:@"%d", (int)(b->hp + 0.5f)];
            NSDictionary *ha = @{ NSFontAttributeName: fDist,
                NSForegroundColorAttributeName: [UIColor colorWithRed:cr green:cg blue:cb alpha:0.96],
                NSShadowAttributeName: txtShadow };
            [hs drawAtPoint:CGPointMake(CGRectGetMaxX(r) + 2.0, r.origin.y - 1.0) withAttributes:ha];
        }
        /* v0.4.2 (flecha off-screen): si la caja cae fuera de pantalla, flecha al borde. */
        if (conArrow) {
            CGFloat mx = CGRectGetMidX(r), my = CGRectGetMidY(r);
            if (mx < 0.0 || mx > bs.size.width || my < 0.0 || my > bs.size.height)
                mm_draw_edge_arrow(ctx, bs, mx, my, cr, cg, cb);
        }

        /* v0.2.6: barra de salud INDEPENDIENTE del toggle "Cajas" (en la
           0.2.5 yo la habia ligado a el y con Cajas OFF desaparecia; el
           test la reporto como "no se ve"). Manda solo el toggle "Salud".
           v0.3.3: 2.8 px, marco fino y colores mas sobrios; se dibuja
           tambien con vida 0 (se ve el fondo) a la izquierda de la caja. */
        if (conSalud && b->hp >= 0.0f && b->hpMax > 1.0f) {
            float fr = b->hp / b->hpMax;
            if (fr < 0.0f) fr = 0.0f;
            if (fr > 1.0f) fr = 1.0f;
            CGFloat bwv = 2.8;
            CGFloat bx  = r.origin.x - 6.0;
            if (bx < 2.0) bx = 2.0;
            CGFloat by  = r.origin.y;
            CGFloat bhh = r.size.height;
            if (bhh < 8.0) bhh = 8.0;  /* minimo para que se vea de lejos */
            /* marco negro fino */
            CGContextSetRGBFillColor(ctx, 0.0, 0.0, 0.0, 0.62);
            CGContextFillRect(ctx, CGRectMake(bx - 1.0, by - 1.0,
                                              bwv + 2.0, bhh + 2.0));
            /* fondo oscuro (se ve aunque la vida este en 0) */
            CGContextSetRGBFillColor(ctx, 0.05, 0.08, 0.06, 0.82);
            CGContextFillRect(ctx, CGRectMake(bx, by, bwv, bhh));
            /* relleno segun la vida */
            CGFloat rr2 = 1.00, gg2 = 0.30, bb2 = 0.32;
            if (fr > 0.5f)       { rr2 = 0.30; gg2 = 0.95; bb2 = 0.48; }
            else if (fr > 0.25f) { rr2 = 1.00; gg2 = 0.72; bb2 = 0.26; }
            CGFloat fh2 = bhh * fr;
            if (fh2 > 0.0f) {
                CGContextSetRGBFillColor(ctx, rr2, gg2, bb2, 0.92);
                CGContextFillRect(ctx, CGRectMake(bx, by + bhh - fh2,
                                                  bwv, fh2));
            }
        }

        NSDictionary *attr = b->robot ? nameBot : nameJug;
        if (conNombre) {
            NSString *nm = nil;
            if (b->hasName) nm = [NSString stringWithUTF8String:b->name];
            if (nm == nil || nm.length == 0)
                nm = (b->robot ? @"BOT" : @"JUGADOR");
            CGSize ns = [nm sizeWithAttributes:attr];
            CGFloat nx = CGRectGetMidX(r) - ns.width / 2.0;
            nx = MAX(2.0, MIN(bs.size.width - ns.width - 2.0, nx));
            CGFloat ny = r.origin.y - ns.height - 1.0;
            if (ny < 0.0) ny = 0.0;
            [nm drawAtPoint:CGPointMake(nx, ny) withAttributes:attr];
        }
        if (conDist && b->dist > 0.5f) {
            NSDictionary *dattr = b->robot ? distBot : distJug;
            NSString *ds = [NSString stringWithFormat:@"%d m",
                            (int)(b->dist + 0.5f)];
            CGSize dsz = [ds sizeWithAttributes:dattr];
            CGFloat dx = CGRectGetMidX(r) - dsz.width / 2.0;
            dx = MAX(2.0, MIN(bs.size.width - dsz.width - 2.0, dx));
            CGFloat dy = CGRectGetMaxY(r) + 2.0;
            if (dy + dsz.height > bs.size.height - 2.0)
                dy = MAX(0.0, r.origin.y - dsz.height - 1.0);
            [ds drawAtPoint:CGPointMake(dx, dy) withAttributes:dattr];
        }
    }

    /* v0.4.2 (aviso de enemigo cercano): borde rojo pulsante si el mas cercano < 30 m. */
    if (conWarn && priIdx >= 0 && priDist < 30.0f) mm_draw_warn(ctx, bs);
}
@end

/*---------------------------------------------------------------------------
 * Callbacks de la UI (un singleton para target/action).
 *--------------------------------------------------------------------------*/
@interface MMTargets : NSObject
+ (MMTargets *)shared;
- (void)onFrame:(CADisplayLink *)link;
- (void)onPanelPan:(UIPanGestureRecognizer *)g;
- (void)onTelegram;
- (void)onBoxStyle:(UISegmentedControl *)s;
- (void)onTheme:(UISegmentedControl *)s;
- (void)onThemeAccent:(UISegmentedControl *)s;
- (void)onMenuOpacity:(UISlider *)s;
- (void)onMenuScale:(UISlider *)s;
- (void)onCrossStyle:(UISegmentedControl *)s;
- (void)onMaxN:(UISlider *)s;
- (void)onPanic:(UILongPressGestureRecognizer *)g;
- (void)onProfileSlot:(UISegmentedControl *)s;
- (void)onProfileSave;
- (void)onProfileLoad;
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

/* v0.3.3: contacto de Telegram desde INFO. URL publica, sin APIs privadas. */
- (void)onTelegram
{
    @try {
        NSURL *u = [NSURL URLWithString:@"https://t.me/l0pez9801"];
        if (u == nil) return;
        [[UIApplication sharedApplication] openURL:u options:@{} completionHandler:nil];
    } @catch (NSException *e) {
        NSLog(@"%s telegram: %@", MM_TAG, e.reason);
    }
}

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
    if (g_p_esp   != nil) g_p_esp.hidden   = (i != 0);
    if (g_p_vis   != nil) g_p_vis.hidden   = (i != 1);
    if (g_p_misc  != nil) g_p_misc.hidden  = (i != 2);
    if (g_p_more  != nil) g_p_more.hidden  = (i != 3);
    if (g_p_info  != nil) g_p_info.hidden  = (i != 4);
}

- (void)onSwitch:(UISwitch *)s
{
    NSString *k = s.accessibilityIdentifier;
    if (k.length == 0) return;
    [[NSUserDefaults standardUserDefaults] setBool:s.on forKey:k];
    if ([k isEqualToString:@"mm_esp_master"]) mm_apply_esp_lock();
    if ([k isEqualToString:@"mm_esp_count"]) mm_refresh_count_glass();
    if ([k isEqualToString:@"mm_stream"]) {
        mm_apply_stream();
        /* Al activarlo desde VIS se cierra el panel para dejar limpia la
           grabacion; al reabrirlo con el boton atenuado ya no se vuelve a
           cerrar solo (v0.3.0). */
        if (s.on) mm_set_panel(NO);
    }
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

/* v0.4.0 #10: acento del menu. Re-skina en vivo lo barato (borde/sombra); el
   gradiente y el resto se re-skinan al reabrir, y el overlay se repinta solo. */
- (void)onThemeAccent:(UISegmentedControl *)s
{
    [[NSUserDefaults standardUserDefaults] setInteger:s.selectedSegmentIndex
                                               forKey:@"mm_theme_accent"];
    if (g_panel != nil) {
        g_panel.layer.borderColor = [mm_neon_green() colorWithAlphaComponent:0.78].CGColor;
        g_panel.layer.shadowColor = [mm_neon_purple() colorWithAlphaComponent:0.90].CGColor;
    }
    if (g_esp != nil) [g_esp setNeedsDisplay];
    mm_write_status(@"tema menu");
}

/* v0.4.0 #11: opacidad y escala del menu, aplicadas en vivo. */
- (void)onMenuOpacity:(UISlider *)s
{
    [[NSUserDefaults standardUserDefaults] setFloat:s.value forKey:@"mm_menu_opacity"];
    if (g_panel != nil && !g_panel.hidden) g_panel.alpha = s.value;
}

- (void)onMenuScale:(UISlider *)s
{
    [[NSUserDefaults standardUserDefaults] setFloat:s.value forKey:@"mm_menu_scale"];
    if (g_panel != nil && !g_panel.hidden)
        g_panel.transform = CGAffineTransformMakeScale(s.value, s.value);
}

/* v0.4.2: estilo de crosshair + limite de objetivos (el lienzo los lee en vivo). */
- (void)onCrossStyle:(UISegmentedControl *)s
{
    [[NSUserDefaults standardUserDefaults] setFloat:(float)s.selectedSegmentIndex
                                             forKey:@"mm_x_cross_style"];
    mm_write_status(@"crosshair style");
}
- (void)onMaxN:(UISlider *)s
{
    [[NSUserDefaults standardUserDefaults] setFloat:(float)(int)(s.value + 0.5f)
                                             forKey:@"mm_x_maxn"];
}

/* v0.4.0 #8: kill-switch. Long-press en el boton -> oculta TODO al instante;
   otro long-press restaura. El modo panico se respeta en mm_esp_frame. */
- (void)onPanic:(UILongPressGestureRecognizer *)g
{
    if (g.state != UIGestureRecognizerStateBegan) return;
    g_panic = !g_panic;
    if (g_panic) {
        mm_set_panel(NO);
        if (g_esp != nil) g_esp.hidden = YES;
        if (g_count_glass != nil) g_count_glass.hidden = YES;
        if (g_marca != nil) g_marca.hidden = YES;
    } else {
        if (g_marca != nil) g_marca.hidden = NO;
        mm_refresh_count_glass();
    }
    mm_write_status(g_panic ? @"panic ON" : @"panic OFF");
}

/* v0.4.0 #7: perfiles de config (3 slots). */
- (void)onProfileSlot:(UISegmentedControl *)s { g_profile_slot = (int)s.selectedSegmentIndex; }
- (void)onProfileSave
{
    mm_profile_save(g_profile_slot);
    mm_show_alert(@"Perfiles",
                  [NSString stringWithFormat:@"Configuracion guardada en P%d.", g_profile_slot + 1]);
}
- (void)onProfileLoad
{
    if (mm_profile_load(g_profile_slot)) {
        mm_write_status(@"perfil cargado");
        mm_show_alert(@"Perfiles",
                      [NSString stringWithFormat:@"P%d cargado y aplicado.", g_profile_slot + 1]);
    } else {
        mm_show_alert(@"Perfiles",
                      [NSString stringWithFormat:@"P%d esta vacio. Guardalo primero.", g_profile_slot + 1]);
    }
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
                           @"mm_x_cross", @"mm_x_aimring", @"mm_x_fps",
                           @"mm_x_head", @"mm_x_distcol", @"mm_x_lowhp",
                           @"mm_x_hpnum", @"mm_x_priority", @"mm_x_warn",
                           @"mm_x_arrow", @"mm_x_cross_style", @"mm_x_maxn" ];
        for (NSString *k in keys) [ud removeObjectForKey:k];
        [ud synchronize];
    } @catch (NSException *e) {
        NSLog(@"[MODMENU] reset de opciones: %@", e.reason);
    }
}

/* v0.4.0 #7: perfiles de config. Snapshot/restore de las claves de opciones a
   un slot en NSUserDefaults. Al cargar, sincroniza las palancas visibles y
   repinta el overlay (que de todos modos lee las claves en vivo). */
static NSArray *mm_profile_keys(void)
{
    return @[ @"mm_esp_master", @"mm_esp_box", @"mm_esp_players", @"mm_esp_bots",
              @"mm_esp_name", @"mm_esp_dist", @"mm_esp_health", @"mm_esp_lines",
              @"mm_esp_lines_top", @"mm_esp_fill", @"mm_esp_range", @"mm_stream",
              @"mm_esp_count", @"mm_esp_box_style", @"mm_esp_theme",
              @"mm_x_cross", @"mm_x_aimring", @"mm_x_head", @"mm_x_distcol",
              @"mm_x_lowhp", @"mm_x_fps", @"mm_theme_accent",
              @"mm_menu_opacity", @"mm_menu_scale",
              @"mm_x_hpnum", @"mm_x_priority", @"mm_x_warn", @"mm_x_arrow",
              @"mm_x_cross_style", @"mm_x_maxn" ];   /* 0.4: perfiles completos (v0.4.2) */
}

static void mm_profile_save(int slot)
{
    @try {
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        NSMutableDictionary *d = [NSMutableDictionary dictionary];
        for (NSString *k in mm_profile_keys()) {
            id v = [ud objectForKey:k];
            if (v != nil) d[k] = v;
        }
        [ud setObject:d forKey:[NSString stringWithFormat:@"mm_profile_%d", slot]];
        [ud synchronize];
    } @catch (NSException *e) {
        NSLog(@"%s perfil guardar: %@", MM_TAG, e.reason);
    }
}

static void mm_sync_switches(UIView *root)
{
    if (root == nil) return;
    for (UIView *v in root.subviews) {
        if ([v isKindOfClass:[UISwitch class]]) {
            UISwitch *sw = (UISwitch *)v;
            NSString *k = sw.accessibilityIdentifier;
            if (sw.enabled && k.length && [k hasPrefix:@"mm_"]) sw.on = mm_def_bool(k, sw.on);
        } else {
            mm_sync_switches(v);
        }
    }
}

static BOOL mm_profile_load(int slot)
{
    @try {
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        NSDictionary *d = [ud dictionaryForKey:[NSString stringWithFormat:@"mm_profile_%d", slot]];
        if (d == nil) return NO;
        for (NSString *k in mm_profile_keys()) {
            id v = d[k];
            if (v != nil) [ud setObject:v forKey:k];
        }
        [ud synchronize];
        if (g_panel != nil) mm_sync_switches(g_panel);
        if (g_esp != nil) [g_esp setNeedsDisplay];
        return YES;
    } @catch (NSException *e) {
        NSLog(@"%s perfil cargar: %@", MM_TAG, e.reason);
        return NO;
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
        /* v0.4.3 (0.1): version gate — no leer offsets de 1.0.57 contra otra version del juego. */
        static int g_ver_ok = -1;
        if (g_ver_ok < 0) {
            NSString *gv = NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"];
            g_ver_ok = (gv != nil && [gv isEqualToString:@FUSION_OFFSETS_VERSION]) ? 1 : 0;
            if (!g_ver_ok) NSLog(@"%s version gate: juego %@ != offsets %s -> ESP OFF",
                                 MM_TAG, gv, FUSION_OFFSETS_VERSION);
        }
        if (!g_ver_ok) { if (!g_esp.hidden) g_esp.hidden = YES; return; }
        if (g_panic) {                 /* v0.4.0 #8: todo oculto en modo panico */
            if (!g_esp.hidden) g_esp.hidden = YES;
            return;
        }
        if (!mm_def_bool(@"mm_esp_master", NO)) {
            if (g_box_count != 0) {
                g_box_count = 0;
                [g_esp setNeedsDisplay];
            }
            if (!g_esp.hidden) g_esp.hidden = YES;
            mm_refresh_count_glass();
            return;
        }
        if (g_esp.hidden) g_esp.hidden = NO;

        /* v0.4.0 (#2 FPS): media exponencial del ritmo real del lienzo. */
        static double s_lastT = 0.0;
        if (s_lastT > 0.0 && t > s_lastT) {
            double inst = 1.0 / (t - s_lastT);
            g_fps = (g_fps > 0.0) ? (g_fps * 0.9 + inst * 0.1) : inst;
        }
        s_lastT = t;

        static int s_tick = 0;              /* datos ~15 Hz, pintado a 30 fps */
        if ((s_tick++ & 1) == 0) {
            mm_esp_collect_real();
            mm_refresh_count_glass();       /* v0.3.2: contador glass */
        }
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

/* ---------------------------------------------------------------------------
 *  VAs y offsets del juego: CONTRATO DATA-DRIVEN (v0.4.0).
 *  Antes vivian como #define sueltos aqui (v<=0.3.7). Ahora se generan con
 *      fusion offsets <ver> --emit
 *  desde corpus/<ver>/offsets.json y el CI compila la dylib con este header.
 *  En un update: `fusion resolve --write` re-localiza las VAs -> `fusion offsets
 *  --emit --from-resolved` regenera el header -> CI recompila. Las direcciones
 *  (datos, versionadas) se separan de la logica (codigo, estable).
 *  Los offsets de struct van pinned por version y se validan en runtime.
 * ------------------------------------------------------------------------- */
#include "fusion_offsets.generated.h"

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

    for (int i = 0; i < loopn; i++) {   /* v0.4.3 (0.6): escanea TODOS; closest-N al insertar */
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
        /* v0.4.3 (0.6): si el array esta lleno, reemplaza la caja mas LEJANA si esta
           es mas cercana. Asi nunca se pierde el enemigo de al lado por el orden. */
        int slot;
        if (drawn < MM_MAX_BOXES) slot = drawn++;
        else {
            int far = 0; float fd = nuevos[0].dist;
            for (int q = 1; q < MM_MAX_BOXES; q++) if (nuevos[q].dist > fd) { fd = nuevos[q].dist; far = q; }
            if (nb.dist >= fd) continue;   /* las 32 ya son mas cercanas: descarta */
            slot = far;
        }
        nuevos[slot] = nb;
    }

    /* 0.6: contadores desde el set final (closest-N), no durante la insercion. */
    g_count_players = 0; g_count_bots = 0;
    for (int q = 0; q < drawn; q++) { if (nuevos[q].robot) g_count_bots++; else g_count_players++; }

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
                     @"El juego se cerrará en %d segundos.", sec];
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
        a = [UIAlertController alertControllerWithTitle:@"Datos borrados"
                                                message:@"El juego se cerrará en 3 segundos."
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
            alertControllerWithTitle:@"Restablecer invitado"
                             message:@"Se borrarán los datos locales de la cuenta de invitado. "
                                     @"El juego se cerrará y al reabrir entrará como un invitado nuevo."
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

/* Reescritura atomica del archivo de estado que se puede leer sin syslog. */
static void mm_write_status(NSString *nota)
{
    @try {
        /* v0.4.3 (0.8): modmenu_status.txt es evidencia forense; solo se escribe con
           el modo debug ON (default OFF). El operador lo prende para diagnosticar. */
        if (!mm_def_bool(@"mm_debug", NO)) return;
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
/* v0.4.0: paleta de acento CONFIGURABLE (selector de tema en MISC). El tema 0 es
   la identidad FUSION (verde/morado); los demas re-skinan TODO el menu (panel,
   borde, gradiente, header, segmento, filas) porque todo lee estas dos funciones. */
typedef struct { float ar, ag, ab, br, bg, bb; } MMTheme;
static const MMTheme g_mm_themes[] = {
    { 0.20f, 1.00f, 0.58f,  0.63f, 0.30f, 1.00f },  /* 0 FUSION  verde / morado  */
    { 0.00f, 0.95f, 1.00f,  0.35f, 0.45f, 1.00f },  /* 1 Hielo    cian  / azul    */
    { 1.00f, 0.30f, 0.62f,  0.65f, 0.25f, 1.00f },  /* 2 Magenta  rosa  / morado  */
    { 1.00f, 0.62f, 0.12f,  1.00f, 0.22f, 0.40f },  /* 3 Fuego    ambar / rojo    */
    { 0.26f, 1.00f, 0.72f,  0.06f, 0.82f, 0.95f },  /* 4 Aqua     verde / cian    */
};
#define MM_THEME_COUNT ((int)(sizeof(g_mm_themes) / sizeof(g_mm_themes[0])))

static int mm_theme_idx(void)
{
    int i = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"mm_theme_accent"];
    if (i < 0 || i >= MM_THEME_COUNT) i = 0;
    return i;
}

static UIColor *mm_neon_green(void)
{
    MMTheme t = g_mm_themes[mm_theme_idx()];
    return [UIColor colorWithRed:t.ar green:t.ag blue:t.ab alpha:1.0];
}

static UIColor *mm_neon_purple(void)
{
    MMTheme t = g_mm_themes[mm_theme_idx()];
    return [UIColor colorWithRed:t.br green:t.bg blue:t.bb alpha:1.0];
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
    /* v0.4.0: deriva de las bandas (locations) -> fusion tipo AURORA: flujo
       continuo de las franjas de color, no un simple ida/vuelta. */
    if (g.locations.count >= 4 && [g animationForKey:@"mmNeonLoc"] == nil) {
        CAKeyframeAnimation *k = [CAKeyframeAnimation animationWithKeyPath:@"locations"];
        k.values = @[ @[@0.0, @0.35, @0.68, @1.0],
                      @[@0.0, @0.20, @0.52, @1.0],
                      @[@0.0, @0.46, @0.80, @1.0],
                      @[@0.0, @0.35, @0.68, @1.0] ];
        k.keyTimes = @[@0.0, @0.34, @0.68, @1.0];
        k.duration = 12.0;
        k.repeatCount = HUGE_VALF;
        k.timingFunction = [CAMediaTimingFunction
                            functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [g addAnimation:k forKey:@"mmNeonLoc"];
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

/*---------------------------------------------------------------------------
 * v0.3.2: contador JUG/BOT glass (SOLO UI).
 * v0.3.3: capsula sobria: blur oscuro, borde hairline y texto jerarquico.
 *   - el ancho sale del texto (minimo MM_COUNT_MIN_W) y se centra dentro de
 *     la safe area; no recibe toques ni tapa boton/panel.
 *--------------------------------------------------------------------------*/
static NSAttributedString *mm_count_text(int players, int bots)
{
    UIFont *labelFont = [UIFont systemFontOfSize:9.0
                                          weight:UIFontWeightSemibold];
    if (labelFont == nil) labelFont = [UIFont boldSystemFontOfSize:9.0];
    UIFont *numFont = [UIFont monospacedDigitSystemFontOfSize:13.0
                                                     weight:UIFontWeightSemibold];
    if (numFont == nil) numFont = [UIFont boldSystemFontOfSize:13.0];

    NSString *s = [NSString stringWithFormat:@"JUG  %d   ·   BOT  %d",
                   players, bots];
    NSMutableAttributedString *a = [[NSMutableAttributedString alloc]
        initWithString:s
            attributes:@{ NSFontAttributeName: numFont,
                          NSForegroundColorAttributeName:
                              [UIColor colorWithWhite:0.97 alpha:1.0],
                          NSKernAttributeName: @0.3 }];
    NSRange rj = [s rangeOfString:@"JUG"];
    NSRange rb = [s rangeOfString:@"BOT"];
    NSRange rd = [s rangeOfString:@"·"];
    if (rj.location != NSNotFound) {
        [a addAttributes:@{ NSFontAttributeName: labelFont,
                            NSForegroundColorAttributeName:
                                [mm_neon_green() colorWithAlphaComponent:0.96],
                            NSKernAttributeName: @1.1 } range:rj];
    }
    if (rb.location != NSNotFound) {
        [a addAttributes:@{ NSFontAttributeName: labelFont,
                            NSForegroundColorAttributeName:
                                [mm_neon_purple() colorWithAlphaComponent:0.96],
                            NSKernAttributeName: @1.1 } range:rb];
    }
    if (rd.location != NSNotFound) {
        [a addAttributes:@{ NSFontAttributeName: labelFont,
                            NSForegroundColorAttributeName:
                                [UIColor colorWithWhite:0.52 alpha:1.0] }
                    range:rd];
    }
    return a;
}

static void mm_layout_count_glass(void)
{
    if (g_count_glass == nil || g_root == nil || g_count_label == nil) return;

    NSAttributedString *text = g_count_label.attributedText;
    if (text.length == 0) text = mm_count_text(g_count_players, g_count_bots);
    CGSize ts = [text boundingRectWithSize:CGSizeMake(1000.0, MM_COUNT_H)
                                   options:NSStringDrawingUsesLineFragmentOrigin |
                                           NSStringDrawingUsesFontLeading
                                   context:nil].size;

    UIEdgeInsets safe = g_root.safeAreaInsets;
    CGFloat avail = g_root.bounds.size.width - safe.left - safe.right;
    if (avail < 80.0) avail = g_root.bounds.size.width;
    CGFloat maxW = MAX(80.0, avail - 16.0);
    CGFloat width = ceil(ts.width) + MM_COUNT_PAD_X * 2.0;
    if (width < MM_COUNT_MIN_W) width = MM_COUNT_MIN_W;
    if (width > maxW) width = maxW;

    CGFloat x = safe.left + round((avail - width) / 2.0);
    CGFloat y = MAX(8.0, safe.top + 6.0);
    CGRect f = CGRectMake(x, y, width, MM_COUNT_H);
    if (!CGRectEqualToRect(g_count_glass.frame, f))
        g_count_glass.frame = f;

    CGRect b = g_count_glass.bounds;
    if (g_count_neon != nil)  g_count_neon.frame = b;
    if (g_count_blur != nil)  g_count_blur.frame = b;
    if (g_count_shade != nil) g_count_shade.frame = b;
    if (g_count_label != nil) g_count_label.frame = CGRectInset(b, MM_COUNT_PAD_X, 0.0);
    g_count_glass.layer.shadowPath =
        [UIBezierPath bezierPathWithRoundedRect:b
                                   cornerRadius:MM_COUNT_H / 2.0].CGPath;
}

static void mm_update_count_glass_text(int players, int bots)
{
    if (g_count_label == nil) return;
    if (players == g_count_last_players && bots == g_count_last_bots) return;
    g_count_last_players = players;
    g_count_last_bots = bots;

    g_count_label.attributedText = mm_count_text(players, bots);
    mm_layout_count_glass();
}

static BOOL mm_count_glass_visible(void)
{
    return g_count_glass != nil &&
           mm_def_bool(@"mm_esp_master", NO) &&
           mm_def_bool(@"mm_esp_count", NO) &&
           !mm_def_bool(@"mm_stream", NO);
}

static void mm_build_count_glass(void)
{
    if (g_count_glass != nil) return;

    CGFloat radius = MM_COUNT_H / 2.0;
    g_count_glass = [[UIView alloc] initWithFrame:
                     CGRectMake(0.0, 0.0, MM_COUNT_MIN_W, MM_COUNT_H)];
    g_count_glass.backgroundColor = [UIColor colorWithWhite:0.02 alpha:0.18];
    g_count_glass.opaque = NO;
    g_count_glass.userInteractionEnabled = NO;
    g_count_glass.clipsToBounds = NO;
    g_count_glass.hidden = YES;
    g_count_glass.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
                                     UIViewAutoresizingFlexibleRightMargin;
    g_count_glass.layer.cornerRadius = radius;
    g_count_glass.layer.borderWidth = 0.8;
    g_count_glass.layer.borderColor =
        [UIColor colorWithWhite:1.0 alpha:0.16].CGColor;
    g_count_glass.layer.shadowColor = [UIColor blackColor].CGColor;
    g_count_glass.layer.shadowOpacity = 0.40;
    g_count_glass.layer.shadowRadius = 8.0;
    g_count_glass.layer.shadowOffset = CGSizeMake(0.0, 2.0);

    g_count_blur = [[UIVisualEffectView alloc] initWithEffect:
                    [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    g_count_blur.frame = g_count_glass.bounds;
    g_count_blur.userInteractionEnabled = NO;
    g_count_blur.alpha = 0.88;
    g_count_blur.layer.cornerRadius = radius;
    g_count_blur.clipsToBounds = YES;
    [g_count_glass addSubview:g_count_blur];

    /* v0.3.3: brillo superior estatico, sin gradiente verde/morado animado. */
    g_count_neon = [CAGradientLayer layer];
    g_count_neon.frame = g_count_glass.bounds;
    g_count_neon.cornerRadius = radius;
    g_count_neon.masksToBounds = YES;
    g_count_neon.startPoint = CGPointMake(0.0, 0.0);
    g_count_neon.endPoint = CGPointMake(0.0, 1.0);
    g_count_neon.colors = @[(__bridge id)[UIColor colorWithWhite:1.0
                                                           alpha:0.10].CGColor,
                            (__bridge id)[UIColor colorWithWhite:1.0
                                                           alpha:0.0].CGColor];
    [g_count_glass.layer addSublayer:g_count_neon];

    g_count_shade = [[UIView alloc] initWithFrame:g_count_glass.bounds];
    g_count_shade.backgroundColor = [UIColor colorWithWhite:0.01 alpha:0.22];
    g_count_shade.userInteractionEnabled = NO;
    g_count_shade.layer.cornerRadius = radius;
    g_count_shade.clipsToBounds = YES;
    g_count_shade.layer.borderWidth = 0.5;
    g_count_shade.layer.borderColor =
        [UIColor colorWithWhite:1.0 alpha:0.06].CGColor;
    [g_count_glass addSubview:g_count_shade];

    g_count_label = [[UILabel alloc] initWithFrame:
                     CGRectInset(g_count_glass.bounds, MM_COUNT_PAD_X, 0.0)];
    UIFont *font = [UIFont monospacedDigitSystemFontOfSize:13.0
                                                   weight:UIFontWeightSemibold];
    if (font == nil) font = [UIFont boldSystemFontOfSize:13.0];
    g_count_label.font = font;
    g_count_label.textAlignment = NSTextAlignmentCenter;
    g_count_label.backgroundColor = [UIColor clearColor];
    g_count_label.userInteractionEnabled = NO;
    g_count_label.adjustsFontSizeToFitWidth = YES;
    g_count_label.minimumScaleFactor = 0.85;
    g_count_label.lineBreakMode = NSLineBreakByClipping;
    g_count_label.layer.shadowColor = [UIColor blackColor].CGColor;
    g_count_label.layer.shadowOpacity = 0.55;
    g_count_label.layer.shadowRadius = 1.5;
    g_count_label.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    [g_count_glass addSubview:g_count_label];

    g_count_last_players = -1;
    g_count_last_bots = -1;
    mm_update_count_glass_text(0, 0);
    mm_layout_count_glass();
}

static void mm_refresh_count_glass(void)
{
    if (g_count_glass == nil) return;

    if (!mm_count_glass_visible()) {
        if (!g_count_glass.hidden) g_count_glass.hidden = YES;
        return;
    }

    mm_update_count_glass_text(g_count_players, g_count_bots);
    if (g_count_glass.hidden) {
        g_count_glass.hidden = NO;
        g_count_glass.alpha = 1.0;
        mm_layout_count_glass();
    }
}

/* Fila generica del panel: titulo a la izquierda + control a la derecha. */
static UIView *mm_row(NSString *titulo, UIView *ctrl)
{
    UIView *r = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 284.0, 34.0)];
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(8.0, 0, 196.0, 34.0)];
    l.text = titulo;
    l.textColor = [UIColor colorWithWhite:0.97 alpha:1.0];
    l.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightMedium];
    [r addSubview:l];
    /* v0.4.0: hairline inferior tenue con el acento del tema (fila "premium"). */
    UIView *hair = [[UIView alloc] initWithFrame:CGRectMake(6.0, 33.0, 272.0, 0.5)];
    hair.backgroundColor = [mm_neon_purple() colorWithAlphaComponent:0.14];
    hair.userInteractionEnabled = NO;
    [r addSubview:hair];
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
/* Crea boton flotante + panel (una sola vez). */
static void mm_build_ui(void)
{
    /* --- boton flotante (v0.3.1: glass neon) --- */
    if (g_btn == nil) {
        g_btn = [UIButton buttonWithType:UIButtonTypeCustom];
        g_btn.bounds = CGRectMake(0, 0, 54.0, 54.0);
        g_btn.backgroundColor = [UIColor colorWithRed:0.02 green:0.08 blue:0.05 alpha:0.92];
        g_btn.layer.cornerRadius = 27.0;
        g_btn.layer.borderWidth = 1.0;
        g_btn.layer.borderColor =
            [mm_neon_green() colorWithAlphaComponent:0.5].CGColor;
        g_btn.layer.shadowColor =
            [mm_neon_green() colorWithAlphaComponent:0.9].CGColor;
        g_btn.layer.shadowOpacity = 0.40;
        g_btn.layer.shadowRadius = 12.0;
        g_btn.layer.shadowOffset = CGSizeZero;
        g_btn.clipsToBounds = NO;
        [g_btn setTitle:@"F" forState:UIControlStateNormal];
        [g_btn setTitleColor:[UIColor colorWithWhite:0.98 alpha:1.0]
                    forState:UIControlStateNormal];
        UIFont *bf = [UIFont fontWithName:@"AvenirNext-Bold" size:23.0];
        if (bf == nil) bf = [UIFont systemFontOfSize:23.0 weight:UIFontWeightBold];
        g_btn.titleLabel.font = bf;
        /* v0.3.2: un poco mas de contraste/glow en el texto del boton. */
        g_btn.titleLabel.layer.shadowColor =
            [mm_neon_green() colorWithAlphaComponent:0.70].CGColor;
        g_btn.titleLabel.layer.shadowOpacity = 0.60;
        g_btn.titleLabel.layer.shadowRadius = 3.0;
        g_btn.titleLabel.layer.shadowOffset = CGSizeZero;
        [g_btn addTarget:[MMTargets shared] action:@selector(onTap)
        forControlEvents:UIControlEventTouchUpInside];
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]
            initWithTarget:[MMTargets shared] action:@selector(onPan:)];
        [g_btn addGestureRecognizer:pan];
        /* v0.4.0 #8: kill-switch por gesto — mantener presionado el boton oculta
           TODO al instante (anti-spectator); otro long-press restaura. */
        UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc]
            initWithTarget:[MMTargets shared] action:@selector(onPanic:)];
        lp.minimumPressDuration = 0.6;
        [g_btn addGestureRecognizer:lp];

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
        CGColorRef sh1 = [UIColor colorWithWhite:1.0 alpha:0.26].CGColor;
        CGColorRef sh2 = [UIColor colorWithWhite:1.0 alpha:0.0].CGColor;
        shine.colors = @[(__bridge id)sh1, (__bridge id)sh2];
        [g_btn.layer insertSublayer:shine atIndex:1];

        g_btn.layer.shadowPath =
            [UIBezierPath bezierPathWithOvalInRect:g_btn.bounds].CGPath;
        /* v0.4.1: boton mas sobrio y profesional — SIN anillo de color animado
           ni pulso (contrastaban con la identidad). Vidrio estatico + borde fino
           verde + glow suave fijo + monograma "F". */
    }

    /* --- contador JUG/BOT (v0.3.2: glass flotante arriba) --- */
    if (g_count_glass == nil) mm_build_count_glass();

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
        /* v0.4.1: ESP mas fluido + FPS REAL. Antes estaba capado a 30, por eso el
           medidor mostraba 30 fijo. En ProMotion (iPhone 13 Pro+/14 Pro Max) el
           display corre hasta 120 Hz y la refresca segun el contenido; dejamos que
           el CADisplayLink llegue a 120 para que mm_esp_frame mida la cadencia REAL
           del display (hasta 120). Fallback a 60 en equipos sin la API. */
        if (@available(iOS 15.0, *))
            g_link.preferredFrameRateRange = CAFrameRateRangeMake(30.0, 120.0, 120.0);
        else
            g_link.preferredFramesPerSecond = 60;
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
        initWithString:@"FUSION"
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

    g_seg = [[UISegmentedControl alloc] initWithItems:@[@"ESP", @"VIS", @"MISC", @"EXTRA", @"INFO"]];
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
    g_p_more = [[UIScrollView alloc] initWithFrame:CGRectMake(8.0, 74.0, 284.0, 348.0)];
    ((UIScrollView *)g_p_more).showsVerticalScrollIndicator = YES;
    ((UIScrollView *)g_p_more).indicatorStyle = UIScrollViewIndicatorStyleWhite;
    g_p_info = [[UIView alloc] initWithFrame:CGRectMake(8.0, 74.0, 284.0, 348.0)];
    g_p_vis.hidden = YES;
    g_p_misc.hidden = YES;
    g_p_more.hidden = YES;
    g_p_info.hidden = YES;
    [g_panel addSubview:g_p_esp];
    [g_panel addSubview:g_p_vis];
    [g_panel addSubview:g_p_misc];
    [g_panel addSubview:g_p_more];
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

    /* --- pagina MISC --- */
    UILabel *d1 = [[UILabel alloc] initWithFrame:CGRectMake(6.0, 6.0, 272.0, 18.0)];
    d1.text = @"Cuenta invitado";
    d1.textColor = [UIColor colorWithRed:0.55 green:1.0 blue:0.66 alpha:1.0];
    d1.font = [UIFont boldSystemFontOfSize:12.0];
    [g_p_misc addSubview:d1];

    UIButton *gr = [UIButton buttonWithType:UIButtonTypeCustom];
    gr.frame = CGRectMake(6.0, 28.0, 272.0, 36.0);
    gr.backgroundColor = [UIColor colorWithRed:0.48 green:0.08 blue:0.08 alpha:0.95];
    gr.layer.cornerRadius = 8.0;
    gr.layer.borderWidth = 1.0;
    gr.layer.borderColor = [UIColor colorWithRed:1.0 green:0.45 blue:0.45 alpha:0.7].CGColor;
    [gr setTitle:@"Restablecer invitado" forState:UIControlStateNormal];
    [gr setTitleColor:[UIColor colorWithRed:1.0 green:0.9 blue:0.9 alpha:1.0]
             forState:UIControlStateNormal];
    gr.titleLabel.font = [UIFont boldSystemFontOfSize:13.0];
    [gr addTarget:[MMTargets shared] action:@selector(onGuestReset)
        forControlEvents:UIControlEventTouchUpInside];
    [g_p_misc addSubview:gr];

    /* v0.4.0 #7: perfiles de configuracion (3 slots) */
    UILabel *pfl = [[UILabel alloc] initWithFrame:CGRectMake(6.0, 78.0, 272.0, 16.0)];
    pfl.text = @"Perfiles de configuracion";
    pfl.textColor = [UIColor colorWithRed:0.55 green:1.0 blue:0.66 alpha:1.0];
    pfl.font = [UIFont boldSystemFontOfSize:12.0];
    [g_p_misc addSubview:pfl];

    UISegmentedControl *pfseg = [[UISegmentedControl alloc]
        initWithItems:@[@"P1", @"P2", @"P3"]];
    pfseg.frame = CGRectMake(6.0, 100.0, 272.0, 28.0);
    pfseg.selectedSegmentIndex = 0;
    if ([pfseg respondsToSelector:@selector(setSelectedSegmentTintColor:)])
        pfseg.selectedSegmentTintColor = [mm_neon_purple() colorWithAlphaComponent:0.85];
    [pfseg setTitleTextAttributes:@{ NSForegroundColorAttributeName:[UIColor colorWithWhite:0.88 alpha:1.0],
        NSFontAttributeName:[UIFont boldSystemFontOfSize:11.0] } forState:UIControlStateNormal];
    [pfseg addTarget:[MMTargets shared] action:@selector(onProfileSlot:)
        forControlEvents:UIControlEventValueChanged];
    [g_p_misc addSubview:pfseg];

    UIButton *pfsave = [UIButton buttonWithType:UIButtonTypeCustom];
    pfsave.frame = CGRectMake(6.0, 134.0, 132.0, 32.0);
    pfsave.backgroundColor = [UIColor colorWithRed:0.08 green:0.42 blue:0.20 alpha:0.95];
    pfsave.layer.cornerRadius = 7.0;
    [pfsave setTitle:@"Guardar" forState:UIControlStateNormal];
    [pfsave setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    pfsave.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
    [pfsave addTarget:[MMTargets shared] action:@selector(onProfileSave)
        forControlEvents:UIControlEventTouchUpInside];
    [g_p_misc addSubview:pfsave];

    UIButton *pfload = [UIButton buttonWithType:UIButtonTypeCustom];
    pfload.frame = CGRectMake(146.0, 134.0, 132.0, 32.0);
    pfload.backgroundColor = [UIColor colorWithRed:0.10 green:0.28 blue:0.48 alpha:0.95];
    pfload.layer.cornerRadius = 7.0;
    [pfload setTitle:@"Cargar" forState:UIControlStateNormal];
    [pfload setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    pfload.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
    [pfload addTarget:[MMTargets shared] action:@selector(onProfileLoad)
        forControlEvents:UIControlEventTouchUpInside];
    [g_p_misc addSubview:pfload];

    /* v0.4.3 (0.8): debug — prende el status file (modmenu_status.txt) para diagnosticar.
       Default OFF: sin esto no se escribe evidencia forense. */
    UISwitch *dbg = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 51.0, 31.0)];
    dbg.on = mm_def_bool(@"mm_debug", NO);
    dbg.onTintColor = mm_verde();
    dbg.accessibilityIdentifier = @"mm_debug";
    dbg.transform = CGAffineTransformMakeScale(0.9, 0.9);
    [dbg addTarget:[MMTargets shared] action:@selector(onSwitch:)
        forControlEvents:UIControlEventValueChanged];
    UIView *dbgr = mm_row(@"Debug (status file)", dbg);
    dbgr.frame = CGRectMake(0, 176.0, 284.0, 31.0);
    [g_p_misc addSubview:dbgr];

    /* --- pagina EXTRA (v0.4.0: features nuevas de overlay) --- */
    UILabel *xh = [[UILabel alloc] initWithFrame:CGRectMake(6.0, 2.0, 272.0, 18.0)];
    xh.text = @"OVERLAY";
    xh.textColor = [UIColor colorWithRed:0.55 green:1.0 blue:0.66 alpha:1.0];
    xh.font = [UIFont boldSystemFontOfSize:11.0];
    [g_p_more addSubview:xh];

    NSArray *xkeys = @[ @"mm_x_cross", @"mm_x_aimring", @"mm_x_head",
                        @"mm_x_distcol", @"mm_x_lowhp", @"mm_x_fps",
                        @"mm_x_hpnum", @"mm_x_priority", @"mm_x_warn", @"mm_x_arrow" ];
    NSArray *xtit  = @[ @"Crosshair (mira)", @"Anillo de aim", @"Punto en la cabeza",
                        @"Color por distancia", @"Resaltar vida baja", @"Medidor de FPS",
                        @"Vida numerica", @"Prioridad (mas cercano)", @"Aviso enemigo cerca",
                        @"Flecha fuera de pantalla" ];
    for (NSUInteger i = 0; i < xkeys.count; i++) {
        UIView *xrow = mm_switch_row(xtit[i], xkeys[i], NO);
        xrow.frame = CGRectMake(0, 24.0 + (CGFloat)i * 31.0, 284.0, 31.0);
        [g_p_more addSubview:xrow];
    }

    CGFloat ry = 24.0 + (CGFloat)xkeys.count * 31.0 + 10.0;   /* bajo los toggles */

    /* v0.4.2: estilo de crosshair */
    UILabel *csl = [[UILabel alloc] initWithFrame:CGRectMake(6.0, ry, 272.0, 16.0)];
    csl.text = @"Estilo de crosshair";
    csl.textColor = [UIColor colorWithWhite:0.80 alpha:1.0];
    csl.font = [UIFont systemFontOfSize:11.0];
    [g_p_more addSubview:csl]; ry += 20.0;
    UISegmentedControl *css = [[UISegmentedControl alloc]
        initWithItems:@[@"Cruz", @"Punto", @"Circulo", @"Todo"]];
    css.frame = CGRectMake(6.0, ry, 272.0, 28.0);
    { int cv = (int)mm_def_float(@"mm_x_cross_style", 0.0f); if (cv < 0 || cv > 3) cv = 0; css.selectedSegmentIndex = cv; }
    if ([css respondsToSelector:@selector(setSelectedSegmentTintColor:)])
        css.selectedSegmentTintColor = [mm_neon_purple() colorWithAlphaComponent:0.85];
    [css setTitleTextAttributes:@{ NSForegroundColorAttributeName:[UIColor colorWithWhite:0.88 alpha:1.0],
        NSFontAttributeName:[UIFont systemFontOfSize:10.0] } forState:UIControlStateNormal];
    [css addTarget:[MMTargets shared] action:@selector(onCrossStyle:)
        forControlEvents:UIControlEventValueChanged];
    [g_p_more addSubview:css]; ry += 38.0;

    /* v0.4.2: limite de objetivos (closest-N) */
    UILabel *mnl = [[UILabel alloc] initWithFrame:CGRectMake(6.0, ry, 272.0, 16.0)];
    mnl.text = @"Limite de objetivos (0 = todos)";
    mnl.textColor = [UIColor colorWithWhite:0.80 alpha:1.0];
    mnl.font = [UIFont systemFontOfSize:11.0];
    [g_p_more addSubview:mnl]; ry += 18.0;
    UISlider *mns = [[UISlider alloc] initWithFrame:CGRectMake(6.0, ry, 272.0, 28.0)];
    mns.minimumValue = 0.0f; mns.maximumValue = 32.0f;
    mns.value = mm_def_float(@"mm_x_maxn", 0.0f);
    mns.tintColor = mm_neon_green();
    [mns addTarget:[MMTargets shared] action:@selector(onMaxN:)
        forControlEvents:UIControlEventValueChanged];
    [g_p_more addSubview:mns]; ry += 36.0;

    /* #10 selector de tema del menu (re-skina todo el acento) */
    UILabel *tl = [[UILabel alloc] initWithFrame:CGRectMake(6.0, ry, 272.0, 16.0)];
    tl.text = @"Tema del menu";
    tl.textColor = [UIColor colorWithWhite:0.80 alpha:1.0];
    tl.font = [UIFont systemFontOfSize:11.0];
    [g_p_more addSubview:tl]; ry += 20.0;
    UISegmentedControl *tac = [[UISegmentedControl alloc]
        initWithItems:@[@"FUSION", @"Hielo", @"Magenta", @"Fuego", @"Aqua"]];
    tac.frame = CGRectMake(6.0, ry, 272.0, 28.0);
    { int ti = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"mm_theme_accent"];
      if (ti < 0 || ti > 4) ti = 0; tac.selectedSegmentIndex = ti; }
    if ([tac respondsToSelector:@selector(setSelectedSegmentTintColor:)])
        tac.selectedSegmentTintColor = [mm_neon_purple() colorWithAlphaComponent:0.85];
    [tac setTitleTextAttributes:@{ NSForegroundColorAttributeName:[UIColor colorWithWhite:0.86 alpha:1.0],
        NSFontAttributeName:[UIFont boldSystemFontOfSize:9.5] } forState:UIControlStateNormal];
    [tac setTitleTextAttributes:@{ NSForegroundColorAttributeName:[UIColor whiteColor],
        NSFontAttributeName:[UIFont boldSystemFontOfSize:9.5] } forState:UIControlStateSelected];
    [tac addTarget:[MMTargets shared] action:@selector(onThemeAccent:)
        forControlEvents:UIControlEventValueChanged];
    [g_p_more addSubview:tac]; ry += 38.0;

    /* #11 opacidad del menu */
    UILabel *ol = [[UILabel alloc] initWithFrame:CGRectMake(6.0, ry, 272.0, 16.0)];
    ol.text = @"Opacidad del menu";
    ol.textColor = [UIColor colorWithWhite:0.80 alpha:1.0];
    ol.font = [UIFont systemFontOfSize:11.0];
    [g_p_more addSubview:ol]; ry += 18.0;
    UISlider *osl = [[UISlider alloc] initWithFrame:CGRectMake(6.0, ry, 272.0, 28.0)];
    osl.minimumValue = 0.4f; osl.maximumValue = 1.0f;
    osl.value = mm_def_float(@"mm_menu_opacity", 1.0f);
    osl.tintColor = mm_neon_green();
    [osl addTarget:[MMTargets shared] action:@selector(onMenuOpacity:)
        forControlEvents:UIControlEventValueChanged];
    [g_p_more addSubview:osl]; ry += 34.0;

    /* #11 escala del menu */
    UILabel *scl = [[UILabel alloc] initWithFrame:CGRectMake(6.0, ry, 272.0, 16.0)];
    scl.text = @"Escala del menu";
    scl.textColor = [UIColor colorWithWhite:0.80 alpha:1.0];
    scl.font = [UIFont systemFontOfSize:11.0];
    [g_p_more addSubview:scl]; ry += 18.0;
    UISlider *ssl = [[UISlider alloc] initWithFrame:CGRectMake(6.0, ry, 272.0, 28.0)];
    ssl.minimumValue = 0.8f; ssl.maximumValue = 1.2f;
    ssl.value = mm_def_float(@"mm_menu_scale", 1.0f);
    ssl.tintColor = mm_neon_green();
    [ssl addTarget:[MMTargets shared] action:@selector(onMenuScale:)
        forControlEvents:UIControlEventValueChanged];
    [g_p_more addSubview:ssl]; ry += 36.0;

    /* Tier-2 (gated): presentes pero NO activables hasta dumpear offsets. Honesto:
       no invento offsets. Aparecen atenuadas con nota. */
    UILabel *t2 = [[UILabel alloc] initWithFrame:CGRectMake(6.0, ry, 272.0, 16.0)];
    t2.text = @"TIER 2 — requiere offsets (proxima)";
    t2.textColor = [UIColor colorWithWhite:0.55 alpha:1.0];
    t2.font = [UIFont boldSystemFontOfSize:10.0];
    [g_p_more addSubview:t2]; ry += 20.0;
    NSArray *t2tit = @[ @"ESP de esqueleto", @"Visible / tapado",
                        @"ESP de granadas", @"ESP de loot / vehiculos" ];
    for (NSUInteger i = 0; i < t2tit.count; i++) {
        UISwitch *t2sw = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 51.0, 31.0)];
        t2sw.on = NO; t2sw.enabled = NO;    /* gated */
        t2sw.transform = CGAffineTransformMakeScale(0.9, 0.9);
        UIView *t2row = mm_row(t2tit[i], t2sw);
        t2row.frame = CGRectMake(0, ry, 284.0, 31.0);
        t2row.alpha = 0.5;
        [g_p_more addSubview:t2row]; ry += 31.0;
    }

    ((UIScrollView *)g_p_more).contentSize = CGSizeMake(284.0, ry + 8.0);

    /* --- pagina INFO --- */
    g_info = [[UILabel alloc] initWithFrame:CGRectMake(6.0, 4.0, 272.0, 280.0)];
    g_info.numberOfLines = 0;
    g_info.clipsToBounds = YES;
    g_info.textColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    g_info.font = [UIFont fontWithName:@"Menlo" size:9.5] ?: [UIFont systemFontOfSize:9.5];
    [g_p_info addSubview:g_info];

    /* v0.3.3: pie de autoria + contacto Telegram tappable. */
    UIView *foot = [[UIView alloc] initWithFrame:CGRectMake(6.0, 288.0, 272.0, 54.0)];
    foot.backgroundColor = [UIColor colorWithWhite:0.04 alpha:0.55];
    foot.layer.cornerRadius = 9.0;
    foot.layer.borderWidth = 0.6;
    foot.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.10].CGColor;
    [g_p_info addSubview:foot];

    UILabel *made = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 5.0, 252.0, 12.0)];
    made.text = @"Made by: Jose Lopez";
    made.textColor = [UIColor colorWithWhite:0.62 alpha:1.0];
    made.font = [UIFont systemFontOfSize:9.5 weight:UIFontWeightMedium];
    [foot addSubview:made];

    UIButton *tg = [UIButton buttonWithType:UIButtonTypeCustom];
    tg.frame = CGRectMake(0.0, 19.0, 272.0, 32.0);
    tg.backgroundColor = [UIColor clearColor];
    tg.accessibilityLabel = @"Telegram @l0pez9801";
    tg.accessibilityIdentifier = @"mm_telegram";
    [tg addTarget:[MMTargets shared] action:@selector(onTelegram)
        forControlEvents:UIControlEventTouchUpInside];
    [foot addSubview:tg];

    UIView *badge = [[UIView alloc] initWithFrame:CGRectMake(8.0, 4.0, 24.0, 24.0)];
    badge.backgroundColor = [UIColor colorWithRed:0.16 green:0.58 blue:0.96 alpha:1.0];
    badge.layer.cornerRadius = 12.0;
    badge.userInteractionEnabled = NO;
    [tg addSubview:badge];

    UIImage *planeImg = [UIImage systemImageNamed:@"paperplane.fill"];
    UIImageView *plane = [[UIImageView alloc] initWithFrame:CGRectMake(4.0, 4.0, 16.0, 16.0)];
    plane.image = [planeImg imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    plane.tintColor = [UIColor whiteColor];
    plane.contentMode = UIViewContentModeScaleAspectFit;
    plane.userInteractionEnabled = NO;
    [badge addSubview:plane];

    UILabel *handle = [[UILabel alloc] initWithFrame:CGRectMake(40.0, 1.0, 190.0, 15.0)];
    handle.text = @"@l0pez9801";
    handle.textColor = [UIColor colorWithWhite:0.98 alpha:1.0];
    handle.font = [UIFont fontWithName:@"Menlo-Bold" size:11.5] ?:
                  [UIFont boldSystemFontOfSize:11.5];
    handle.userInteractionEnabled = NO;
    [tg addSubview:handle];

    UILabel *sub = [[UILabel alloc] initWithFrame:CGRectMake(40.0, 16.0, 190.0, 11.0)];
    sub.text = @"Telegram · tocar para abrir";
    sub.textColor = [UIColor colorWithWhite:0.58 alpha:1.0];
    sub.font = [UIFont systemFontOfSize:8.5];
    sub.userInteractionEnabled = NO;
    [tg addSubview:sub];

    UILabel *chev = [[UILabel alloc] initWithFrame:CGRectMake(244.0, 5.0, 18.0, 20.0)];
    chev.text = @"›";
    chev.textColor = [UIColor colorWithWhite:0.55 alpha:1.0];
    chev.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightMedium];
    chev.textAlignment = NSTextAlignmentRight;
    chev.userInteractionEnabled = NO;
    [tg addSubview:chev];

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
    mm_refresh_count_glass();   /* v0.3.2: el maestro tambien manda */
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
    /* v0.3.2: el contador tambien forma parte de la UI que Stream oculta. */
    mm_refresh_count_glass();
}

static void mm_position_panel(void)
{
    if (g_panel == nil || g_panel.superview == nil || g_btn == nil) return;
    /* v0.4.1 FIX del bug de tamano: NUNCA setear .frame con un transform de escala
       activo (UIKit deja el frame indefinido y el panel salta/se deforma). Reset a
       identidad, posicionar en tamano base, y re-aplicar la escala del usuario. */
    g_panel.transform = CGAffineTransformIdentity;

    CGRect rb = g_panel.superview.bounds;
    CGFloat w = MM_PANEL_W, h = MM_PANEL_H;
    CGFloat px, py;

    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"mm_panel_pos"]) {
        CGFloat cx = mm_def_float(@"mm_panel_x", w / 2.0 + 8.0);
        CGFloat cy = mm_def_float(@"mm_panel_y", h / 2.0 + 34.0);
        px = cx - w / 2.0;
        py = cy - h / 2.0;
    } else {
        CGPoint c = g_btn.center;
        px = c.x - w / 2.0;
        py = c.y + 34.0;
        if (py + h > rb.size.height - 12.0) py = c.y - h - 34.0;  /* si no cabe abajo, arriba */
    }
    px = MAX(4.0, MIN(rb.size.width  - w - 4.0, px));
    py = MAX(34.0, MIN(rb.size.height - h - 12.0, py));
    g_panel.frame = CGRectMake(px, py, w, h);
    mm_layout_panel_glass();

    CGFloat mmSc = mm_def_float(@"mm_menu_scale", 1.0f);
    if (mmSc < 0.8f) mmSc = 0.8f; if (mmSc > 1.2f) mmSc = 1.2f;
    if (mmSc != 1.0f) g_panel.transform = CGAffineTransformMakeScale(mmSc, mmSc);
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
            CGFloat mmOp = mm_def_float(@"mm_menu_opacity", 1.0f);
            CGFloat mmSc = mm_def_float(@"mm_menu_scale", 1.0f);
            if (mmOp < 0.4f) mmOp = 0.4f; if (mmOp > 1.0f) mmOp = 1.0f;
            if (mmSc < 0.8f) mmSc = 0.8f; if (mmSc > 1.2f) mmSc = 1.2f;
            g_panel.transform = CGAffineTransformMakeScale(mmSc * 0.97f, mmSc * 0.97f);
            /* v0.4.0: apertura con resorte (spring) + opacidad/escala del usuario (#11). */
            [UIView animateWithDuration:0.32 delay:0.0
                 usingSpringWithDamping:0.78 initialSpringVelocity:0.6
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                g_panel.alpha = mmOp;
                g_panel.transform = CGAffineTransformMakeScale(mmSc, mmSc);
            } completion:nil];
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

/* v0.3.5: INFO limpia. El diagnostico tecnico ya no se muestra aqui:
   sigue en Documents/modmenu_status.txt y en el syslog. */
static void mm_refresh_info(void)
{
    if (g_info == nil) return;
    if (g_info.attributedText.length > 0) return;
    @try {
        UIFont *titleFont = [UIFont fontWithName:@"Menlo-Bold" size:17.0] ?:
                            [UIFont boldSystemFontOfSize:17.0];
        UIFont *verFont = [UIFont fontWithName:@"Menlo-Bold" size:10.0] ?:
                          [UIFont boldSystemFontOfSize:10.0];
        UIFont *bodyFont = [UIFont systemFontOfSize:11.0];
        UIFont *itemFont = [UIFont systemFontOfSize:12.5];
        NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
        ps.lineSpacing = 3.0;

        NSMutableAttributedString *t = [[NSMutableAttributedString alloc]
            initWithString:@"FUSION\n"
                attributes:@{ NSFontAttributeName: titleFont,
                              NSForegroundColorAttributeName: mm_neon_green(),
                              NSKernAttributeName: @2.0 }];
        [t appendAttributedString:[[NSAttributedString alloc]
            initWithString:[NSString stringWithFormat:@"v%s\n\n", MODMENU_VERSION]
                attributes:@{ NSFontAttributeName: verFont,
                              NSForegroundColorAttributeName:
                                  [mm_neon_purple() colorWithAlphaComponent:0.95] }]];
        [t appendAttributedString:[[NSAttributedString alloc]
            initWithString:@"Aimbot no toggleable para mayor seguridad.\n\n"
                attributes:@{ NSFontAttributeName: itemFont,
                              NSForegroundColorAttributeName:
                                  [UIColor colorWithWhite:0.95 alpha:1.0],
                              NSParagraphStyleAttributeName: ps }]];
        [t appendAttributedString:[[NSAttributedString alloc]
            initWithString:@"Proyecto desarrollado por\nJose Lopez — Ing. de Sistemas\n\n"
                attributes:@{ NSFontAttributeName: bodyFont,
                              NSForegroundColorAttributeName:
                                  [UIColor colorWithWhite:0.70 alpha:1.0],
                              NSParagraphStyleAttributeName: ps }]];
        [t appendAttributedString:[[NSAttributedString alloc]
            initWithString:@"Contacto:"
                attributes:@{ NSFontAttributeName: bodyFont,
                              NSForegroundColorAttributeName:
                                  [UIColor colorWithWhite:0.55 alpha:1.0] }]];
        g_info.attributedText = t;
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

        /* v0.3.2: el contador glass va encima del lienzo/agua pero DEBAJO del
           boton y del panel (indice 1). No recibe toques. */
        if (g_count_glass == nil) mm_build_count_glass();
        if (g_count_glass.superview != g_root) {
            [g_count_glass removeFromSuperview];
            [g_root insertSubview:g_count_glass atIndex:1];
        }
        mm_layout_count_glass();

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
            UIFont *wmFont = [UIFont fontWithName:@"Menlo" size:9.5] ?:
                             [UIFont systemFontOfSize:9.5];
            g_marca.font = wmFont;
            NSMutableAttributedString *wm = [[NSMutableAttributedString alloc]
                initWithString:@"●  Made by: Jose Lopez"
                    attributes:@{ NSFontAttributeName: wmFont,
                                  NSForegroundColorAttributeName:
                                      [UIColor colorWithWhite:0.72 alpha:0.42],
                                  NSKernAttributeName: @0.35 }];
            [wm addAttributes:@{ NSFontAttributeName:
                                     [UIFont systemFontOfSize:8.0],
                                 NSForegroundColorAttributeName:
                                     [mm_neon_green() colorWithAlphaComponent:0.62] }
                         range:NSMakeRange(0, 1)];
            g_marca.attributedText = wm;
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
            UIEdgeInsets safe = g_root.safeAreaInsets;
            rm.origin.x = safe.left + 14.0;
            rm.origin.y = g_root.bounds.size.height - rm.size.height -
                          MAX(10.0, safe.bottom + 4.0);
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

/*==========================================================================
 * v0.3.7 — LICENCIA (cliente en FusionCore; migra KeyGate).
 *
 * Verifica un token ES256 que la app guarda en el Keychain tras activar contra
 * el servidor. Reemplaza a KeyGate (2a dylib + claves CODMGateKey/Device en el
 * plist = el vector estatico F-04): aqui todo vive DENTRO del carrier, el token
 * en Keychain, cero claves plist.
 *
 * Security.framework verifica firmas ECDSA en DER (X9.62); el token JWS trae la
 * firma en r||s (64 B), asi que se convierte r||s -> DER antes de verificar.
 *
 * ENFORCE: g_lic_enforce arranca en NO (modo observacion) — verifica, registra
 * y expone el estado, pero NO bloquea features, hasta validar en equipo. Activar
 * el bloqueo sin probar podria dejar fuera a usuarios validos (leccion anogs).
 *==========================================================================*/

static BOOL      g_lic_valid = NO;
static BOOL      g_lic_enforce = NO;        /* OFF hasta validar en dispositivo */
static NSString *g_lic_reason = nil;
static NSString *g_lic_sku = nil;
static NSArray  *g_lic_feats = nil;
static long      g_lic_exp = 0;

/* Clave publica ES256 (punto sin comprimir 0x04 || X(32) || Y(32), 65 B).
   PLACEHOLDER: reemplazar por la de produccion (imprimela con `fusion license pubkey`).
   Con el placeholder la verificacion fallara (reason="firma invalida"), que es lo
   correcto hasta pegar la real. */
static const uint8_t MM_LIC_PUBKEY[65] = { 0x04 };  /* resto en cero = placeholder */

#define MM_LIC_SERVICE @"com.fusion.license"

static NSData *mm_lic_kc_get(NSString *acct)
{
    NSDictionary *q = @{ (__bridge id)kSecClass:(__bridge id)kSecClassGenericPassword,
                         (__bridge id)kSecAttrService:MM_LIC_SERVICE,
                         (__bridge id)kSecAttrAccount:acct,
                         (__bridge id)kSecReturnData:@YES,
                         (__bridge id)kSecMatchLimit:(__bridge id)kSecMatchLimitOne };
    CFTypeRef r = NULL;
    if (SecItemCopyMatching((__bridge CFDictionaryRef)q, &r) == errSecSuccess && r)
        return (__bridge_transfer NSData *)r;
    return nil;
}
static void mm_lic_kc_set(NSString *acct, NSData *data)
{
    NSDictionary *q = @{ (__bridge id)kSecClass:(__bridge id)kSecClassGenericPassword,
                         (__bridge id)kSecAttrService:MM_LIC_SERVICE,
                         (__bridge id)kSecAttrAccount:acct };
    SecItemDelete((__bridge CFDictionaryRef)q);
    NSMutableDictionary *add = [q mutableCopy];
    add[(__bridge id)kSecValueData] = data;
    add[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly;
    SecItemAdd((__bridge CFDictionaryRef)add, NULL);
}

/* uuid por dispositivo guardado en Keychain: sobrevive reinstalaciones. */
static NSString *mm_lic_device_uuid(void)
{
    NSData *d = mm_lic_kc_get(@"device_uuid");
    if (d) return [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
    NSString *u = [[NSUUID UUID] UUIDString];
    mm_lic_kc_set(@"device_uuid", [u dataUsingEncoding:NSUTF8StringEncoding]);
    return u;
}
/* HWID = SHA256(identifierForVendor + uuid-keychain + sal). El cliente manda este
   mismo HWID al activar, asi que el token lo trae igual. */
static NSString *mm_lic_hwid(void)
{
    NSString *idfv = [[UIDevice currentDevice].identifierForVendor UUIDString] ?: @"nil";
    NSString *mix = [NSString stringWithFormat:@"%@|%@|fusion_hwid_v1", idfv, mm_lic_device_uuid()];
    NSData *in = [mix dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t out[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(in.bytes, (CC_LONG)in.length, out);
    NSMutableString *h = [NSMutableString string];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) [h appendFormat:@"%02x", out[i]];
    return h;
}

static NSData *mm_b64url(NSString *s)
{
    NSMutableString *m = [s mutableCopy];
    [m replaceOccurrencesOfString:@"-" withString:@"+" options:0 range:NSMakeRange(0, m.length)];
    [m replaceOccurrencesOfString:@"_" withString:@"/" options:0 range:NSMakeRange(0, m.length)];
    while (m.length % 4) [m appendString:@"="];
    return [[NSData alloc] initWithBase64EncodedString:m options:0];
}
/* un INTEGER DER a partir de un entero big-endian de 'len' bytes */
static NSData *mm_der_int(const uint8_t *b, int len)
{
    int i = 0; while (i < len - 1 && b[i] == 0) i++;     /* quita ceros a la izquierda */
    int n = len - i;
    BOOL pad = (b[i] & 0x80) != 0;                        /* bit alto -> prefijo 0x00 */
    NSMutableData *d = [NSMutableData data];
    uint8_t tag = 0x02, l = (uint8_t)(n + (pad ? 1 : 0));
    [d appendBytes:&tag length:1]; [d appendBytes:&l length:1];
    if (pad) { uint8_t z = 0; [d appendBytes:&z length:1]; }
    [d appendBytes:(b + i) length:n];
    return d;
}
/* firma r||s (64 B) -> SEQUENCE{INTEGER r, INTEGER s} (DER), que es lo que pide
   SecKeyVerifySignature para ECDSA. */
static NSData *mm_ec_rs_to_der(NSData *rs)
{
    if (rs.length != 64) return nil;
    const uint8_t *p = rs.bytes;
    NSData *rI = mm_der_int(p, 32), *sI = mm_der_int(p + 32, 32);
    NSMutableData *der = [NSMutableData data];
    uint8_t seq = 0x30, l = (uint8_t)(rI.length + sI.length);
    [der appendBytes:&seq length:1]; [der appendBytes:&l length:1];
    [der appendData:rI]; [der appendData:sI];
    return der;
}

/* verifica firma + exp + hwid; rellena g_lic_*. Devuelve YES si valida. */
static BOOL mm_lic_verify_token(NSString *token)
{
    g_lic_reason = @"sin token"; g_lic_sku = nil; g_lic_feats = nil; g_lic_exp = 0;
    if (token.length == 0) return NO;
    NSArray *parts = [token componentsSeparatedByString:@"."];
    if (parts.count != 3) { g_lic_reason = @"malformado"; return NO; }
    NSData *sig = mm_b64url(parts[2]);
    if (sig.length != 64) { g_lic_reason = @"firma no es r||s(64)"; return NO; }

    NSData *pk = [NSData dataWithBytes:MM_LIC_PUBKEY length:sizeof(MM_LIC_PUBKEY)];
    NSDictionary *attr = @{ (__bridge id)kSecAttrKeyType:(__bridge id)kSecAttrKeyTypeECSECPrimeRandom,
                            (__bridge id)kSecAttrKeyClass:(__bridge id)kSecAttrKeyClassPublic,
                            (__bridge id)kSecAttrKeySizeInBits:@256 };
    CFErrorRef err = NULL;
    SecKeyRef key = SecKeyCreateWithData((__bridge CFDataRef)pk, (__bridge CFDictionaryRef)attr, &err);
    if (!key) { g_lic_reason = @"pubkey invalida"; if (err) CFRelease(err); return NO; }
    NSData *der = mm_ec_rs_to_der(sig);
    NSString *hp = [NSString stringWithFormat:@"%@.%@", parts[0], parts[1]];
    BOOL ok = der && SecKeyVerifySignature(key, kSecKeyAlgorithmECDSASignatureMessageX962SHA256,
                                           (__bridge CFDataRef)[hp dataUsingEncoding:NSUTF8StringEncoding],
                                           (__bridge CFDataRef)der, &err);
    CFRelease(key); if (err) CFRelease(err);
    if (!ok) { g_lic_reason = @"firma invalida"; return NO; }

    NSDictionary *p = [NSJSONSerialization JSONObjectWithData:mm_b64url(parts[1]) options:0 error:nil];
    if (![p isKindOfClass:[NSDictionary class]]) { g_lic_reason = @"payload ilegible"; return NO; }
    long exp = [p[@"exp"] longValue], now = (long)time(NULL);
    g_lic_exp = exp;
    if (exp && now > exp) { g_lic_reason = @"expirada"; return NO; }
    NSString *hwid = p[@"hwid"];
    if (hwid.length && ![hwid isEqualToString:mm_lic_hwid()]) { g_lic_reason = @"hwid no coincide"; return NO; }
    g_lic_sku = p[@"sku"]; g_lic_feats = p[@"feats"]; g_lic_reason = @"valida";
    return YES;
}

/* token desde Keychain; si no, desde Documents/fusion_license.txt (para pruebas) */
static NSString *mm_lic_load_token(BOOL *fromFile)
{
    *fromFile = NO;
    NSData *d = mm_lic_kc_get(@"token");
    if (d) return [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
    NSString *docs = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *t = [NSString stringWithContentsOfFile:[docs stringByAppendingPathComponent:@"fusion_license.txt"]
                                            encoding:NSUTF8StringEncoding error:nil];
    if (t.length) { *fromFile = YES; return [t stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]; }
    return nil;
}

/* feature habilitada por la licencia ("all" o el nombre). Lista para cuando se
   active el enforce; en observacion no se consulta aun. */
static BOOL mm_lic_has_feat(NSString *feat)
{
    if (!g_lic_enforce) return YES;                 /* observacion: todo permitido */
    if (!g_lic_valid) return NO;
    if ([g_lic_feats containsObject:@"all"]) return YES;
    return [g_lic_feats containsObject:feat];
}

static void mm_lic_check(void)
{
    BOOL fromFile = NO;
    NSString *token = mm_lic_load_token(&fromFile);
    g_lic_valid = token ? mm_lic_verify_token(token) : (g_lic_reason = @"sin token", NO);
    if (g_lic_valid && fromFile)                     /* migrar el token de archivo al Keychain */
        mm_lic_kc_set(@"token", [token dataUsingEncoding:NSUTF8StringEncoding]);
    long now = (long)time(NULL);
    NSString *st = [NSString stringWithFormat:@"lic=%@ sku=%@ reason=%@ exp_dias=%ld enforce=%@",
                    g_lic_valid ? @"si" : @"no", g_lic_sku ?: @"-", g_lic_reason ?: @"-",
                    g_lic_exp ? (g_lic_exp - now) / 86400 : 0, g_lic_enforce ? @"si" : @"no"];
    NSLog(@"%s licencia: %@ (hwid=%@…)", MM_TAG, st, [mm_lic_hwid() substringToIndex:12]);
    mm_write_status([@"licencia " stringByAppendingString:st]);
    /* ENFORCE (cuando se valide en equipo): if (g_lic_enforce && !g_lic_valid)
       -> no instalar hooks / apagar feats; por ahora solo observa. */
}

__attribute__((constructor)) static void modmenu_init(void)
{
    g_t0 = [NSDate date].timeIntervalSinceReferenceDate;
    mm_reset_options();   /* v0.2.7: opciones a fabrica en cada arranque */
    NSLog(@"%s dylib cargada v%s  path=%s  pid=%d (opciones reseteadas)",
          MM_TAG, MODMENU_VERSION, mm_my_path(), (int)getpid());
    mm_write_status(@"arranque (opciones a fabrica)");
    mm_lic_check();       /* v0.3.7: licencia (observacion; migra KeyGate) */
    mm_nojb_start();      /* v0.2.8: fase C (antidetect) en segundo plano */

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{ mm_tick(); });
}
