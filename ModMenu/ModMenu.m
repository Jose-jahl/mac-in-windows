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
 *  v0.7.2 (25 oct) - QUICK BAR COMPLETA + PULIDO.
 *    - barra rapida con MASTER / CAJAS / NOMBRES / RADAR / PANIC;
 *    - kill-switch compartido entre long-press y chip PANIC.
 *
 *  v0.7.1 (25 oct) - CIERRE DE FASE 1 + REVOCACION OFFLINE.
 *    - lista de objetivos con nombre + HP y toque para resaltar la caja;
 *    - doble toque en el boton = maestro; swipe de 2 dedos en el encabezado =
 *      perfil anterior/siguiente; el toque simple sigue abriendo el panel;
 *    - dos acentos custom y 3 temas guardados (T1/T2/T3);
 *    - marca HWID opt-in en INFO (hash corto, no el HWID completo);
 *    - auto-test copiable al portapapeles;
 *    - revocacion offline: fusion_config.json firmado con "revoked": [hwid].
 *
 *  v0.7.0 (24 oct) - FASE 1 (cierre) + FASE 4 (producto) EN EL MENU.
 *    - perfiles: 5 slots con nombre, presets MP/BR/Stream/Bajo y export/import
 *      JSON por portapapeles;
 *    - guard termico (thermalState serious/critical baja el ritmo y apaga el
 *      relleno), Stream automatico si UIScreen.isCaptured y boton fantasma;
 *    - crash counter: dos arranques sucios seguidos -> modo seguro + aviso;
 *    - paleta para daltonismo y acento custom con UIColorPickerViewController;
 *    - guard de captura experimental (canvas de UITextField secureTextEntry,
 *      opt-in, con fallback a la ventana);
 *    - licencia in-menu sin red: HWID, pegar token, revalidar y estado;
 *    - INFO con chips por capa (offsets/ESP/NoJB/lic) + pack y experiment ID;
 *    - crumbs de la ultima accion y salud de la sesion en el status.
 *
 *  v0.6.4 (24 oct) - LOTE 2 DE UX + CPU DEL TEXTO.
 *    - lista de objetivos ordenada por distancia (radar/arriba = vista, flecha
 *      relativa a la camara), barra rapida de 3 toggles junto al boton, gestos
 *      (doble toque en el encabezado cierra; swipe en el selector cambia de
 *      pagina), modo seguro (apaga y bloquea el overlay), vibracion y UI ES/EN
 *      (aplica al reiniciar);
 *    - auto-test de solo lectura en MISC -> Documents/self_test.txt;
 *    - CPU: nombres/distancias/alturas cacheados por pawn (antes ~5.700
 *      NSString/s con 32 cajas), sin NSDictionary por caja en la altura ni
 *      NSUserDefaults por caja en "color por distancia"; el digest se calcula
 *      solo cuando toca pintar y cada feature tiene su ritmo (fps/telemetria
 *      4 Hz, aviso/estelas 30 Hz, panel abierto 20 Hz); FPS del medidor = ritmo
 *      real de pintado, no del display link.
 *
 *  v0.5.0 (24 oct) - FASE 2: LIMPIEZA + ESP DETRAS DE LA ESPALDA.
 *    - fuera "Marcar visibles" (Tier-2 v0.4.4): el get_isVisible del juego
 *      llamado desde el hilo del overlay CONGELABA la partida. Se elimina el
 *      toggle, el puntero y la VA del contrato: nunca mas una llamada asi;
 *    - fuera "Vida numerica" (mm_x_hpnum): el numero sobre la caja se
 *      confundia con la barra; queda solo la barra de salud;
 *    - ESP a la espalda: el radar y el contador JUG/BOT ya no dependen de la
 *      proyeccion (track mundial nuevo) y, con "Flecha fuera de pantalla",
 *      una flecha al borde senala a los que quedan detras de la camara;
 *    - opacidad del menu ARREGLADA: el latido forzaba alpha 1.0 y pisaba el
 *      slider (min 0.4); ahora respeta el valor elegido;
 *    - boton flotante: emblema dibujado (anillo neon + F de trazo redondeado
 *      con glow + arco de acento giratorio) en vez de la "F" de texto;
 *    - INFO: nota de rendimiento (activar todo no agrega riesgo de seguridad;
 *      el costo es FPS en el equipo).
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
#include <mach/task_info.h>   /* Fase 1.7: memoria residente (task_info) */
#include <mach/vm_map.h>
#include <mach/vm_region.h>
#include <mach-o/dyld.h>
#include <libkern/OSCacheControl.h>
#include <pthread.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>

#define MODMENU_VERSION     "0.14.2"
/* v0.7.0: indice del acento custom en mm_theme_accent. Debe coincidir con el
   tamano de g_mm_themes (se verifica con _Static_assert al definir la tabla). */
#define MM_THEME_CUSTOM     5
/* Clave publica ES256 del proyecto (65 B, punto sin comprimir 0x04||X||Y).
   Firma los manifiestos/pack/config y los tokens de licencia. La privada vive
   fuera del arbol distribuido (server/token.js la carga del keystore). */
static const uint8_t MM_LIC_PUBKEY[65] = {
    0x04, 0xfa, 0x3d, 0x37, 0x3f, 0xde, 0x7f, 0x46,
    0x85, 0x08, 0xa9, 0xce, 0x89, 0x5c, 0x5a, 0xe8,
    0xe9, 0x6c, 0x08, 0xf3, 0x38, 0x66, 0x4e, 0x49,
    0x92, 0xf5, 0xa9, 0xd0, 0x8d, 0xa4, 0xe8, 0xa6,
    0xaa, 0x01, 0xeb, 0xa1, 0x52, 0x82, 0xcc, 0x6b,
    0xa1, 0x55, 0xe8, 0x6e, 0x9a, 0x31, 0xa6, 0x9e,
    0x28, 0xd8, 0x33, 0x83, 0x9c, 0xac, 0x35, 0xc2,
    0x4d, 0xbb, 0xd8, 0xe3, 0x44, 0xa8, 0x59, 0x03,
    0x7d
};

/* v0.4.3 FIX: el contrato de offsets se incluye TEMPRANO (lo usa el version-gate en
   mm_esp_frame). El header tiene include-guard, asi que el 2do include mas abajo es no-op. */
#include "fusion_offsets.generated.h"
/* v0.7.0 (4.3/4.4): metadatos del pack. El generador los emite; si un header
   viejo no los trae, quedan valores honestos (version del contrato / sin ID). */
#ifndef FUSION_PACK_VERSION
#define FUSION_PACK_VERSION FUSION_OFFSETS_VERSION
#endif
#ifndef FUSION_LATEST_PACK
#define FUSION_LATEST_PACK FUSION_OFFSETS_VERSION
#endif
#ifndef FUSION_EXPERIMENT_ID
#define FUSION_EXPERIMENT_ID "exp-local"
#endif
/* 0.13: matematicas puras (w2s/distancia/box/closest-N). Se incluye TEMPRANO
   porque drawRect (mucho antes del bloque ESP) ya usa closest-N. */
#include "mm_math.h"
#define MM_TAG              "[MODMENU]"
#define MM_FAST_TRIES       120             /* 120 x 0.5 s = 60 s rapidos  */
#define MM_FAST_LOG_EVERY   20              /* log de espera cada 10 s     */
#define MM_SLOW_SECS        5               /* luego un latido cada 5 s    */
/* v0.8.0: panel horizontal CLOUD. 640x356 entra completo en un iPhone
   moderno en landscape y conserva una jerarquia de tres columnas. */
#define MM_PANEL_W          640.0
#define MM_PANEL_H          356.0
#define MM_CLOUD_PAD         18.0
#define MM_CLOUD_NAV_Y       72.0
#define MM_CLOUD_BODY_Y     126.0
#define MM_CLOUD_BODY_H     214.0
#define MM_CLOUD_CARD_W     192.0
#define MM_CLOUD_CARD_GAP    14.0
#define MM_CLOUD_CARD_INNER  14.0
#define MM_CLOUD_ROW_H       28.0
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
const char *modmenu_build_id = "modmenu-glass-0.14.2";

/* Fase C (ADR 0008): aim configurable via relay en cod.__DATA.
   El pack reemplaza el parche fijo del aim (0x1026FEC24) por un relay:
     adrp x8,#0x10dc63000 ; ldr s0,[x8,#0x9ec] ; ret
   es decir, GetAssitAimSpeed devuelve el float que vive en cod_base+0xDC639EC.
   Aca escribimos ese float (fuerza de aim, 0..28). Si la dylib no lo escribio
   todavia, el slot vale 0 -> aim apagado (fail-safe, nunca maximo). */
static float g_aim_strength = 28.0f;
static float g_aim_fov = 90.0f;    /* 0.14.1: cono +-45; 180 dejaba enganchar a 85 grados */
static float g_aim_smooth = 0.0f;   /* C-4: 0 = snap, 1 = suave */
/* 0.14.2: diagnostico del aimlock.
   g_lock_last  = lo que escribimos el frame anterior.
   g_lock_diag  = [0] frames en que la escritura sobrevivio hasta el frame siguiente,
                  [1] frames en que el juego la piso antes. */
static float g_lock_last[4] = { 0.0f, 0.0f, 0.0f, 1.0f };
static int   g_lock_last_ok = 0;
static long  g_lock_diag[2] = { 0, 0 };
static BOOL g_lock_on = NO;
static BOOL g_lock_rifle = YES, g_lock_smg = YES, g_lock_shotgun = YES, g_lock_sniper = YES;
static BOOL g_lock_ads  = NO;    /* 0.9.3: lock solo mientras apunta (mas discreto) */
static float mm_def_float(NSString *k, float d);   /* forward (0.9.4) */
static float g_aim_height = 0.0f;   /* 0.9.9: offset vertical DESDE LA CABEZA (0 = cabeza) */
static BOOL  g_aim_on = NO;   /* 0.10.2: default OFF (el relay necesita re-aplicarse) */
static BOOL  g_aim_key_mode = NO;   /* C-3: aim solo mientras se mantiene el boton AIM */
static BOOL  g_aim_key_held = NO;
static void mm_aim_apply(void)
{
    const struct mach_header *h = _dyld_get_image_header(0);
    if (h == NULL) return;
    /* strength +0xEC, FOV +0xF0, gate +0xF4, cur +0xF8 (lo escribe el relay), alpha +0xFC */
    *(float *)((uintptr_t)h + (uintptr_t)0x0DC639ECULL) = g_aim_on ? g_aim_strength : 0.0f;
    *(float *)((uintptr_t)h + (uintptr_t)0x0DC639F0ULL) = g_aim_fov;
    *(int   *)((uintptr_t)h + (uintptr_t)0x0DC639F4ULL) =
        (g_aim_key_mode && !g_aim_key_held) ? 0 : 1;   /* 0.9.5: el asist nunca se apaga */
    *(float *)((uintptr_t)h + (uintptr_t)0x0DC639FCULL) = 1.0f - g_aim_smooth * 0.98f;
}

static BOOL mm_def_bool(NSString *k, BOOL d);   /* forward: lo usa mm_reload_apply */

/* 0.9.1: AIM LOCK — seguir al enemigo sin apuntar, con sub-opciones por tipo de
   arma (por defecto solo franco y escopeta, que es donde mas se usa). */
static void mm_lock_opts_sync(void)
{
    g_lock_on      = mm_def_bool(@"mm_x_aimlock", NO);
    g_lock_rifle   = mm_def_bool(@"mm_lock_rifle", YES);
    g_lock_smg     = mm_def_bool(@"mm_lock_smg", YES);
    g_lock_shotgun = mm_def_bool(@"mm_lock_shotgun", YES);
    g_lock_sniper  = mm_def_bool(@"mm_lock_sniper", YES);
    g_aim_height   = mm_def_float(@"mm_aim_height", 0.0f);
    g_lock_ads     = mm_def_bool(@"mm_lock_ads", NO);
}

/* C-18: recarga rapida toggleable. El relay de GetChangeClipTime lee el slot
   cod_base+0xDC63A04; aca se escribe 0.125 s (ON) o 3.0 s (OFF). */
static void mm_reload_apply(void)
{
    const struct mach_header *h = _dyld_get_image_header(0);
    if (h == NULL) return;
    BOOL on = mm_def_bool(@"mm_x_fast_reload", NO);
    *(float *)((uintptr_t)h + (uintptr_t)0x0DC63A04ULL) = on ? 0.125f : 3.0f;
}

/* --- objetos de UI (globales, creados una sola vez) --- */
static UIView   *g_root  = nil;   /* capa transparente sobre la ventana juego */
static UIButton *g_btn   = nil;   /* boton flotante                           */
static UIButton *g_aimkey_btn = nil; /* C-3: boton AIM (mantener) flotante    */
@class MMBtnGlyph;                /* v0.5.0: emblema dibujado del boton       */
static MMBtnGlyph *g_btn_glyph = nil;
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
static UISegmentedControl *g_seg = nil;  /* v0.8.0: backing oculto de la nav */
static NSMutableArray *g_nav_btns = nil; /* v0.8.0: botones horizontales */
static UILabel  *g_status_strip = nil;  /* v0.8.0: HUD vivo del encabezado */
static UILabel  *g_marca  = nil;  /* marca de agua v0.2.4 (identidad) */
static UIView   *g_p_esp  = nil;
static UIView   *g_p_vis  = nil;  /* v0.3.0: Stream Mode + pulido ESP */
static UIView   *g_p_aim  = nil;
static UIView   *g_p_misc = nil;
static UIButton *g_dbgbtn = nil;  /* v0.6.1: Debug como boton de fila completa */
static UIView   *g_p_info = nil;
static UIView   *g_p_more = nil;  /* v0.4.0: pagina EXTRA (features nuevas)    */
static UILabel  *g_info   = nil;  /* texto vivo de la pagina INFO             */
static UIScrollView *g_info_scroll = nil; /* v0.8.0: INFO en tarjeta scrolleable */
static UILabel  *g_range_val = nil;
static UILabel  *g_maxn_val  = nil;
static NSMutableArray *g_sub_switches = nil;  /* switches bajo el maestro    */
/* v0.6.4: barra rapida flotante (3 toggles) junto al boton. */
static UIView   *g_quickbar = nil;
static NSMutableArray *g_quick_btns = nil;
static NSArray  *g_quick_keys = nil;

static const char *g_via   = "-";     /* donde quedo colgada la UI        */
static BOOL  g_panel_open  = NO;
static BOOL  g_panic       = NO;  /* v0.4.0 #8: kill-switch (long-press boton)  */
static int   g_profile_slot = 0;  /* v0.4.0 #7: slot de perfil seleccionado     */
static UISegmentedControl *g_profile_seg = nil;  /* v0.7.0: sincroniza swipe */
static int   g_theme_slot = 0;    /* v0.7.0: slot de tema guardado              */
static int   g_accent_slot = 0;   /* v0.7.0: 0 = acento 1, 1 = acento 2        */
static CGPoint g_panel_drag0;         /* v0.2.4: inicio de arrastre panel */
static int   g_tries       = 0;
static NSTimeInterval g_t0 = 0;
static BOOL  g_ui_ok       = NO;      /* UIApplication ya es segura       */

/* =========================================================================
   v0.8.1 — HARDENING (Fase A)
   -------------------------------------------------------------------------
   Bloque defensivo que no agrega features al usuario pero endurece el mod
   contra: debugger attach casual, exposicion via screen record/stream,
   screenshot del Control Center, y strings leakeadas por `strings` sobre
   el .ipa (infra XOR para uso futuro).

   NO cambia la arquitectura carrier (sigue siendo swap de MSDKPolicy),
   NO agrega load commands, NO toca NSUserDefaults existentes.
   Posicion: DESPUES de los globales de UI porque referencia g_panel/g_btn.
   ========================================================================= */

/* A.1 — anti-debug. Direct syscall arm64 de ptrace(PT_DENY_ATTACH, 0, 0, 0)
   sin pasar por libc; evita hooks sobre libSystem.ptrace que detectan la
   llamada "clasica". syscall 26 = ptrace, flag 31 = PT_DENY_ATTACH. */
static void mm_antidebug(void)
{
#if defined(__arm64__) || defined(__aarch64__)
    __asm__ volatile(
        "mov x0, #31\n"
        "mov x1, #0\n"
        "mov x2, #0\n"
        "mov x3, #0\n"
        "mov x16, #26\n"
        "svc 0x80\n"
        : : : "x0", "x1", "x2", "x3", "x16", "memory"
    );
#endif
}

/* A.2 — panic mode. El polling en mm_tick ya actualiza g_captured a 4 Hz;
   aca registramos observer para reaccion inmediata (frame siguiente) al
   evento de captura/stream, y ocultamos g_panel + g_btn mientras dure.
   Al terminar la captura, restauramos el boton; el panel queda cerrado
   (el usuario lo re-abre con el boton flotante, deliberado). */
static BOOL g_hardening_hid_panel = NO;

static void mm_apply_capture_hide(void)
{
    BOOL captured = NO;
    if (@available(iOS 11.0, *)) {
        captured = UIScreen.mainScreen.isCaptured;
    }
    if (captured) {
        if (g_panel != nil && !g_panel.hidden) {
            g_panel.hidden = YES;
            g_hardening_hid_panel = YES;
        }
        if (g_btn != nil) g_btn.alpha = 0.0;
    } else {
        if (g_btn != nil) g_btn.alpha = 1.0;
        g_hardening_hid_panel = NO;
    }
}

/* A.5 — hide del panel cuando la app va a background (screenshot del
   Control Center / App Switcher). Al volver, el panel queda cerrado:
   el usuario lo abre a mano con el boton (consistente con panic mode). */
static void mm_apply_background_hide(void)
{
    if (g_panel != nil && !g_panel.hidden) {
        g_panel.hidden = YES;
    }
}

static void mm_register_hardening_observers(void)
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    NSOperationQueue *mq = [NSOperationQueue mainQueue];
    if (@available(iOS 11.0, *)) {
        [nc addObserverForName:UIScreenCapturedDidChangeNotification
                        object:nil
                         queue:mq
                    usingBlock:^(NSNotification *n) { mm_apply_capture_hide(); }];
    }
    [nc addObserverForName:UIApplicationWillResignActiveNotification
                    object:nil
                     queue:mq
                usingBlock:^(NSNotification *n) { mm_apply_background_hide(); }];
    [nc addObserverForName:UIApplicationDidBecomeActiveNotification
                    object:nil
                     queue:mq
                usingBlock:^(NSNotification *n) { mm_apply_capture_hide(); }];
}

/* A.3 — infra XOR para strings sensibles. NO se aplica a NSUserDefaults
   keys existentes (romperia la persistencia del usuario); queda listo
   para strings nuevos (ej. nombres de metodo IL2CPP cuando metamos Dobby).
   Uso:
     static const uint8_t K_HELLO[] = { 0x32, 0x3f, 0x36, 0x36, 0x35 }; // "hello"^0x5A
     char buf[sizeof(K_HELLO)+1];
     mm_xor_decrypt(0x5A, K_HELLO, sizeof(K_HELLO), buf);
*/
#define MM_XOR_DEFAULT_KEY 0x5A
static inline void mm_xor_decrypt(uint8_t key, const uint8_t *src, size_t n, char *dst)
{
    for (size_t i = 0; i < n; i++) dst[i] = (char)(src[i] ^ key);
    dst[n] = '\0';
}

/* =========================================================================
   FIN v0.8.1 HARDENING
   ========================================================================= */

/* =========================================================================
   v0.8.2 — DOBBY INTEGRATION (Fase B.2 + B.3)
   -------------------------------------------------------------------------
   Gated por MM_USE_DOBBY (compile flag inyectado por el workflow CI cuando
   el input enable_dobby=true). Cuando NO esta definido, mm_dobby_init es
   un no-op y la dylib compila sin libdobby.a (comportamiento = v0.8.1).

   Cuando esta definido:
   - include dobby.h (del submodulo clonado por el workflow)
   - B.3 smoke test: hook de getpid() libc para validar pipeline end-to-end
   - log "DOBBY_HOOK_OK: getpid hooked" al mm_write_status la primera vez
     que algo llama getpid tras el init (si el log aparece en Documents/
     modmenu_status.txt del equipo de prueba, Dobby funciona)

   Esto NO cambia comportamiento del juego: solo prueba que el pipeline
   compile + link + inject + hook funciona. Features reales (god mode,
   silent aim, etc.) vienen en Fase C basadas en este cimiento.
   ========================================================================= */
#if defined(MM_USE_DOBBY) && MM_USE_DOBBY
#include "dobby.h"
#include <sys/types.h>

/* Forward decl: mm_write_status se define mas abajo (linea ~5470).
   El bloque Dobby ocurre antes para que mm_dobby_init este visible al
   constructor. */
static void mm_write_status(NSString *nota);

static pid_t (*mm_orig_getpid)(void) = NULL;
static BOOL  g_dobby_hit = NO;

static pid_t mm_hooked_getpid(void)
{
    pid_t p = mm_orig_getpid ? mm_orig_getpid() : (pid_t)-1;
    if (!g_dobby_hit) {
        g_dobby_hit = YES;
        /* mm_write_status se define mas abajo; llamada diferida al primer
           invocacion de getpid tras el init del constructor. */
        mm_write_status(@"DOBBY_HOOK_OK: getpid hooked (B.3 smoke test)");
    }
    return p;
}

static void mm_dobby_init(void)
{
    void *target = dlsym(RTLD_DEFAULT, "getpid");
    if (target == NULL) {
        mm_write_status(@"DOBBY: dlsym(getpid) == NULL, hook skip");
        return;
    }
    int rv = DobbyHook(target, (void *)mm_hooked_getpid, (void **)&mm_orig_getpid);
    mm_write_status([NSString stringWithFormat:@"DOBBY: init rv=%d target=%p",
                     rv, target]);
}
#else
static inline void mm_dobby_init(void) { /* no-op cuando MM_USE_DOBBY=0 */ }
#endif

/* --- ESP: lienzo + cajas + sonda --- */
#define MM_MAX_BOXES 32
/* C-5: Transform.Find / Transform.get_position (dump 1.0.57, verificados) */
#ifndef VA_TRFIND
#define VA_TRFIND 0x108C65B98ULL
#endif
#ifndef VA_TRPOS
#define VA_TRPOS  0x108C3C41CULL
#endif
/* C-5: Pawn.m_ModelRoot (Transform del modelo) — dump 1.0.57 */
#ifndef OFF_PAWN_MODELROOT
#define OFF_PAWN_MODELROOT 0x630ULL
#endif
/* C-5b: Pawn.m_Mesh (Transform del mesh) - segundo candidato de raiz */
#ifndef OFF_PAWN_MESH
#define OFF_PAWN_MESH 0x628ULL
#endif
/* C-19: PlayerInfo.m_ReviveTime -> >0 = caido (dump 1.0.57) */
#ifndef OFF_ENT_REVIVE
#define OFF_ENT_REVIVE 0x5B4ULL
#endif
/* C-7: Camera.set_fieldOfView (dump 1.0.57) */
#ifndef VA_CAM_SETFOV
#define VA_CAM_SETFOV 0x108BD9890ULL
#endif
/* C-11: Camera.get_fieldOfView (para el circulo de FOV) */
#ifndef VA_CAM_GETFOV
#define VA_CAM_GETFOV 0x108BD9868ULL
#endif
/* C-15: Object.get_name / Transform.get_childCount / GetChild */
#ifndef VA_GETNAME
#define VA_GETNAME 0x108C0CCA8ULL
#endif
#ifndef VA_CHILDCOUNT
#define VA_CHILDCOUNT 0x108C3C954ULL
#endif
#ifndef VA_GETCHILD
#define VA_GETCHILD 0x108C3C924ULL
#endif
/* 0.7: ventana contigua del pawn que cubre alive/transform/entity. Se lee de
   una sola pasada (con fallback a lecturas individuales si el rango falla). */
#define MM_PAWN_BLOCK_BASE (OFF_PAWN_TRANSFORM & ~0xFFULL)
#define MM_PAWN_BLOCK_SIZE (OFF_PAWN_ENTITY + 8 - MM_PAWN_BLOCK_BASE)
typedef struct {
    uint64_t pawn;              /* v0.2.4: dueno de la caja (estabilidad) */
    CGFloat x, y, w, h;
    float   dist;
    float   wx, wy, wz;         /* v0.4.4: posicion mundial (radar 2D / altura) */
    float   hp;                 /* v0.2.4: salud actual (-1 = sin dato) */
    float   hpMax;              /* v0.2.4: salud maxima (100 por defecto)*/
    int     robot;
    int     alive;
    int     hasName;            /* v0.2.4: 1 si name trae nombre real   */
    int     downed;             /* C-19: 1 si esta caido (revive)       */
    uint32_t tags;              /* 2026-11: 1 curando, 2 invisible, 4 vehiculo, 8 ADS */
    int     ammo;               /* 2026-11: balas en el cargador (-1 = sin dato) */
    int     ammoMax;            /* 2026-11: cargador maximo (0 = sin dato) */
    int     armor;              /* 2026-11: m_KineticArmorHP (0 = sin armadura) */
    float   vx, vy, vz;         /* 0.9.3: velocidad estimada (m/s) para prediccion */
    char    name[64];           /* v0.2.4: nombre UTF-8 del jugador     */
} MMEspBox;
static MMEspBox     g_boxes[MM_MAX_BOXES];
static int          g_box_count = 0;  /* cajas listas para pintar         */

/* 0.8.8: muestra de lo que devuelven los lectores nuevos (equipo / estado /
   municion) por caja. La escribe mm_esp_read_diag() en Documents cuando alguno
   de los tres toggles esta encendido. Sirve para ver donde se corta la cadena
   sin adivinar. */
typedef struct {
    unsigned long long pawn, ent;
    uint32_t team;
    int armor, invis, healing, veh;
    int ammo, ammoMax, ads;
    int invOk, wepOk, flOk, fcount, ownerOk;
} MMEspRead;
#define MM_ESPREAD_N 8
static MMEspRead    g_read[MM_ESPREAD_N];
static int          g_read_n = 0;
static uint32_t     g_team_local = 0;

typedef void *(*MMFindFn)(void *transform, void *nsstring);
typedef void  (*MMPosFn)(void *transform, float out[3]);
static MMFindFn     g_fp_find  = NULL;
static MMPosFn      g_fp_trpos = NULL;
typedef void (*MMSetFovFn)(void *cam, float v);
static MMSetFovFn   g_fp_cam_setfov = NULL;
/* 0.9.1: aim lock (seguir sin apuntar) — transform de la camara + rotacion. */
typedef void *(*MMCompTransFn)(void *component);
typedef void  (*MMSetRotFn)(void *transform, float q[4]);
typedef void  (*MMGetRotFn)(void *transform, float q[4]);
static MMCompTransFn g_fp_gettrans = NULL;
static MMSetRotFn    g_fp_setrot   = NULL;
static MMGetRotFn    g_fp_getrot   = NULL;

/* 0.9.7: silent aim — Pawn.set_AimRotation(Quaternion) (HFA s0..s3). Es el mismo
   camino que usa el mod de referencia (SP3CTERIOS): no escribe el campo, llama
   al setter del juego. */
typedef struct { float x, y, z, w; } MMQuat;
typedef void   (*MMSetAimRotFn)(void *pawn, MMQuat q);
typedef MMQuat (*MMGetAimRotFn)(void *pawn);
static MMSetAimRotFn g_fp_setaimrot = NULL;
static MMGetAimRotFn g_fp_getaimrot = NULL;

/* ===== 0.13.0: AIM LOCK POR DETOUR DEL GETTER ============================
   El juego reescribe la rotacion de aim desde el input en cada frame, asi que
   escribir la camara o el campo del pawn por timer SIEMPRE llega tarde. Lo que
   manda es escribir la rotacion calculada directamente en OFF_PAWN_AIMROT
   del pawn local, cada frame (CADisplayLink 60 Hz). No se toca codigo
   ejecutable: solo datos en heap — compatible con firma de codigo iOS.
   Con el lock apagado no se escribe nada; el campo queda intacto. */
static volatile int g_lock_active = 0;
static volatile uint64_t g_lock_pawn = 0;
static volatile long g_lock_frames = 0;
#define MM_AIM_LOCK_UP 1.15f   /* metros sobre la posicion del pawn (pecho) */
typedef float (*MMGetFovFn)(void *cam);
static MMGetFovFn   g_fp_cam_getfov = NULL;   /* C-11 */
typedef void *(*MMStrFn)(void *obj);
typedef int   (*MMIntFn1)(void *obj);
typedef void *(*MMObjIntFn)(void *obj, int i);
static MMStrFn      g_fp_getname = NULL;      /* C-15 */
static MMIntFn1     g_fp_childcount = NULL;
static MMObjIntFn   g_fp_getchild = NULL;
static float        g_cam_fov = 0.0f;   /* C-7: 0 = no tocar */
static void *(*g_fov_cam_get)(void) = NULL;   /* C-7: get_main (se setea en esp_try) */
/* v0.5.0: TRACK MUNDIAL, independiente de la proyeccion. Un enemigo detras
   de la camara no se puede proyectar (no hay caja), pero SI esta en el mundo:
   el radar, el contador JUG/BOT y la flecha "detras de ti" salen de aca. */
#define MM_MAX_TRACKS 64
typedef struct {
    uint64_t pawn;      /* v0.7.0: enlace con la caja (nombre/HP en la lista) */
    float wx, wy, wz;   /* posicion mundial del pawn                    */
    float dist;         /* distancia al jugador local (m)               */
    float vx, vy;       /* coords en espacio de camara (dir. si detras) */
    float sx, sy;       /* proyeccion cruda (aunque caiga fuera)        */
    int   robot;
    int   alive;
    int   downed;       /* C-19: caido */
    int   proj;         /* 1 = tiene caja dibujable en g_boxes          */
    int   behind;       /* 1 = detras de la camara (no proyectable)     */
    int   has_sx;       /* 1 = la proyeccion dio un punto (aunque fuera)*/
} MMTrack;
static MMTrack      g_tracks[MM_MAX_TRACKS];
static int          g_track_count = 0;

/* v0.7.3 (perf): contador de version de escena. Lo bumpean los productores
   (colector, lector BR, invalidador de opts, panic/safe/thermal). Reemplaza al
   hash FNV sobre arrays enteros en el skip de pintado: en gameplay la view
   matrix cambia cada frame del juego y el hash NUNCA ahorraba repintados;
   peor, hashear g_boxes/g_tracks por frame era trabajo gratis. Con este
   contador el skip es O(1) y la decision de repintar sigue siendo correcta. */
static volatile unsigned long long g_scene_ver = 1ULL;
static inline void mm_scene_bump(void) { g_scene_ver++; }

/* v0.7.0 (1.2): lista de objetivos interactiva. La fila tocada resalta la
   caja del pawn; el area de toque es SOLO el rectangulo de la lista y solo
   cuando la lista esta visible (el resto del overlay sigue dejando pasar). */
#define MM_TL_ROWS     6
#define MM_TL_BOX_X    6.0
#define MM_TL_BOX_Y    92.0
#define MM_TL_BOX_W    148.0
#define MM_TL_ROW_Y    110.0
#define MM_TL_ROW_H    14.0
static uint64_t     g_tl_sel_pawn = 0;
static double       g_tl_sel_t = 0.0;

/* Orden por distancia de los tracks vivos (mismo criterio que el dibujo). */
static int mm_tl_order(int *idx, int max)
{
    int n = 0;
    for (int k = 0; k < max; k++) {
        int best = -1; float bd = 1.0e9f;
        for (int i = 0; i < g_track_count && i < MM_MAX_TRACKS; i++) {
            if (!g_tracks[i].alive) continue;
            BOOL used = NO;
            for (int q = 0; q < n; q++) if (idx[q] == i) { used = YES; break; }
            if (used) continue;
            if (g_tracks[i].dist < bd) { bd = g_tracks[i].dist; best = i; }
        }
        if (best < 0) break;
        idx[n++] = best;
    }
    return n;
}

/* v0.6.4: cache de los NSString que drawRect usa por caja (nombre, distancia y
   altura). Antes cada frame creaba hasta 3 NSString por enemigo; con 32 cajas a
   60 fps eran ~5.700 allocaciones/s. Las distancias/alturas se comparten por
   valor entero (solo hay ~500 y ~200 variantes) y los nombres se guardan por
   pawn; si el nombre cambia, se reemplaza. */
static NSMutableDictionary *g_cache_dist = nil;
static NSMutableDictionary *g_cache_hgt = nil;
static NSMutableDictionary *g_cache_name = nil;
static NSString *mm_cached_dist(int m)
{
    if (g_cache_dist == nil) g_cache_dist = [NSMutableDictionary dictionary];
    NSNumber *k = @(m);
    NSString *s = g_cache_dist[k];
    if (s == nil) {
        s = [NSString stringWithFormat:@"%d m", m];
        if (g_cache_dist.count > 512) [g_cache_dist removeAllObjects];
        g_cache_dist[k] = s;
    }
    return s;
}
static NSString *mm_cached_hgt(int m)
{
    if (g_cache_hgt == nil) g_cache_hgt = [NSMutableDictionary dictionary];
    NSNumber *k = @(m);
    NSString *s = g_cache_hgt[k];
    if (s == nil) {
        s = [NSString stringWithFormat:(m >= 0 ? @"\u25B2%dm" : @"\u25BC%dm"),
                                      (m >= 0 ? m : -m)];
        if (g_cache_hgt.count > 256) [g_cache_hgt removeAllObjects];
        g_cache_hgt[k] = s;
    }
    return s;
}
static NSString *mm_cached_name(uint64_t pawn, const char *nm)
{
    if (g_cache_name == nil) g_cache_name = [NSMutableDictionary dictionary];
    NSNumber *k = @(pawn);
    NSString *cur = g_cache_name[k];
    if (cur != nil && nm != NULL && strcmp(cur.UTF8String ?: "", nm) == 0) return cur;
    NSString *s = (nm != NULL) ? [NSString stringWithUTF8String:nm] : nil;
    if (s.length == 0) return nil;
    if (g_cache_name.count > 128) [g_cache_name removeAllObjects];
    g_cache_name[k] = s;
    return s;
}
/* 2026-11: etiqueta de estado/municion por caja. La clave empaqueta la mascara
   (5 bits) y los dos enteros de municion, asi que no hay alloc por frame. */
static NSMutableDictionary *g_cache_tags = nil;
static NSString *mm_cached_tags(uint32_t mask, int ammo, int ammoMax, int armor)
{
    int a = (ammo >= 0 && ammo < 4095) ? ammo : 4095;
    int m = (ammoMax > 0 && ammoMax < 4095) ? ammoMax : 0;
    int ar = (armor > 0 && armor < 4095) ? armor : 0;
    unsigned long long key = ((unsigned long long)(mask & 0x1F) << 48) |
                             ((unsigned long long)ar << 36) |
                             ((unsigned long long)a << 12) |
                             (unsigned long long)m;
    if (g_cache_tags == nil) g_cache_tags = [NSMutableDictionary dictionary];
    NSNumber *k = @(key);
    NSString *s = g_cache_tags[k];
    if (s != nil) return s;
    NSMutableString *t = [NSMutableString string];
    if (mask & 1) [t appendString:@"CUR "];
    if (mask & 2) [t appendString:@"INV "];
    if (mask & 4) [t appendString:@"VEH "];
    if (mask & 8) [t appendString:@"ADS "];
    if (ar > 0) [t appendFormat:@"A%d ", ar];
    if (m > 0) [t appendFormat:@"%d/%d", a, m];
    s = [t copy];
    if (g_cache_tags.count > 512) [g_cache_tags removeAllObjects];
    g_cache_tags[k] = s;
    return s;
}

/* Fase 1.5: estelas "last seen" en espacio de MUNDO. Cada pawn conserva
   hasta 14 muestras (~2 s a 0.15 s); se proyectan al dibujar para que no se
   deformen cuando gira la camara. No hay lecturas nuevas: se alimentan de
   las cajas ya calculadas por el colector. */
#define MM_MAX_TRAILS  32
#define MM_TRAIL_PTS   14
#define MM_TRAIL_SAMPLE 0.15
#define MM_TRAIL_LIFE   2.0
typedef struct { float x, y, z; double t; } MMTrailPt;
typedef struct {
    uint64_t  pawn;
    int       robot;
    int       n;
    MMTrailPt p[MM_TRAIL_PTS];
} MMTrail;
static MMTrail      g_trails[MM_MAX_TRAILS];

/* v0.6.3: zona BR leida del manager del juego. Inerte hasta que el contrato
   traiga offsets verificados (BR_STRUCT_* != 0). Solo se dibuja en el radar. */
typedef struct {
    int    ok;
    float  x, y, z;      /* centro actual (mundo)   */
    float  r;            /* radio actual (m)        */
    double t;            /* ultima lectura          */
    float  nextS;      /* C-6: segundos para el proximo cierre */
    float  progress;   /* C-6: 0..1 avance del cierre actual  */
    int    cur, total; /* C-6: cierre actual / total          */
} MMBrZone;
static MMBrZone     g_br_zone;
static NSString    *g_br_zone_info = nil;

/* v0.4.4: datos para radar 2D / altura / telemetria (se llenan en el colector) */
static float        g_local_pos[3] = { 0.0f, 0.0f, 0.0f };
static int          g_have_local = 0;
static float        g_view_mtx[16];
static int          g_have_view = 0;
static float        g_proj_mtx[16];      /* Fase 1.5: proyeccion de estelas/FOV   */
static int          g_have_proj = 0;
static float        g_fov_deg = 60.0f;
static double       g_collect_ms = 0.0;
static int          g_count_players = 0; /* v0.3.0: dibujados por tipo     */
static int          g_count_bots = 0;
/* Fase 1.7: lecturas vm y memoria residente para el HUD de telemetria. */
static uint64_t     g_vm_reads = 0;      /* total acumulado (mm_vm_read + sonda) */
static double       g_reads_per_s = 0.0; /* ventana de 1 s                        */
static double       g_mem_mb = 0.0;      /* residente del proceso                 */
static UIView      *g_esp   = nil;    /* lienzo MMCanvasView              */
static CADisplayLink *g_link = nil;   /* latido de dibujo ~30 fps         */
static NSString    *g_probe = nil;    /* texto de la sonda (fase B)       */
static int          g_probe_ok = -1;  /* -1 pendiente / 0 revisar / 1 ok  */
static NSString    *g_br_probe = nil; /* BR probe (prologo decodificado)  */
static int          g_br_probe_got_inst = 0;   /* 0.7.5: 1 si la ultima pasada capturo instancia != 0 */
static int          g_br_probe_saw_diff = 0;   /* 0.7.8: 1 si alguna pasada vio diff != none (shrink activo) */
static int          g_br_probe_found_vec3 = 0; /* 0.7.8: 1 si el scan de Vec3 encontro al menos un candidato valido */
static double       g_br_probe_last_run = 0.0; /* 0.7.5: ts (segundos de uptime) de la ultima pasada */
/* v0.7.11: fn del pawn local. El colector ESP lo setea cuando resuelve
   el fieldOfView/WorldToScreen table (via el bootstrap de probe). El
   probe BR lo lee para dumpear el pawn + walk de sus punteros, buscando
   la referencia a GameMode/Match -> SafeZone. Cero riesgo nuevo: la fn
   ya se llama desde el colector en gameplay. */

/* v0.7.0 - Fase 1.11/1.12/1.13/4.5: salud del equipo, arranque sucio y crumbs.
   Todo es estado local; nada de red, nada de llamadas al juego. */
static int   g_thermal_level = 0;          /* 0 nominal .. 3 critical */
static int   g_captured = 0;               /* pantalla capturada (record/stream) */
static int   g_dirty_boots = 0;            /* arranques sin cierre limpio */
static int   g_boot_forced = 0;            /* modo seguro forzado por crash counter */
static int   g_boot_alerted = 0;
static char  g_last_action[48] = "boot";   /* ultima feature tocada (4.5) */
static NSString *g_lic_status_label = nil; /* 4.2: estado de licencia en MISC */
static UILabel  *g_lic_label = nil;
static UILabel  *g_profile_name_label = nil;
static UIView   *g_secure_host = nil;      /* 1.15: contenedor seguro (opt-in) */
static UIView   *g_secure_canvas = nil;
static int       g_secure_canvas_state = -1; /* -1 sin probar / 0 sin canvas / 1 ok */
static int       g_cb_mode = 0;            /* 1.16: paleta daltonismo */
/* 4.1: remote config firmado (archivo local; sin red). */
static int       g_cfg_loaded = 0;
static int       g_cfg_valid = 0;
static NSSet    *g_cfg_disabled = nil;
static NSSet    *g_cfg_revoked = nil;   /* 4.2: HWIDs revocados por config firmado */
static NSString *g_cfg_latest = nil;
static NSString *g_cfg_error = nil;

/* prototipos */
static void mm_tick(void);
static void mm_set_panel(BOOL open);
static void mm_position_panel(void);
static CGFloat mm_menu_total_scale(CGRect host);
static void mm_apply_esp_lock(void);
static void mm_apply_stream(void);
static void mm_refresh_info(void);
static void mm_write_status(NSString *nota);
static void mm_refresh_debug_button(void);
static void mm_refresh_quickbar(void);
static void mm_layout_quickbar(void);
static void mm_sync_switches(UIView *root);
static void mm_apply_safe_mode(void);
static void mm_toggle_panic(void);
static void mm_haptic(int style);
static void mm_self_test(void);
static NSString *mm_docs_dir(void);
static BOOL mm_def_bool(NSString *k, BOOL d);
static float mm_def_float(NSString *k, float d);
static int mm_lang(void);
static NSString *mm_tr(NSString *es);
static void mm_esp_frame(double t);
static void mm_profile_save(int slot);   /* v0.4.0 #7: perfiles de config */
static BOOL mm_profile_load(int slot);
static NSString *mm_profile_name(int slot);
static void mm_profile_set_name(int slot, NSString *name);
static void mm_profile_apply_preset(int which);
static void mm_profile_export(void);
static void mm_profile_import(void);
static BOOL mm_place_ui(void);
static void mm_esp_collect_real(void);
static BOOL mm_w2s(const float *view, const float *proj, const float p[3],
                   BOOL cabeza, CGFloat W, CGFloat H, CGPoint *out,
                   int *detras, float *vxo, float *vyo);   /* Fase 1.5: estelas */
static void mm_probe_run(void);
static void mm_reload_apply(void);     /* C-18: slot de recarga rapida */
static void mm_layout_count_glass(void);
static void mm_refresh_count_glass(void);
static void mm_reload_diag(void);      /* 0.8.4: sonda del estado de recarga */
static void mm_esp_read_diag(void);    /* 0.8.8: sonda de las lecturas nuevas */
static void mm_aim_lock(void);          /* 0.9.1: aim lock (seguir sin apuntar) */
static void mm_lock_opts_sync(void);   /* 0.9.1: opciones del aim lock */
static void mm_mark_action(const char *a);
static void mm_boot_check(void);
static void mm_health_update(void);
static BOOL mm_stream_effective(void);
static UIViewController *mm_top_vc(void);
static NSString *mm_lic_hwid(void);
static BOOL mm_lic_verify_token(NSString *token);
static void mm_lic_save_token(NSString *token);
static void mm_lic_check(void);
static void mm_refresh_license_label(void);
static NSString *mm_lic_short_status(void);
static BOOL mm_lic_is_valid(void);
static NSString *mm_build_mark(void);
static void mm_refresh_info(void);
static UIWindow *mm_host_window(void);

/* v0.2.9: fase D (guest reset) */
static void mm_guest_reset_prompt(void);
static void mm_show_alert(NSString *titulo, NSString *msg);

/* 0.8: el syslog tambien es evidencia forense. Solo se emite con el modo
   debug ON (misma clave mm_debug que habilita modmenu_status.txt). Default
   OFF; el operador lo prende en MISC para diagnosticar. */
#define MM_LOG(...) do { if (mm_def_bool(@"mm_debug", NO)) NSLog(__VA_ARGS__); } while (0)

/* 0.7: snapshot de las opciones que drawRect/colector leen por frame. Evita
   decenas de lookups a NSUserDefaults a 30-60 fps. Se invalida desde cada
   control que cambia una opcion y al cargar/resetear un perfil. */
typedef struct {
    BOOL box, name, dist, lines, linesTop, health, fill;
    BOOL cross, aimring, fps, head, distcol, lowhp;
    BOOL priority, warn, arrow, radar, height, telem;
    BOOL bearings, trails, declutter;   /* Fase 1: brujula / estelas / anti-solape */
    BOOL radarCam;                      /* Fase 1.1: radar camara-arriba */
    BOOL targetList;                    /* v0.6.4: lista de objetivos por distancia */
    BOOL players, bots;
    BOOL master, safe_mode;             /* perf: snapshot de los gates por-frame */
    BOOL fovCircle;                     /* C-11: circulo del FOV de aim */
    BOOL ignoreDown;                    /* C-17: no asistir a enemigos caidos */
    BOOL teamFilter;                    /* 2026-11: no dibujar al propio equipo */
    BOOL stateTags;                     /* 2026-11: curando / invisible / vehiculo */
    BOOL ammoTag;                       /* 2026-11: municion + ADS del enemigo */
    int  boxStyle, theme, crossStyle, maxN;
    float range;
} MMDrawOpts;
static MMDrawOpts g_draw_opts;
static BOOL g_draw_opts_ok = NO;
static void mm_opts_invalidate(void) { g_draw_opts_ok = NO; mm_scene_bump(); }
static const MMDrawOpts *mm_draw_opts(void)
{
    if (g_draw_opts_ok) return &g_draw_opts;
    MMDrawOpts *o = &g_draw_opts;
    memset(o, 0, sizeof(*o));
    o->box       = mm_def_bool(@"mm_esp_box", NO);
    o->name      = mm_def_bool(@"mm_esp_name", NO);
    o->dist      = mm_def_bool(@"mm_esp_dist", NO);
    o->lines     = mm_def_bool(@"mm_esp_lines", NO);
    o->linesTop  = mm_def_bool(@"mm_esp_lines_top", NO);
    o->health    = mm_def_bool(@"mm_esp_health", NO);
    o->fill      = mm_def_bool(@"mm_esp_fill", NO);
    o->cross     = mm_def_bool(@"mm_x_cross", NO);
    o->aimring   = mm_def_bool(@"mm_x_aimring", NO);
    o->fps       = mm_def_bool(@"mm_x_fps", NO);
    o->head      = mm_def_bool(@"mm_x_head", NO);
    o->distcol   = mm_def_bool(@"mm_x_distcol", NO);
    o->lowhp     = mm_def_bool(@"mm_x_lowhp", NO);
    o->priority  = mm_def_bool(@"mm_x_priority", NO);
    o->warn      = mm_def_bool(@"mm_x_warn", NO);
    o->arrow     = mm_def_bool(@"mm_x_arrow", NO);
    o->radar     = mm_def_bool(@"mm_x_radar", NO);
    o->height    = mm_def_bool(@"mm_x_height", NO);
    o->telem     = mm_def_bool(@"mm_x_telem", NO);
    o->bearings  = mm_def_bool(@"mm_x_bearings", NO);
    o->trails    = mm_def_bool(@"mm_x_trails", NO);
    o->declutter = YES;   /* feature fija: anti-solape siempre on, sin UI */
    o->radarCam  = mm_def_bool(@"mm_x_radar_cam", YES);
    o->targetList= mm_def_bool(@"mm_x_targetlist", NO);
    o->players   = mm_def_bool(@"mm_esp_players", NO);
    o->master    = mm_def_bool(@"mm_esp_master", NO);
    o->fovCircle = mm_def_bool(@"mm_x_fov_circle", NO);
    o->ignoreDown = mm_def_bool(@"mm_x_ignore_down", NO);
    /* 2026-11: lecturas nuevas (team / estado / municion). Apagadas por defecto
       hasta validarlas en device: ver docs/re-lecturas-1057.md. */
    o->teamFilter = mm_def_bool(@"mm_x_team_filter", NO);
    o->stateTags  = mm_def_bool(@"mm_x_state_tags", NO);
    o->ammoTag    = mm_def_bool(@"mm_x_ammo", NO);
    o->safe_mode = mm_def_bool(@"mm_safe_mode", NO);
    o->bots      = mm_def_bool(@"mm_esp_bots", NO);
    o->boxStyle  = (int)mm_def_float(@"mm_esp_box_style", 0.0f);
    o->theme     = (int)mm_def_float(@"mm_esp_theme", 0.0f);
    o->crossStyle= (int)mm_def_float(@"mm_x_cross_style", 0.0f);
    o->maxN      = (int)mm_def_float(@"mm_x_maxn", 0.0f);
    o->range     = mm_def_float(@"mm_esp_range", 500.0f);
    if (o->boxStyle != 1) o->boxStyle = 0;
    if (o->theme < 0 || o->theme > 2) o->theme = 0;
    if (o->crossStyle < 0 || o->crossStyle > 3) o->crossStyle = 0;
    if (o->maxN < 0) o->maxN = 0;
    if (o->maxN > MM_MAX_BOXES) o->maxN = MM_MAX_BOXES;
    /* 1.12: con el equipo caliente se apaga el relleno (lo mas caro de pintar)
       sin tocar la preferencia del operador. */
    if (g_thermal_level >= 2) o->fill = NO;
    g_draw_opts_ok = YES;
    return o;
}

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
 * v0.7.0 (1.15): host seguro para el guard de captura.
 *   El contenido vive dentro del canvas de un UITextField secureTextEntry:
 *   iOS lo excluye de capturas y grabacion. El hitTest del campo se reenvia
 *   al overlay; fuera del overlay devuelve nil y el toque sigue al juego.
 *   Es OPT-IN y con fallback: si no hay canvas, la UI queda en la ventana.
 *--------------------------------------------------------------------------*/
@interface MMSecureHost : UITextField @end

@implementation MMSecureHost
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (g_root == nil || g_root.hidden || g_root.alpha < 0.01) return nil;
    return [g_root hitTest:point withEvent:event];
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
    if (g_cb_mode) {
        /* 1.16: paletas para daltonismo. Naranja vs azul (protan/deutan) y
           magenta vs verde-cian (tritan) mantienen el par separado. */
        if (g_cb_mode == 3) {
            if (robot) { *r = 0.15; *g = 0.85; *b = 0.85; }
            else       { *r = 0.95; *g = 0.25; *b = 0.85; }
        } else {
            if (robot) { *r = 0.30; *g = 0.58; *b = 1.00; }
            else       { *r = 1.00; *g = 0.62; *b = 0.10; }
        }
        return;
    }
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
/* v0.6.4: ritmo REAL de pintado (drawRect), no del display link. */
static double g_paint_fps = 0.0;
static uint64_t g_paints = 0;

/* fwd: el acento del tema se define mas abajo, pero drawRect/helpers lo usan aqui. */
static UIColor *mm_neon_green(void);
static UIColor *mm_neon_purple(void);

/*---------------------------------------------------------------------------
 * v0.6.2: CPU del lienzo. Fuentes, sombra y medidas de texto se reutilizan.
 * Antes drawRect creaba UIFont/NSShadow y medía cada etiqueta con CoreText en
 * cada frame (y un NSDictionary por caja en la etiqueta de altura).
 *--------------------------------------------------------------------------*/
static UIFont *mm_font_name(void)
{
    static UIFont *f = nil;
    if (f == nil) f = [UIFont systemFontOfSize:10.5 weight:UIFontWeightSemibold]
                        ?: [UIFont boldSystemFontOfSize:10.5];
    return f;
}
static UIFont *mm_font_dist(void)
{
    static UIFont *f = nil;
    if (f == nil) f = [UIFont monospacedDigitSystemFontOfSize:9.5
                                                      weight:UIFontWeightMedium]
                        ?: [UIFont systemFontOfSize:9.5];
    return f;
}
static UIFont *mm_font_ring(void)
{
    static UIFont *f = nil;
    if (f == nil) f = [UIFont monospacedDigitSystemFontOfSize:7.5
                                                      weight:UIFontWeightMedium]
                        ?: [UIFont systemFontOfSize:7.5];
    return f;
}
static UIFont *mm_font_fps(void)
{
    static UIFont *f = nil;
    if (f == nil) f = [UIFont monospacedDigitSystemFontOfSize:10.0
                                                      weight:UIFontWeightSemibold]
                        ?: [UIFont boldSystemFontOfSize:10.0];
    return f;
}
static NSShadow *mm_txt_shadow(void)
{
    static NSShadow *sh = nil;
    if (sh == nil) {
        sh = [[NSShadow alloc] init];
        sh.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.82];
        sh.shadowBlurRadius = 2.0;
        sh.shadowOffset = CGSizeMake(0.0, 1.0);
    }
    return sh;
}

/* Cache de medidas: 0 = nombre, 1 = distancia/altura, 2 = anillos del radar.
   Las cadenas cortas se repiten (distancias enteras, nombres, "+12m"), así que
   el hit rate es alto y CoreText deja de medir en cada frame. */
static CGSize mm_text_size(NSString *s, NSDictionary *attrs, int slot)
{
    static NSMutableDictionary *c0 = nil, *c1 = nil, *c2 = nil;
    if (s.length == 0) return CGSizeZero;
    NSMutableDictionary *c = (slot <= 0) ? c0 : (slot == 1 ? c1 : c2);
    if (c == nil) {
        c = [NSMutableDictionary dictionary];
        if (slot <= 0) c0 = c; else if (slot == 1) c1 = c; else c2 = c;
    }
    NSValue *v = c[s];
    if (v != nil) return v.CGSizeValue;
    CGSize sz = [s sizeWithAttributes:attrs];
    if (c.count > 512) [c removeAllObjects];   /* techo de memoria */
    c[s] = [NSValue valueWithCGSize:sz];
    return sz;
}

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
    double fpsShow = (g_paint_fps > 0.5) ? g_paint_fps : g_fps;
    NSString *s = [NSString stringWithFormat:@"%d FPS", (int)(fpsShow + 0.5)];
    static NSDictionary *a = nil;   /* v0.6.2: atributos una sola vez */
    if (a == nil) a = @{ NSFontAttributeName: mm_font_fps(),
        NSForegroundColorAttributeName: [UIColor colorWithWhite:0.92 alpha:1.0],
        NSShadowAttributeName: mm_txt_shadow() };
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

/* v0.4.4 (Fase 1.1): radar 2D.
   v0.5.0: dibuja desde el TRACK mundial, no desde las cajas: los enemigos
   detras de la camara (o fuera del cuadro) siguen apareciendo en el radar.
   Fase 1.1: anillos de 50/100/200 m, modo camara-arriba (yaw desde view),
   rumbo de la camara en modo norte-arriba y caret de altura por contacto.
   v0.6.0 (iteracion de intuicion): radar mas grande, cono de vision legible,
   chevron "FRENTE" en el borde (reemplaza a la "N" rotatoria en camara-arriba),
   triangulo del jugador grande con outline negro, etiquetas de distancia en los
   anillos 50/100/200, y los contactos a la ESPALDA se dibujan como aro hueco
   (los del cono se quedan como punto macizo). "Arriba = donde mira el jugador"
   queda explicito a primer golpe de vista. */
/* C-11: circulo del FOV de aim (como SP3CTERIOS). Radio proyectado desde el
   FOV de aim en grados y el FOV real de la camara. */
static void mm_draw_fov_circle(CGContextRef ctx, CGRect bs, CGFloat cr, CGFloat cg, CGFloat cb)
{
    if (!mm_draw_opts()->fovCircle) return;
    float aimFov = g_aim_fov;
    if (aimFov <= 0.5f || aimFov >= 179.5f) return;
    float camFov = 60.0f;
    if (g_fp_cam_getfov != NULL && g_fov_cam_get != NULL) {
        void *cam = g_fov_cam_get();
        if (cam != NULL) {
            float f = g_fp_cam_getfov(cam);
            if (isfinite(f) && f > 20.0f && f < 140.0f) camFov = f;
        }
    }
    CGFloat h = bs.size.height;
    CGFloat r = (CGFloat)(tan(aimFov * (float)M_PI / 360.0f) /
                          tan(camFov * (float)M_PI / 360.0f)) * (h / 2.0);
    if (r < 10.0 || r > h) return;
    CGPoint c = CGPointMake(bs.size.width / 2.0, bs.size.height / 2.0);
    CGContextSaveGState(ctx);
    CGContextSetShadowWithColor(ctx, CGSizeZero, 4.0,
        [UIColor colorWithRed:cr green:cg blue:cb alpha:0.5].CGColor);
    CGContextSetLineWidth(ctx, 1.4);
    CGContextSetRGBStrokeColor(ctx, cr, cg, cb, 0.55);
    CGContextStrokeEllipseInRect(ctx, CGRectMake(c.x - r, c.y - r, r * 2.0, r * 2.0));
    CGContextRestoreGState(ctx);
}

static void mm_draw_radar(CGContextRef ctx, CGRect bs, CGFloat cr, CGFloat cg, CGFloat cb)
{
    if (!g_have_local) return;
    CGFloat R = 92.0, cx = bs.size.width - R - 16.0, cy = R + 54.0;
    const MMDrawOpts *o = mm_draw_opts();
    float rng = o->range; if (rng < 40.0f) rng = 40.0f;
    /* El radar es tactico: 200 m de techo. Los contactos mas lejanos quedan
       pegados al borde y atenuados (el ESP sigue mostrando su caja real). */
    float radarRng = (rng > 200.0f) ? 200.0f : rng;
    BOOL camUp = o->radarCam && g_have_view;

    /* fondo: disco oscuro + aro interior tenue del color del tema para marcar
       que es parte del mod y no del HUD del juego. */
    /* C-10: fondo con gradiente radial (centro mas claro) + aro con glow. */
    CGContextSaveGState(ctx);
    CGContextAddEllipseInRect(ctx, CGRectMake(cx - R, cy - R, R * 2.0, R * 2.0));
    CGContextClip(ctx);
    {
        CGColorSpaceRef spc = CGColorSpaceCreateDeviceRGB();
        CGFloat gcol[8] = { 0.06, 0.13, 0.10, 0.90,  0.01, 0.03, 0.03, 0.94 };
        CGFloat gloc[2] = { 0.0, 1.0 };
        CGGradientRef grad = CGGradientCreateWithColorComponents(spc, gcol, gloc, 2);
        if (grad != NULL) {
            CGContextDrawRadialGradient(ctx, grad, CGPointMake(cx, cy), 0.0,
                                        CGPointMake(cx, cy), R, 0);
            CGGradientRelease(grad);
        }
        CGColorSpaceRelease(spc);
    }
    CGContextRestoreGState(ctx);
    CGContextSaveGState(ctx);
    CGContextSetShadowWithColor(ctx, CGSizeZero, 8.0,
        [UIColor colorWithRed:cr green:cg blue:cb alpha:0.55].CGColor);
    CGContextSetLineWidth(ctx, 1.3);
    CGContextSetRGBStrokeColor(ctx, cr, cg, cb, 0.42);
    CGContextStrokeEllipseInRect(ctx, CGRectMake(cx - (R - 1.0), cy - (R - 1.0),
                                                  (R - 1.0) * 2.0, (R - 1.0) * 2.0));
    CGContextRestoreGState(ctx);
    /* grilla tenue: cruz central */
    CGContextSetLineWidth(ctx, 0.5);
    CGContextSetRGBStrokeColor(ctx, cr, cg, cb, 0.10);
    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, cx - R + 5.0, cy);
    CGContextAddLineToPoint(ctx, cx + R - 5.0, cy);
    CGContextMoveToPoint(ctx, cx, cy - R + 5.0);
    CGContextAddLineToPoint(ctx, cx, cy + R - 5.0);
    CGContextStrokePath(ctx);

    /* direccion "arriba" del radar en espacio de pantalla.
       - camara-arriba: fijo arriba (frente al jugador = arriba de la pantalla).
       - norte-arriba:  gira con la camara para marcar la vista actual. */
    CGFloat fwdAng = -(CGFloat)M_PI / 2.0;
    if (!camUp && g_have_view) {
        float fx = -g_view_mtx[2], fz = -g_view_mtx[10];
        if (fabsf(fx) > 0.0001f || fabsf(fz) > 0.0001f)
            fwdAng = atan2f(fz, fx);
    }

    /* cono de vision: slice al color del tema (bien visible). Marcas de 30
       grados fuera del cono, para no competir con el cono. */
    CGFloat halfCone = 0.52;   /* ~30 grados por lado => cono de ~60 grados */
    {
        CGContextSaveGState(ctx);
        CGContextSetRGBFillColor(ctx, cr, cg, cb, 0.15);
        CGContextMoveToPoint(ctx, cx, cy);
        CGContextAddArc(ctx, cx, cy, R - 2.0, fwdAng - halfCone, fwdAng + halfCone, 0);
        CGContextClosePath(ctx);
        CGContextFillPath(ctx);
        /* bordes del cono: finos y del color del tema, para dejar lineal la mira. */
        CGContextSetLineWidth(ctx, 0.9);
        CGContextSetRGBStrokeColor(ctx, cr, cg, cb, 0.48);
        {
            CGFloat eux = cosf((float)(fwdAng - halfCone)), euy = sinf((float)(fwdAng - halfCone));
            CGFloat vux = cosf((float)(fwdAng + halfCone)), vuy = sinf((float)(fwdAng + halfCone));
            CGContextMoveToPoint(ctx, cx, cy);
            CGContextAddLineToPoint(ctx, cx + eux * (R - 2.0), cy + euy * (R - 2.0));
            CGContextMoveToPoint(ctx, cx, cy);
            CGContextAddLineToPoint(ctx, cx + vux * (R - 2.0), cy + vuy * (R - 2.0));
            CGContextStrokePath(ctx);
        }
        CGContextRestoreGState(ctx);
    }

    /* v0.6.2: las 12 marcas en DOS trazos (mayores y menores), no 12. */
    for (int pass = 0; pass < 2; pass++) {
        int step = pass ? 90 : 30;
        CGContextSetLineWidth(ctx, pass ? 1.0 : 0.7);
        CGContextSetRGBStrokeColor(ctx, 1.0, 1.0, 1.0, pass ? 0.22 : 0.11);
        CGContextBeginPath(ctx);
        for (int a = 0; a < 360; a += step) {
            if (!pass && (a % 90) == 0) continue;   /* los mayores van en pass 1 */
            CGFloat rad = (CGFloat)a * (CGFloat)M_PI / 180.0f;
            CGFloat ux = sinf((float)rad), uy = -cosf((float)rad);
            CGFloat r0 = pass ? R - 7.0 : R - 4.0;
            CGContextMoveToPoint(ctx, cx + ux * r0, cy + uy * r0);
            CGContextAddLineToPoint(ctx, cx + ux * (R - 1.0), cy + uy * (R - 1.0));
        }
        CGContextStrokePath(ctx);
    }

    /* anillos 50/100/200 m sobre la escala tactica, con etiqueta "50m", "100m",
       "200m" en el borde derecho del anillo (encima de un rectangulito oscuro). */
    static const float ringM[3] = { 50.0f, 100.0f, 200.0f };
    UIFont *lblF = mm_font_ring();
    static NSDictionary *la = nil;   /* v0.6.2: atributos y medidas cacheadas */
    if (la == nil) la = @{ NSFontAttributeName: lblF,
        NSForegroundColorAttributeName: [UIColor colorWithWhite:0.86 alpha:0.95] };
    for (int k = 0; k < 3; k++) {
        if (ringM[k] > radarRng) continue;
        CGFloat rr = R * (CGFloat)(ringM[k] / radarRng);
        CGContextSetLineWidth(ctx, (ringM[k] > 100.0f) ? 0.7 : 0.9);
        CGContextSetRGBStrokeColor(ctx, cr, cg, cb,
                                   (ringM[k] > 100.0f) ? 0.15 : 0.25);
        CGContextStrokeEllipseInRect(ctx, CGRectMake(cx - rr, cy - rr, rr * 2.0, rr * 2.0));

        /* etiqueta del anillo: "50m"/"100m"/"200m" a la derecha, con pastilla. */
        NSString *lbl = [NSString stringWithFormat:@"%.0fm", ringM[k]];
        CGSize lsz = mm_text_size(lbl, la, 2);
        CGFloat lx = cx + rr - lsz.width - 1.0;
        CGFloat ly = cy - lsz.height / 2.0 - 0.5;
        CGContextSetRGBFillColor(ctx, 0.0, 0.0, 0.0, 0.55);
        CGContextFillRect(ctx, CGRectMake(lx - 1.5, ly, lsz.width + 3.0, lsz.height));
        [lbl drawAtPoint:CGPointMake(lx, ly) withAttributes:la];
    }

    /* borde exterior del disco */
    CGContextSetLineWidth(ctx, 1.2);
    CGContextSetRGBStrokeColor(ctx, cr, cg, cb, 0.70);
    CGContextStrokeEllipseInRect(ctx, CGRectMake(cx - R, cy - R, R * 2.0, R * 2.0));

    /* chevron "FRENTE" por fuera del aro, en direccion de la vista. Siempre
       lo ves aunque el radar este en norte-arriba (ahi te marca hacia donde
       estas mirando). Reemplaza a la "N" rotatoria que confundia. */
    {
        CGFloat chCx = cx + cosf((float)fwdAng) * (R + 4.5);
        CGFloat chCy = cy + sinf((float)fwdAng) * (R + 4.5);
        CGFloat chUx = cosf((float)fwdAng), chUy = sinf((float)fwdAng);
        CGFloat chPx = -chUy, chPy = chUx;
        /* sombra */
        CGContextSaveGState(ctx);
        CGContextSetShadowWithColor(ctx, CGSizeMake(0.0, 1.0), 2.5,
            [UIColor colorWithWhite:0.0 alpha:0.9].CGColor);
        CGContextBeginPath(ctx);
        CGContextMoveToPoint(ctx, chCx + chUx * 4.2, chCy + chUy * 4.2);     /* punta */
        CGContextAddLineToPoint(ctx, chCx - chUx * 1.2 + chPx * 3.6,
                                     chCy - chUy * 1.2 + chPy * 3.6);
        CGContextAddLineToPoint(ctx, chCx - chUx * 1.2 - chPx * 3.6,
                                     chCy - chUy * 1.2 - chPy * 3.6);
        CGContextClosePath(ctx);
        CGContextSetRGBFillColor(ctx, cr, cg, cb, 0.96);
        CGContextFillPath(ctx);
        CGContextRestoreGState(ctx);
    }

    /* v0.6.3: zona de radiacion actual. Solo aparece si el contrato trae
       offsets verificados por el probe (si no, g_br_zone.ok == 0). */
    if (g_br_zone.ok && g_have_local) {
        CGContextSaveGState(ctx);
        CGContextAddEllipseInRect(ctx, CGRectMake(cx - (R - 1.0), cy - (R - 1.0),
                                                 (R - 1.0) * 2.0, (R - 1.0) * 2.0));
        CGContextClip(ctx);
        float zdx = g_br_zone.x - g_local_pos[0];
        float zdz = g_br_zone.z - g_local_pos[2];
        float zpx, zpy;
        if (camUp) {
            float vx = g_view_mtx[0] * zdx + g_view_mtx[8]  * zdz;
            float vz = g_view_mtx[2] * zdx + g_view_mtx[10] * zdz;
            zpx = (float)cx + (vx / radarRng) * (float)R;
            zpy = (float)cy + (vz / radarRng) * (float)R;
        } else {
            zpx = (float)cx + (zdx / radarRng) * (float)R;
            zpy = (float)cy + (zdz / radarRng) * (float)R;
        }
        CGFloat zpr = (CGFloat)(g_br_zone.r / radarRng) * R;
        if (zpr > 0.5) {
            CGContextSetLineWidth(ctx, 1.5);
            CGContextSetRGBStrokeColor(ctx, cr, cg, cb, 0.55);
            CGContextStrokeEllipseInRect(ctx, CGRectMake(zpx - zpr, zpy - zpr,
                                                         zpr * 2.0, zpr * 2.0));
        }
        /* C-6b: proxima zona (estimada: mismo centro, radio * 0.55) en cian
           para diferenciarla de la actual. */
        CGFloat npr = zpr * 0.55;
        if (npr > 0.5) {
            CGContextSetLineWidth(ctx, 1.3);
            CGContextSetRGBStrokeColor(ctx, 0.25, 0.95, 1.0, 0.85);
            CGContextStrokeEllipseInRect(ctx, CGRectMake(zpx - npr, zpy - npr,
                                                         npr * 2.0, npr * 2.0));
        }
        CGContextSetRGBFillColor(ctx, cr, cg, cb, 0.90);
        CGContextFillEllipseInRect(ctx, CGRectMake(zpx - 2.0, zpy - 2.0, 4.0, 4.0));
        CGContextRestoreGState(ctx);
    }

    /* "N" (norte) solo en modo norte-arriba — ahi queda siempre arriba y
       cumple su rol de brujula. En camara-arriba la referencia es "FRENTE". */
    if (!camUp) {
        CGFloat nr = R - 12.0;
        NSString *ns = @"N";
        UIFont *nf = [UIFont boldSystemFontOfSize:9.0];
        NSShadow *nsh = [[NSShadow alloc] init];
        nsh.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.9];
        nsh.shadowBlurRadius = 2.0; nsh.shadowOffset = CGSizeZero;
        NSDictionary *na = @{ NSFontAttributeName: nf,
            NSForegroundColorAttributeName: [UIColor colorWithWhite:0.92 alpha:0.95],
            NSShadowAttributeName: nsh };
        CGSize nsz = [ns sizeWithAttributes:na];
        [ns drawAtPoint:CGPointMake(cx - nsz.width / 2.0,
                                    cy - nr - nsz.height / 2.0)
         withAttributes:na];
    }

    /* marcador del jugador: triangulo grande, outline negro + relleno cian
       claro. Que no se pierda sobre fondos claros ni oscuros. */
    {
        CGFloat ux = cosf((float)fwdAng), uy = sinf((float)fwdAng);
        CGFloat px = -uy, py = ux;   /* perpendicular */
        CGContextBeginPath(ctx);
        CGContextMoveToPoint(ctx, cx + ux * 12.0, cy + uy * 12.0);
        CGContextAddLineToPoint(ctx, cx - ux * 5.5 + px * 6.5, cy - uy * 5.5 + py * 6.5);
        CGContextAddLineToPoint(ctx, cx - ux * 2.0, cy - uy * 2.0);   /* muesca atras */
        CGContextAddLineToPoint(ctx, cx - ux * 5.5 - px * 6.5, cy - uy * 5.5 - py * 6.5);
        CGContextClosePath(ctx);
        /* outline oscuro para que lea sobre cualquier mapa */
        CGContextSetLineWidth(ctx, 1.6);
        CGContextSetLineJoin(ctx, kCGLineJoinRound);
        CGContextSetRGBStrokeColor(ctx, 0.0, 0.0, 0.0, 0.80);
        CGContextStrokePath(ctx);
        /* relleno */
        CGContextBeginPath(ctx);
        CGContextMoveToPoint(ctx, cx + ux * 12.0, cy + uy * 12.0);
        CGContextAddLineToPoint(ctx, cx - ux * 5.5 + px * 6.5, cy - uy * 5.5 + py * 6.5);
        CGContextAddLineToPoint(ctx, cx - ux * 2.0, cy - uy * 2.0);
        CGContextAddLineToPoint(ctx, cx - ux * 5.5 - px * 6.5, cy - uy * 5.5 - py * 6.5);
        CGContextClosePath(ctx);
        CGContextSetRGBFillColor(ctx, 0.92, 0.98, 1.0, 1.0);
        CGContextFillPath(ctx);
    }

    /* contactos. Si estan DENTRO del cono de vision -> punto macizo.
       Si estan a la espalda (fuera del cono) -> aro hueco: al vuelo sabes
       cual es tiro directo y cual tenes que girar para mirar.
       Fuera del rango tactico -> pegado al borde y atenuado. */
    for (int i = 0; i < g_track_count && i < MM_MAX_TRACKS; i++) {
        MMTrack *tk = &g_tracks[i];
        if (!tk->alive) continue;
        float dx = tk->wx - g_local_pos[0];
        float dz = tk->wz - g_local_pos[2];

        /* bearing del contacto en el plano del radar (grados en pantalla). */
        float bearingAng;
        float px, py;
        if (camUp) {
            float vx = g_view_mtx[0] * dx + g_view_mtx[8]  * dz;
            float vz = g_view_mtx[2] * dx + g_view_mtx[10] * dz;
            px = (float)cx + (vx / radarRng) * (float)R;
            py = (float)cy + (vz / radarRng) * (float)R;
            /* en camara-arriba, "arriba" = -y en pantalla; el angulo relativo
               al frente lo sacamos del vector de pantalla desde el centro. */
            float sxv = px - (float)cx, syv = py - (float)cy;
            bearingAng = atan2f(syv, sxv);
        } else {
            px = (float)cx + (dx / radarRng) * (float)R;
            py = (float)cy + (dz / radarRng) * (float)R;
            float sxv = px - (float)cx, syv = py - (float)cy;
            bearingAng = atan2f(syv, sxv);
        }
        /* diferencia angular contra fwdAng (centro del cono). */
        float dAng = bearingAng - (float)fwdAng;
        while (dAng >  (float)M_PI) dAng -= 2.0f * (float)M_PI;
        while (dAng < -(float)M_PI) dAng += 2.0f * (float)M_PI;
        BOOL enConoVista = (fabsf(dAng) <= (float)halfCone);

        float ox = px - (float)cx, oy = py - (float)cy;
        float d = sqrtf(ox * ox + oy * oy);
        BOOL fuera = NO;
        if (d > (float)R - 3.0f) {
            float s = ((float)R - 3.0f) / d;
            px = (float)cx + ox * s; py = (float)cy + oy * s;
            fuera = (tk->dist > radarRng);
        }
        CGFloat al = tk->proj ? 0.97 : 0.62;
        if (fuera) al *= 0.62;

        /* halo oscuro: legible sobre cualquier fondo */
        CGContextSetRGBFillColor(ctx, 0.0, 0.0, 0.0, 0.60);
        CGContextFillEllipseInRect(ctx, CGRectMake(px - 3.6, py - 3.6, 7.2, 7.2));

        CGFloat colR, colG, colB;
        if (tk->downed) { colR = 1.0;  colG = 0.62; colB = 0.12; }   /* C-19: caido = naranja */
        else if (tk->robot) { colR = 0.63; colG = 0.30; colB = 1.0; }
        else           { colR = 1.0;  colG = 0.25; colB = 0.30; }

        /* C-10: pulso expansivo para contactos cercanos (<25 m). */
        if (tk->dist < 25.0f) {
            double ph = fmod(CACurrentMediaTime(), 1.2) / 1.2;
            CGFloat pr = 4.0 + (CGFloat)ph * 10.0;
            CGFloat pa = (CGFloat)(1.0 - ph) * 0.55;
            CGContextSetLineWidth(ctx, 1.2);
            CGContextSetRGBStrokeColor(ctx, colR, colG, colB, pa);
            CGContextStrokeEllipseInRect(ctx, CGRectMake(px - pr, py - pr,
                                                         pr * 2.0, pr * 2.0));
        }

        if (enConoVista) {
            /* punto macizo: contacto en la direccion que estas mirando */
            CGContextSetRGBFillColor(ctx, colR, colG, colB, al);
            CGContextFillEllipseInRect(ctx, CGRectMake(px - 2.6, py - 2.6, 5.2, 5.2));
        } else {
            /* aro hueco: contacto fuera de tu cono (laterales + espalda) */
            CGContextSetLineWidth(ctx, 1.5);
            CGContextSetRGBStrokeColor(ctx, colR, colG, colB, al);
            CGContextStrokeEllipseInRect(ctx, CGRectMake(px - 2.8, py - 2.8, 5.6, 5.6));
            /* centro oscuro adicional para que el aro no se confunda con un punto. */
            CGContextSetRGBFillColor(ctx, 0.0, 0.0, 0.0, 0.35);
            CGContextFillEllipseInRect(ctx, CGRectMake(px - 1.2, py - 1.2, 2.4, 2.4));
        }

        /* caret de altura: triangulito arriba (enemigo mas alto) / abajo (mas
           bajo). Mismo signo que el indicador junto a la caja. */
        float dh = tk->wy - g_local_pos[1];
        if (fabsf(dh) >= 2.0f) {
            CGFloat ty = (dh > 0.0f) ? (CGFloat)py - 7.0 : (CGFloat)py + 7.0;
            CGFloat dir = (dh > 0.0f) ? -1.0 : 1.0;
            CGContextBeginPath(ctx);
            CGContextMoveToPoint(ctx, px, ty);
            CGContextAddLineToPoint(ctx, px - 2.8, ty - dir * 3.2);
            CGContextAddLineToPoint(ctx, px + 2.8, ty - dir * 3.2);
            CGContextClosePath(ctx);
            CGContextSetRGBFillColor(ctx, colR, colG, colB, al);
            CGContextFillPath(ctx);
        }
    }

    /* pie: "mi vista ▲ · 200m" / "norte ▲ · 200m". El triangulo refuerza el
       mensaje de "lo de arriba es lo que estas mirando". */
    {
        NSString *cap = [NSString stringWithFormat:@"%@ ▲ · %.0f m",
                         camUp ? @"mi vista" : @"norte",
                         radarRng];
        UIFont *cf = [UIFont monospacedDigitSystemFontOfSize:8.5
                                                      weight:UIFontWeightSemibold];
        if (cf == nil) cf = [UIFont systemFontOfSize:8.5];
        NSShadow *csh = [[NSShadow alloc] init];
        csh.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.9];
        csh.shadowBlurRadius = 2.5; csh.shadowOffset = CGSizeZero;
        NSDictionary *ca = @{ NSFontAttributeName: cf,
            NSForegroundColorAttributeName: [UIColor colorWithWhite:0.88 alpha:0.97],
            NSShadowAttributeName: csh };
        CGSize csz = [cap sizeWithAttributes:ca];
        [cap drawAtPoint:CGPointMake(cx - csz.width / 2.0, cy + R + 4.0)
          withAttributes:ca];
    }
}

/* v0.4.4 (Fase 1.7): telemetria (colecta, cajas, jug/bot).
   Fase 1.7: suma lecturas vm/s y memoria residente del proceso. */
static void mm_telem_update(void)
{
    static double last_t = 0.0, last_mem_t = 0.0;
    static uint64_t last_reads = 0;
    double now = CACurrentMediaTime();
    if (last_t <= 0.0) { last_t = now; last_reads = g_vm_reads; }
    double dt = now - last_t;
    if (dt > 3.0) {
        /* el HUD estuvo apagado: no promediar el hueco */
        g_reads_per_s = 0.0;
        last_t = now;
        last_reads = g_vm_reads;
    } else if (dt >= 1.0) {
        g_reads_per_s = (double)(g_vm_reads - last_reads) / dt;
        last_t = now;
        last_reads = g_vm_reads;
    }
    if (last_mem_t <= 0.0) last_mem_t = now - 1.0;   /* primera medida inmediata */
    if (now - last_mem_t >= 1.0) {
        last_mem_t = now;
        mach_task_basic_info_data_t bi;
        mach_msg_type_number_t cnt = MACH_TASK_BASIC_INFO_COUNT;
        if (task_info(mach_task_self(), MACH_TASK_BASIC_INFO,
                      (task_info_t)&bi, &cnt) == KERN_SUCCESS)
            g_mem_mb = (double)bi.resident_size / (1024.0 * 1024.0);
    }
}

static void mm_draw_telem(CGRect bs)
{
    (void)bs;
    mm_telem_update();
    UIFont *f = [UIFont monospacedDigitSystemFontOfSize:9.0 weight:UIFontWeightMedium];
    if (f == nil) f = [UIFont systemFontOfSize:9.0];
    NSShadow *sh = [[NSShadow alloc] init];
    sh.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.8];
    sh.shadowBlurRadius = 2.0; sh.shadowOffset = CGSizeMake(0.0, 1.0);
    NSDictionary *a = @{ NSFontAttributeName: f,
        NSForegroundColorAttributeName: [UIColor colorWithWhite:0.78 alpha:1.0],
        NSShadowAttributeName: sh };
    NSString *s1 = [NSString stringWithFormat:@"col %.1fms  cajas %d  jug %d bot %d",
                    g_collect_ms, g_box_count, g_count_players, g_count_bots];
    NSString *s2 = [NSString stringWithFormat:@"%.0f lect/s  %.0f MB  fov %.0f  pint %.0f",
                    g_reads_per_s, g_mem_mb, g_fov_deg, g_paint_fps];
    [s1 drawAtPoint:CGPointMake(10.0, 60.0) withAttributes:a];
    [s2 drawAtPoint:CGPointMake(10.0, 71.0) withAttributes:a];
}

/* v0.6.4: lista de objetivos ordenada por distancia. Sale del TRACK mundial,
   asi que incluye a los que estan detras o fuera de cuadro. Solo texto y una
   flecha por fila: no agrega lecturas ni proyecciones. */
static void mm_draw_target_list(CGContextRef ctx, CGRect bs)
{
    (void)bs;
    if (!g_have_local || g_track_count <= 0) return;

    int idx[MM_TL_ROWS];
    int n = mm_tl_order(idx, MM_TL_ROWS);
    if (n <= 0) return;
    if (g_tl_sel_pawn != 0 &&
        (CACurrentMediaTime() - g_tl_sel_t) > 6.0) g_tl_sel_pawn = 0;

    const MMDrawOpts *o = mm_draw_opts();
    static UIFont *hf = nil, *rf = nil;
    static NSDictionary *ha = nil, *raJug = nil, *raBot = nil;
    static CGFloat acJ[3] = { 0.35f, 1.0f, 0.36f }, acB[3] = { 1.0f, 0.30f, 0.36f };
    static int raTheme = -1;
    if (hf == nil) hf = [UIFont boldSystemFontOfSize:8.0];
    if (rf == nil) rf = [UIFont monospacedDigitSystemFontOfSize:9.4
                                                      weight:UIFontWeightMedium];
    if (ha == nil) ha = @{ NSFontAttributeName: hf,
        NSForegroundColorAttributeName: [UIColor colorWithWhite:0.62 alpha:0.95] };
    if (raTheme != o->theme) {
        CGFloat jr = 1.0, jg = 1.0, jb = 1.0;
        mm_esp_color(0, o->theme, &jr, &jg, &jb);
        acJ[0] = jr; acJ[1] = jg; acJ[2] = jb;
        raJug = @{ NSFontAttributeName: rf,
            NSForegroundColorAttributeName: [UIColor colorWithRed:jr green:jg blue:jb alpha:1.0],
            NSShadowAttributeName: mm_txt_shadow() };
        mm_esp_color(1, o->theme, &jr, &jg, &jb);
        acB[0] = jr; acB[1] = jg; acB[2] = jb;
        raBot = @{ NSFontAttributeName: rf,
            NSForegroundColorAttributeName: [UIColor colorWithRed:jr green:jg blue:jb alpha:1.0],
            NSShadowAttributeName: mm_txt_shadow() };
        raTheme = o->theme;
    }

    CGFloat x = 10.0, y = 96.0, w = 140.0, rh = MM_TL_ROW_H;
    CGFloat hgt = 16.0 + rh * (CGFloat)n + 4.0;
    CGContextSetRGBFillColor(ctx, 0.01, 0.03, 0.02, 0.46);
    CGContextFillRect(ctx, CGRectMake(x - 4.0, y - 4.0, w, hgt));
    CGContextSetLineWidth(ctx, 0.7);
    CGContextSetRGBStrokeColor(ctx, 0.32, 1.0, 0.62, 0.22);
    CGContextStrokeRect(ctx, CGRectMake(x - 4.0, y - 4.0, w, hgt));
    [(mm_lang() ? @"TARGETS" : @"OBJETIVOS") drawAtPoint:CGPointMake(x, y - 1.0)
                                         withAttributes:ha];
    y += 14.0;

    for (int k = 0; k < n; k++) {
        MMTrack *t = &g_tracks[idx[k]];
        const MMEspBox *b = NULL;
        for (int q = 0; q < g_box_count; q++) {
            if (g_boxes[q].alive && g_boxes[q].pawn == t->pawn) { b = &g_boxes[q]; break; }
        }
        NSString *nm = nil;
        if (b != NULL && b->hasName) {
            nm = [NSString stringWithUTF8String:b->name];
        }
        if (nm.length == 0) nm = t->robot ? @"BOT" : @"JUG";
        if (nm.length > 9) nm = [nm substringToIndex:9];
        int hp = (b != NULL && b->hp >= 0.0f) ? (int)(b->hp + 0.5f) : -1;
        NSString *line = (hp >= 0)
            ? [NSString stringWithFormat:@"%3dm %@ %3d", (int)(t->dist + 0.5f), nm, hp]
            : [NSString stringWithFormat:@"%3dm %@", (int)(t->dist + 0.5f), nm];

        if (t->pawn != 0 && t->pawn == g_tl_sel_pawn) {
            CGContextSetRGBFillColor(ctx, 0.20, 1.0, 0.58, 0.18);
            CGContextFillRect(ctx, CGRectMake(x - 3.0, y - 2.0, w - 1.0, rh));
        }
        [line drawAtPoint:CGPointMake(x, y) withAttributes:(t->robot ? raBot : raJug)];

        /* flecha relativa a la camara: arriba = al frente. */
        if (g_have_view) {
            float dx = t->wx - g_local_pos[0], dz = t->wz - g_local_pos[2];
            float vx = g_view_mtx[0] * dx + g_view_mtx[8]  * dz;
            float vz = g_view_mtx[2] * dx + g_view_mtx[10] * dz;
            if (fabsf(vx) > 0.0001f || fabsf(vz) > 0.0001f) {
                float ang = atan2f(vx, -vz);
                CGFloat px = x + w - 16.0, py = y + 6.0;
                CGFloat ca = cosf(ang), sa = sinf(ang);
                CGFloat rr2 = 4.6, rb = 3.0;
                CGContextSetRGBFillColor(ctx, 0.0, 0.0, 0.0, 0.55);
                CGContextMoveToPoint(ctx, px + sa * rr2, py - ca * rr2);
                CGContextAddLineToPoint(ctx, px + sa * -rb + ca * rb,
                                             py - ca * -rb - sa * rb);
                CGContextAddLineToPoint(ctx, px + sa * -rb - ca * rb,
                                             py - ca * -rb + sa * rb);
                CGContextClosePath(ctx);
                CGContextFillPath(ctx);
                CGContextSetRGBFillColor(ctx,
                    t->robot ? acB[0] : acJ[0],
                    t->robot ? acB[1] : acJ[1],
                    t->robot ? acB[2] : acJ[2], 0.95);
                CGContextMoveToPoint(ctx, px + sa * 4.0, py - ca * 4.0);
                CGContextAddLineToPoint(ctx, px + sa * -2.6 + ca * 2.6,
                                             py - ca * -2.6 - sa * 2.6);
                CGContextAddLineToPoint(ctx, px + sa * -2.6 - ca * 2.6,
                                             py - ca * -2.6 + sa * 2.6);
                CGContextClosePath(ctx);
                CGContextFillPath(ctx);
            }
        }
        y += rh;
    }
}

/* Fase 1.3: brujula de bearings. Marca en un anillo, en la direccion de cada
   contacto relativa a la camara (view matrix), sin mirar el radar. */
static void mm_draw_bearings(CGContextRef ctx, CGRect bs)
{
    if (!g_have_local || !g_have_view || g_track_count <= 0) return;
    float rng = mm_draw_opts()->range; if (rng < 40.0f) rng = 40.0f;
    CGFloat cx = bs.size.width / 2.0, cy = bs.size.height / 2.0;
    CGFloat R = MIN(bs.size.width, bs.size.height) * 0.30;
    if (R < 90.0) R = 90.0;
    if (R > 150.0) R = 150.0;
    int tema = mm_draw_opts()->theme;

    CGContextSetLineWidth(ctx, 0.7);
    CGContextSetRGBStrokeColor(ctx, 1.0, 1.0, 1.0, 0.07);
    CGContextStrokeEllipseInRect(ctx, CGRectMake(cx - R, cy - R, R * 2.0, R * 2.0));

    /* v0.6.2: ticks agrupados por robot y nivel de alpha. Antes eran 2 draw
       calls por track (128 con 64 tracks); ahora 8 trazos + 8 puntos maximo. */
    #define MM_BEAR_LV 4
    for (int rb = 0; rb < 2; rb++) {
        CGFloat cr, cg, cb;
        mm_esp_color(rb, tema, &cr, &cg, &cb);
        for (int lv = 0; lv < MM_BEAR_LV; lv++) {
            CGFloat al = 0.25f + (CGFloat)lv * (0.67f / (CGFloat)(MM_BEAR_LV - 1));
            int hay = 0;
            /* trazos */
            CGContextBeginPath(ctx);
            for (int i = 0; i < g_track_count && i < MM_MAX_TRACKS; i++) {
                MMTrack *tk = &g_tracks[i];
                if (!tk->alive || tk->robot != rb) continue;
                float dx = tk->wx - g_local_pos[0];
                float dz = tk->wz - g_local_pos[2];
                if (fabsf(dx) < 0.05f && fabsf(dz) < 0.05f) continue;
                float vx = g_view_mtx[0] * dx + g_view_mtx[8]  * dz;
                float vz = g_view_mtx[2] * dx + g_view_mtx[10] * dz;
                CGFloat al0 = 0.90f - 0.55f * (tk->dist / rng);
                if (al0 < 0.25f) al0 = 0.25f;
                if (al0 > 0.92f) al0 = 0.92f;
                int lv0 = (int)(((al0 - 0.25f) / (0.67f / (CGFloat)(MM_BEAR_LV - 1))) + 0.5f);
                if (lv0 < 0) lv0 = 0;
                if (lv0 >= MM_BEAR_LV) lv0 = MM_BEAR_LV - 1;
                if (lv0 != lv) continue;
                CGFloat beta = atan2f(vx, -vz);
                CGFloat sx = sinf(beta), sy = -cosf(beta);
                CGContextMoveToPoint(ctx, cx + sx * (R - 6.0), cy + sy * (R - 6.0));
                CGContextAddLineToPoint(ctx, cx + sx * (R + 3.0), cy + sy * (R + 3.0));
                hay = 1;
            }
            if (hay) {
                CGContextSetLineWidth(ctx, 1.6);
                CGContextSetRGBStrokeColor(ctx, cr, cg, cb, al);
                CGContextStrokePath(ctx);
            }
            /* puntos */
            hay = 0;
            CGContextBeginPath(ctx);
            for (int i = 0; i < g_track_count && i < MM_MAX_TRACKS; i++) {
                MMTrack *tk = &g_tracks[i];
                if (!tk->alive || tk->robot != rb) continue;
                float dx = tk->wx - g_local_pos[0];
                float dz = tk->wz - g_local_pos[2];
                if (fabsf(dx) < 0.05f && fabsf(dz) < 0.05f) continue;
                float vx = g_view_mtx[0] * dx + g_view_mtx[8]  * dz;
                float vz = g_view_mtx[2] * dx + g_view_mtx[10] * dz;
                CGFloat al0 = 0.90f - 0.55f * (tk->dist / rng);
                if (al0 < 0.25f) al0 = 0.25f;
                if (al0 > 0.92f) al0 = 0.92f;
                int lv0 = (int)(((al0 - 0.25f) / (0.67f / (CGFloat)(MM_BEAR_LV - 1))) + 0.5f);
                if (lv0 < 0) lv0 = 0;
                if (lv0 >= MM_BEAR_LV) lv0 = MM_BEAR_LV - 1;
                if (lv0 != lv) continue;
                CGFloat beta = atan2f(vx, -vz);
                CGFloat sx = sinf(beta), sy = -cosf(beta);
                CGContextAddEllipseInRect(ctx, CGRectMake(cx + sx * (R + 4.0) - 1.8,
                                                          cy + sy * (R + 4.0) - 1.8,
                                                          3.6, 3.6));
                hay = 1;
            }
            if (hay) {
                CGContextSetRGBFillColor(ctx, cr, cg, cb, al);
                CGContextFillPath(ctx);
            }
        }
    }
    #undef MM_BEAR_LV
}

/* Fase 1.5: estelas. Se actualizan en el colector (~15 Hz, muestreo 0.15 s)
   con posiciones de MUNDO (no de pantalla: la camara se mueve) y se proyectan
   al dibujar. Desvanecido durante 2 s. */
static void mm_trails_clear(void)
{
    memset(g_trails, 0, sizeof(g_trails));
}

static void mm_trails_update(const MMEspBox *boxes, int n)
{
    if (boxes == NULL || n <= 0) return;   /* deja las viejas para el fade */
    double now = CACurrentMediaTime();
    for (int i = 0; i < n && i < MM_MAX_BOXES; i++) {
        const MMEspBox *b = &boxes[i];
        if (!b->alive) continue;
        int slot = -1, freeSlot = -1;
        for (int t = 0; t < MM_MAX_TRAILS; t++) {
            if (g_trails[t].n > 0 && g_trails[t].pawn == b->pawn) { slot = t; break; }
            if (g_trails[t].n == 0 && freeSlot < 0) freeSlot = t;
        }
        if (slot < 0) {
            if (freeSlot >= 0) slot = freeSlot;
            else {
                /* tabla llena: recicla la estela con la muestra mas vieja */
                double best = 1.0e18; int bi = 0;
                for (int t = 0; t < MM_MAX_TRAILS; t++) {
                    double lt = (g_trails[t].n > 0)
                              ? g_trails[t].p[g_trails[t].n - 1].t : 0.0;
                    if (lt < best) { best = lt; bi = t; }
                }
                slot = bi;
            }
            memset(&g_trails[slot], 0, sizeof(g_trails[slot]));
            g_trails[slot].pawn = b->pawn;
            g_trails[slot].robot = b->robot;
        }
        MMTrail *tr = &g_trails[slot];
        double lastT = (tr->n > 0) ? tr->p[tr->n - 1].t : 0.0;
        if (tr->n > 0 && (now - lastT) < MM_TRAIL_SAMPLE) continue;
        MMTrailPt p;
        p.x = b->wx;
        p.y = b->wy - 0.55f;   /* centro del cuerpo, no el cuello */
        p.z = b->wz;
        p.t = now;
        if (tr->n < MM_TRAIL_PTS) tr->p[tr->n++] = p;
        else {
            memmove(tr->p, tr->p + 1, sizeof(MMTrailPt) * (MM_TRAIL_PTS - 1));
            tr->p[MM_TRAIL_PTS - 1] = p;
        }
    }
    /* poda de muestras vencidas */
    for (int t = 0; t < MM_MAX_TRAILS; t++) {
        MMTrail *tr = &g_trails[t];
        if (tr->n <= 0) continue;
        int keep = 0;
        while (keep < tr->n && (now - tr->p[keep].t) > MM_TRAIL_LIFE) keep++;
        if (keep >= tr->n) { tr->n = 0; tr->pawn = 0; continue; }
        if (keep > 0) {
            memmove(tr->p, tr->p + keep, sizeof(MMTrailPt) * (size_t)(tr->n - keep));
            tr->n -= keep;
        }
    }
}

static void mm_trails_draw(CGContextRef ctx, CGRect bs)
{
    if (!g_have_view || !g_have_proj) return;
    double now = CACurrentMediaTime();
    int tema = mm_draw_opts()->theme;
    CGFloat W = bs.size.width, H = bs.size.height;

    /* v0.6.2: los segmentos se proyectan y clasifican una vez; después se
       agrupan en 6 niveles de alpha x 2 colores = 12 trazos por frame.
       Antes era un CGContextStrokePath por segmento (hasta ~800). */
    typedef struct { CGPoint a, b; unsigned char robot, lvl; } MMSeg;
    static MMSeg segs[MM_MAX_TRAILS * MM_TRAIL_PTS];
    int ns = 0;
    int cap = (int)(sizeof(segs) / sizeof(segs[0]));

    for (int t = 0; t < MM_MAX_TRAILS; t++) {
        MMTrail *tr = &g_trails[t];
        if (tr->n < 2) continue;
        for (int j = 1; j < tr->n && ns < cap; j++) {
            double age = now - tr->p[j].t;
            if (age < 0.0) age = 0.0;
            if (age > MM_TRAIL_LIFE) continue;
            CGFloat al = 0.55f * (CGFloat)(1.0 - age / MM_TRAIL_LIFE);
            if (al < 0.04f) continue;
            float pa[3] = { tr->p[j - 1].x, tr->p[j - 1].y, tr->p[j - 1].z };
            float pb[3] = { tr->p[j].x,     tr->p[j].y,     tr->p[j].z };
            CGPoint a, b;
            if (!mm_w2s(g_view_mtx, g_proj_mtx, pa, NO, W, H, &a, NULL, NULL, NULL)) continue;
            if (!mm_w2s(g_view_mtx, g_proj_mtx, pb, NO, W, H, &b, NULL, NULL, NULL)) continue;
            int lvl = (int)((al / 0.55f) * 5.0f + 0.5f);
            if (lvl < 0) lvl = 0;
            if (lvl > 5) lvl = 5;
            segs[ns].a = a; segs[ns].b = b;
            segs[ns].robot = (unsigned char)(tr->robot ? 1 : 0);
            segs[ns].lvl = (unsigned char)lvl;
            ns++;
        }
    }

    for (int rb = 0; rb < 2; rb++) {
        CGFloat cr, cg, cb;
        mm_esp_color(rb, tema, &cr, &cg, &cb);
        for (int lv = 0; lv < 6; lv++) {
            CGFloat al = 0.55f * ((CGFloat)lv + 0.5f) / 6.0f;
            int hay = 0;
            CGContextBeginPath(ctx);
            for (int s = 0; s < ns; s++) {
                if (segs[s].robot != rb || segs[s].lvl != lv) continue;
                CGContextMoveToPoint(ctx, segs[s].a.x, segs[s].a.y);
                CGContextAddLineToPoint(ctx, segs[s].b.x, segs[s].b.y);
                hay = 1;
            }
            if (hay) {
                CGContextSetLineWidth(ctx, 1.4);
                CGContextSetRGBStrokeColor(ctx, cr, cg, cb, al);
                CGContextStrokePath(ctx);
            }
        }
    }
}

/* Fase 1.6: anti-solape de etiquetas. El presupuesto baja con FOV angosto:
   menos texto cuando la camara esta muy zoomada. */
static BOOL mm_label_rect_free(const CGRect *used, int n, CGRect r)
{
    for (int i = 0; i < n; i++)
        if (CGRectIntersectsRect(used[i], r)) return NO;
    return YES;
}

static BOOL mm_label_claim(CGRect *used, int *n, int cap, CGRect r)
{
    if (!mm_label_rect_free(used, *n, r)) return NO;
    if (*n < cap) used[(*n)++] = r;
    return YES;
}

static int mm_declutter_budget(void)
{
    float f = g_fov_deg;
    if (!isfinite(f) || f < 5.0f) f = 60.0f;
    if (f < 50.0f) return 8;
    if (f < 80.0f) return 12;
    return 16;
}

@interface MMCanvasView : UIView @end

@implementation MMCanvasView
/* v0.7.0 (1.2): el lienzo solo captura toques dentro de la lista de objetivos
   y solo cuando la lista esta visible. Fuera de ahi devuelve nil y el toque
   sigue al juego, igual que antes. */
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (g_panel_open) return nil;
    if (!mm_def_bool(@"mm_esp_master", NO) ||
        !mm_def_bool(@"mm_x_targetlist", NO) ||
        mm_def_bool(@"mm_safe_mode", NO) || g_panic || mm_stream_effective()) return nil;
    if (CGRectContainsPoint(CGRectMake(MM_TL_BOX_X, MM_TL_BOX_Y,
                                       MM_TL_BOX_W, 16.0 + MM_TL_ROW_H * MM_TL_ROWS + 4.0),
                            point)) return self;
    return nil;
}

- (void)drawRect:(CGRect)rect
{
    /* v0.6.4: ritmo REAL de pintado (EMA). El FPS del display link no dice
       nada si el lienzo se salta frames por la huella. */
    {
        static double last = 0.0;
        double now = CACurrentMediaTime();
        if (last > 0.0 && now > last) {
            double inst = 1.0 / (now - last);
            if (inst > 0.0 && inst < 240.0)
                g_paint_fps = (g_paint_fps > 0.0) ? (g_paint_fps * 0.9 + inst * 0.1) : inst;
        }
        last = now;
        g_paints++;
    }
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (ctx == NULL) return;

    CGRect bs = self.bounds;
    /* v0.6.2: fuentes cacheadas (antes se creaban en cada frame). */
    UIFont *fNombre = mm_font_name();
    UIFont *fDist = mm_font_dist();

    const MMDrawOpts *o = mm_draw_opts();
    BOOL conCajas  = o->box;          /* v0.2.5 */
    BOOL conNombre = o->name;
    BOOL conDist   = o->dist;
    BOOL conLineas = o->lines;
    BOOL lineasTop = o->linesTop;     /* v0.2.5 */
    BOOL conSalud  = o->health;
    BOOL conRelleno = o->fill;
    int  estiloCaja = o->boxStyle;
    int  tema       = o->theme;

    /* v0.4.0: features de overlay. Las independientes de las cajas (crosshair,
       anillo de aim, FPS) se dibujan aunque no haya pawns; las por-pawn
       (head dot, color por distancia, vida baja) se leen aca y se usan abajo. */
    BOOL conCross   = o->cross;
    BOOL conAimRing = o->aimring;
    BOOL conFps     = o->fps;
    BOOL conHead    = o->head;
    BOOL conDistCol = o->distcol;
    BOOL conLowHp   = o->lowhp;
    CGFloat ar = 0.2, ag = 1.0, ab = 0.58, aalpha = 1.0;
    [mm_neon_green() getRed:&ar green:&ag blue:&ab alpha:&aalpha];

    /* v0.4.2: features nuevas de solo-lectura (reusan g_boxes). */
    BOOL conPriority = o->priority;
    BOOL conWarn     = o->warn;
    BOOL conArrow    = o->arrow;
    int  crossStyle  = o->crossStyle;
    int  maxN        = o->maxN;

    /* v0.7.3 (perf): auto-cap de maxN cuando el operador acumula muchas
       capas por caja. Cada feature per-pawn (cajas/nombre/dist/head/distcol/
       lowhp/salud/lineas/altura) stackea CGContext ops y texto; con 20+
       pawns y 7+ features ON el gasto crece lineal. Si el operador no eligio
       closest-N explicito, se recorta a 24 (sigue siendo mas que suficiente
       para competitivo). Thermal serio aprieta mas. No toca prefs. */
    {
        int feats = (int)conCajas + (int)conNombre + (int)conDist + (int)conHead
                  + (int)conDistCol + (int)conLowHp + (int)conSalud + (int)conLineas
                  + (int)o->height;
        int cap = 0;
        if (g_thermal_level >= 3)      cap = 10;
        else if (g_thermal_level >= 2) cap = 16;
        else if (feats >= 7)           cap = 24;
        if (cap > 0 && (maxN <= 0 || maxN > cap)) maxN = cap;
    }

    /* v0.4.4 (Fase 1): overlay de informacion — radar 2D, altura, telemetria.
       Solo lectura; reusan el world-pos que el colector ya calculo. */
    BOOL conRadar   = o->radar;
    BOOL conHeight  = o->height;
    BOOL conTelem   = o->telem;
    /* Fase 1: brujula, estelas y anti-solape (cero lecturas nuevas). */
    BOOL conBearings = o->bearings;
    BOOL conTrails   = o->trails;
    BOOL conDeclutter = o->declutter;

    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextSetLineJoin(ctx, kCGLineJoinRound);

    if (conAimRing) mm_draw_aimring(ctx, bs, ar, ag, ab);
    if (conCross)   mm_draw_crosshair(ctx, bs, crossStyle, ar, ag, ab);
    if (conFps)     mm_draw_fps(bs);
    mm_draw_fov_circle(ctx, bs, ar, ag, ab);   /* C-11 */
    if (conRadar)   mm_draw_radar(ctx, bs, ar, ag, ab);
    if (conTelem)   mm_draw_telem(bs);
    if (o->targetList) mm_draw_target_list(ctx, bs);
    if (conTrails)  mm_trails_draw(ctx, bs);
    if (conBearings) mm_draw_bearings(ctx, bs);

    /* v0.5.0: aunque no haya cajas (todos los enemigos detras de la camara),
       el lienzo sigue: la flecha "fuera de pantalla" tiene que poder salir. */
    if (g_box_count <= 0 && g_track_count <= 0) return;

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
        distThresh = mm_math_closest_threshold(ds, n, maxN);
    }

    /* Fase 1.6: con declutter, las cajas se recorren de mas cerca a mas lejos;
       las etiquetas cercanas reclaman el espacio y las lejanas se omiten. */
    int order[MM_MAX_BOXES];
    int orderN = 0;
    if (conDeclutter) {
        for (int i = 0; i < g_box_count && i < MM_MAX_BOXES; i++) {
            if (!g_boxes[i].alive) continue;
            if (maxN > 0 && g_boxes[i].dist > distThresh + 0.01f) continue;
            order[orderN++] = i;
        }
        for (int a = 1; a < orderN; a++) {
            int k = order[a]; float kd = g_boxes[k].dist;
            int j = a - 1;
            while (j >= 0 && g_boxes[order[j]].dist > kd) {
                order[j + 1] = order[j]; j--;
            }
            order[j + 1] = k;
        }
    }
    int labelBudget = conDeclutter ? mm_declutter_budget() : 999;
    CGRect usedLabels[MM_MAX_BOXES * 3];
    int usedN = 0;

    /* v0.3.4: colores y atributos de texto se preparan UNA vez por frame.
       Antes se creaba un NSShadow + dos NSDictionary por cada caja a 30 fps;
       con muchas cajas eso generaba presion de autorelease innecesaria. */
    CGFloat crJug = 1.00, cgJug = 0.25, cbJug = 0.25;
    CGFloat crBot = 1.00, cgBot = 0.25, cbBot = 0.25;
    mm_esp_color(0, tema, &crJug, &cgJug, &cbJug);
    mm_esp_color(1, tema, &crBot, &cgBot, &cbBot);

    NSShadow *txtShadow = mm_txt_shadow();

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

    /* v0.6.2: altura por rol, no un NSDictionary por caja y por frame. */
    NSDictionary *heightJug = @{ NSFontAttributeName: fDist,
        NSForegroundColorAttributeName:
            [UIColor colorWithRed:crJug green:cgJug blue:cbJug alpha:0.92],
        NSShadowAttributeName: txtShadow };
    NSDictionary *heightBot = @{ NSFontAttributeName: fDist,
        NSForegroundColorAttributeName:
            [UIColor colorWithRed:crBot green:cgBot blue:cbBot alpha:0.92],
        NSShadowAttributeName: txtShadow };

    int passes = conDeclutter ? orderN : MIN(g_box_count, MM_MAX_BOXES);
    for (int oi = 0; oi < passes; oi++) {
        int i = conDeclutter ? order[oi] : oi;
        MMEspBox *b = &g_boxes[i];
        if (!b->alive) continue;
        if (maxN > 0 && b->dist > distThresh + 0.01f) continue;   /* v0.4.2: closest-N */
        /* v0.7.3 (perf): culling off-screen con margen. El colector proyecta
           incluso lo que cae fuera (para la flecha de borde); aqui lo saltamos
           cuando la caja no tiene nada que pintar. Margen de 200 px para no
           cortar nombres/salud/head que cuelgan afuera de la caja. Si el
           operador tiene la flecha fuera-de-pantalla ON, NO cull: la flecha
           tiene que poder apuntar al pawn aunque este muy afuera. */
        if (!conArrow) {
            if (b->x + b->w < -200.0f || b->x > bs.size.width + 200.0f ||
                b->y + b->h < -200.0f || b->y > bs.size.height + 200.0f) continue;
        }
        CGRect r = CGRectMake(b->x, b->y, b->w, b->h);

        CGFloat cr = b->robot ? crBot : crJug;
        CGFloat cg = b->robot ? cgBot : cgJug;
        CGFloat cb = b->robot ? cbBot : cbJug;

        /* v0.4.0 (#4 color por distancia): atenua y vira a frio al alejarse. */
        if (conDistCol && b->dist > 0.5f) {
            float rng = o->range;   /* v0.6.4: sin lookup a NSUserDefaults por caja */
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

        /* v0.7.0 (1.2): objetivo elegido en la lista -> aro blanco en la caja. */
        if (g_tl_sel_pawn != 0 && b->pawn == g_tl_sel_pawn) {
            CGContextSetLineWidth(ctx, 2.6);
            CGContextSetRGBStrokeColor(ctx, 1.0, 1.0, 1.0, 0.95);
            mm_esp_box_path(ctx, CGRectInset(r, -3.0, -3.0), estiloCaja);
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
        /* v0.4.2 (flecha off-screen): si la caja cae fuera de pantalla, flecha al borde. */
        if (conArrow) {
            CGFloat mx = CGRectGetMidX(r), my = CGRectGetMidY(r);
            if (mx < 0.0 || mx > bs.size.width || my < 0.0 || my > bs.size.height)
                mm_draw_edge_arrow(ctx, bs, mx, my, cr, cg, cb);
        }
        /* v0.4.4 (altura): diferencia de altura vs. el jugador local (+ arriba / - abajo).
           Fase 1.6: con declutter, la etiqueta solo se dibuja si no pisa otra. */
        BOOL allowLabels = (!conDeclutter || labelBudget > 0);
        BOOL drewLabel = NO;
        if (conHeight && g_have_local && allowLabels) {
            float dh = b->wy - g_local_pos[1];
            int vm = (int)(fabsf(dh) + 0.5f);
            if (dh < 0.0f) vm = -vm;
            NSString *hhs = mm_cached_hgt(vm);   /* v0.6.4: sin alloc por frame */
            NSDictionary *hha = b->robot ? heightBot : heightJug;
            CGFloat hx = CGRectGetMaxX(r) + 2.0, hy = CGRectGetMidY(r) - 5.0;
            CGSize hsz = mm_text_size(hhs, hha, 1);
            CGRect lr = CGRectMake(hx - 1.0, hy - 1.0, hsz.width + 2.0, hsz.height + 2.0);
            BOOL drawH = !conDeclutter ||
                mm_label_claim(usedLabels, &usedN,
                               (int)(sizeof(usedLabels) / sizeof(usedLabels[0])), lr);
            if (drawH) {
                [hhs drawAtPoint:CGPointMake(hx, hy) withAttributes:hha];
                drewLabel = YES;
            }
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
        if (conNombre && allowLabels) {
            NSString *nm = nil;
            if (b->hasName) nm = mm_cached_name(b->pawn, b->name);
            if (nm == nil || nm.length == 0)
                nm = (b->robot ? @"BOT" : @"JUGADOR");
            CGSize ns = mm_text_size(nm, attr, 0);
            CGFloat nx = CGRectGetMidX(r) - ns.width / 2.0;
            nx = MAX(2.0, MIN(bs.size.width - ns.width - 2.0, nx));
            CGFloat ny = r.origin.y - ns.height - 1.0;
            if (ny < 0.0) ny = 0.0;
            CGRect lr = CGRectMake(nx - 1.0, ny - 1.0, ns.width + 2.0, ns.height + 2.0);
            BOOL drawN = !conDeclutter ||
                mm_label_claim(usedLabels, &usedN,
                               (int)(sizeof(usedLabels) / sizeof(usedLabels[0])), lr);
            if (drawN) {
                [nm drawAtPoint:CGPointMake(nx, ny) withAttributes:attr];
                drewLabel = YES;
            }
        }
        if (conDist && b->dist > 0.5f && allowLabels) {
            NSDictionary *dattr = b->robot ? distBot : distJug;
            NSString *ds = mm_cached_dist((int)(b->dist + 0.5f));
            CGSize dsz = mm_text_size(ds, dattr, 1);
            CGFloat dx = CGRectGetMidX(r) - dsz.width / 2.0;
            dx = MAX(2.0, MIN(bs.size.width - dsz.width - 2.0, dx));
            CGFloat dy = CGRectGetMaxY(r) + 2.0;
            if (dy + dsz.height > bs.size.height - 2.0)
                dy = MAX(0.0, r.origin.y - dsz.height - 1.0);
            CGRect lr = CGRectMake(dx - 1.0, dy - 1.0, dsz.width + 2.0, dsz.height + 2.0);
            BOOL drawD = !conDeclutter ||
                mm_label_claim(usedLabels, &usedN,
                               (int)(sizeof(usedLabels) / sizeof(usedLabels[0])), lr);
            if (drawD) {
                [ds drawAtPoint:CGPointMake(dx, dy) withAttributes:dattr];
                drewLabel = YES;
            }
        }
        /* 2026-11: etiqueta de estado (CUR/INV/VEH/ADS) + municion, debajo de
           la distancia. Cadena cacheada: cero alloc por frame. */
        if ((b->tags != 0 || b->ammoMax > 0 || b->armor > 0) && allowLabels) {
            NSString *ts = mm_cached_tags(b->tags, b->ammo, b->ammoMax, b->armor);
            if (ts.length > 0) {
                NSDictionary *tattr = b->robot ? distBot : distJug;
                CGSize tsz = mm_text_size(ts, tattr, 1);
                CGFloat tx = CGRectGetMidX(r) - tsz.width / 2.0;
                tx = MAX(2.0, MIN(bs.size.width - tsz.width - 2.0, tx));
                CGFloat ty = CGRectGetMaxY(r) + 2.0 + 10.0;
                if (ty + tsz.height > bs.size.height - 2.0)
                    ty = MAX(0.0, r.origin.y - tsz.height - 12.0);
                CGRect lr = CGRectMake(tx - 1.0, ty - 1.0, tsz.width + 2.0, tsz.height + 2.0);
                BOOL drawT = !conDeclutter ||
                    mm_label_claim(usedLabels, &usedN,
                                   (int)(sizeof(usedLabels) / sizeof(usedLabels[0])), lr);
                if (drawT) {
                    [ts drawAtPoint:CGPointMake(tx, ty) withAttributes:tattr];
                    drewLabel = YES;
                }
            }
        }
        if (conDeclutter && drewLabel) labelBudget--;
    }

    /* v0.5.0: flecha a enemigos SIN caja en pantalla — detras de la camara o
       muy fuera del cuadro — con el toggle "Flecha fuera de pantalla". Antes
       el enemigo a la espalda simplemente desaparecia sin dejar rastro. */
    if (conArrow) {
        for (int i = 0; i < g_track_count && i < MM_MAX_TRACKS; i++) {
            MMTrack *tk = &g_tracks[i];
            if (!tk->alive || tk->proj) continue;
            CGFloat acr = tk->robot ? crBot : crJug;
            CGFloat acg = tk->robot ? cgBot : cgJug;
            CGFloat acb = tk->robot ? cbBot : cbJug;
            if (tk->behind) {
                /* direccion en espacio de camara: x derecha, y arriba
                   (la pantalla invierte y). Si queda justo detras: abajo. */
                CGFloat dx = (CGFloat)tk->vx, dy = (CGFloat)(-tk->vy);
                if (fabs(dx) < 0.02 && fabs(dy) < 0.02) { dx = 0.0; dy = 1.0; }
                mm_draw_edge_arrow(ctx, bs, bs.size.width / 2.0 + dx * 1000.0,
                                   bs.size.height / 2.0 + dy * 1000.0,
                                   acr, acg, acb);
            } else if (tk->has_sx) {
                mm_draw_edge_arrow(ctx, bs, (CGFloat)tk->sx, (CGFloat)tk->sy,
                                   acr, acg, acb);
            }
        }
    }

    /* v0.4.2 (aviso de enemigo cercano): borde rojo pulsante si el mas cercano < 30 m. */
    if (conWarn && priIdx >= 0 && priDist < 30.0f) mm_draw_warn(ctx, bs);
}
@end

/*---------------------------------------------------------------------------
 * Callbacks de la UI (un singleton para target/action).
 *--------------------------------------------------------------------------*/
/*---------------------------------------------------------------------------
 * v0.6.4: idioma de la UI y vibracion.
 *  - mm_tr traduce SOLO las cadenas del panel y del overlay; el idioma se lee
 *    al construir la UI, por eso el selector avisa "reiniciar".
 *  - mm_haptic usa generadores cacheados; con el toggle OFF no se instancian.
 *--------------------------------------------------------------------------*/
static int mm_lang(void)
{
    static int l = -1;
    if (l < 0) l = (mm_def_float(@"mm_lang", 0.0f) >= 1.0f) ? 1 : 0;
    return l;
}

static NSString *mm_tr(NSString *es)
{
    if (mm_lang() != 1) return es;
    static NSDictionary *t = nil;
    if (t == nil) t = @{
        @"ESP maestro": @"ESP master",
        @"Cajas": @"Boxes",
        @"Jugadores": @"Players",
        @"Bots": @"Bots",
        @"Nombres": @"Names",
        @"Distancia": @"Distance",
        @"Salud": @"Health",
        @"Lineas": @"Lines",
        @"Lineas desde arriba": @"Lines from top",
        @"Relleno": @"Fill",
        @"Rango ESP (m)": @"ESP range (m)",
        @"Stream Mode (ocultar UI)": @"Stream Mode (hide UI)",
        @"ESP EN PANTALLA": @"ESP ON SCREEN",
        @"Contador JUG / BOT": @"PLAYER / BOT counter",
        @"Estilo de caja": @"Box style",
        @"Completa": @"Full",
        @"Esquinas": @"Corners",
        @"Tema de color": @"Color theme",
        @"Clasico": @"Classic",
        @"Hielo": @"Ice",
        @"Fuego": @"Fire",
        @"Neon": @"Neon",
        @"Blanco": @"White",
        @"Cuenta invitado": @"Guest account",
        @"Restablecer invitado": @"Reset guest",
        @"Perfiles de configuracion": @"Config profiles",
        @"Guardar": @"Save",
        @"Cargar": @"Load",
        @"Escribir status TXT ahora": @"Write status TXT now",
        @"Crosshair (mira)": @"Crosshair",
        @"Anillo de aim": @"Aim ring",
        @"Punto en la cabeza": @"Head dot",
        @"Color por distancia": @"Distance color",
        @"Resaltar vida baja": @"Highlight low HP",
        @"Medidor de FPS": @"FPS meter",
        @"Prioridad (mas cercano)": @"Priority (nearest)",
        @"Aviso enemigo cerca": @"Nearby enemy warning",
        @"Flecha fuera de pantalla (detras)": @"Off-screen arrow (behind)",
        @"Radar 2D": @"2D radar",
        @"Indicador de altura": @"Height indicator",
        @"Telemetria": @"Telemetry",
        @"Brujula de bearings": @"Bearing compass",
        @"Estelas (ultimos 2 s)": @"Trails (last 2 s)",
        @"Anti-solape de etiquetas": @"Label declutter",
        @"Radar: arriba = mi vista": @"Radar: up = my view",
        @"Lista de objetivos": @"Target list",
        @"Estilo de crosshair": @"Crosshair style",
        @"Cruz": @"Cross",
        @"Punto": @"Dot",
        @"Circulo": @"Circle",
        @"Todo": @"All",
        @"Limite de objetivos (0 = todos)": @"Target limit (0 = all)",
        @"Tema del menu": @"Menu theme",
        @"Opacidad del menu": @"Menu opacity",
        @"Escala del menu": @"Menu scale",
        @"ESP de granadas": @"Grenade ESP",
        @"ESP de loot / vehiculos": @"Loot / vehicle ESP",
        @"Prediccion de proxima zona (BR)": @"Next zone prediction (BR)",
        @"Modo seguro (apaga overlay)": @"Safe mode (overlay off)",
        @"Barra rapida (3 toggles)": @"Quick bar (3 toggles)",
        @"Vibracion al tocar": @"Haptics",
        @"Idioma (reiniciar)": @"Language (restart)",
        @"Auto-test del overlay": @"Overlay self-test",
        @"Perfiles (5 slots)": @"Profiles (5 slots)",
        @"Nombre": @"Name",
        @"Exportar": @"Export",
        @"Importar": @"Import",
        @"Presets contextuales": @"Context presets",
        @"Bajo": @"Low-end",
        @"Stream auto al grabar": @"Auto stream when recording",
        @"Guard de captura (experimental)": @"Capture guard (experimental)",
        @"Licencia (observacion)": @"License (observation)",
        @"Telemetria local (opt-in)": @"Local telemetry (opt-in)",
        @"Pegar token": @"Paste token",
        @"Revalidar": @"Revalidate",
        @"Paleta daltonismo": @"Colorblind palette",
        @"Normal": @"Normal",
        @"Marca HWID en INFO (opt-in)": @"HWID mark in INFO (opt-in)",
        @"Copiar self-test": @"Copy self-test",
        @"Acento 1": @"Accent 1",
        @"Acento 2": @"Accent 2",
        @"Temas guardados": @"Saved themes",
        @"Temas": @"Themes",
        @"Color de acento (custom)": @"Accent color (custom)",
        @"Modo seguro forzado": @"Safe mode forced",
        @"Dos arranques sin cierre limpio seguidos. El overlay quedo apagado; revisa MISC.":
            @"Two unclean launches in a row. The overlay is off; check MISC.",
        @"CAJAS": @"BOXES",
        @"NOMBRES": @"NAMES",
        @"Debug (status file): ON  -  tocar = escribir TXT": @"Debug (status file): ON  -  tap = write TXT",
        @"Debug (status file): OFF  -  tocar = activar": @"Debug (status file): OFF  -  tap = enable",
        @"Escrito: Documents/modmenu_status.txt": @"Written: Documents/modmenu_status.txt",
        @"ON  -  tocar = escribir TXT": @"ON  -  tap = write TXT",
        @"OFF  -  tocar = activar": @"OFF  -  tap = enable",
        @"Guardar en P": @"Save to P",
        @"Aimbot configurable desde COMBATE.\n\n":
            @"Aimbot is not toggleable, for safety.\n\n",
        @"Activar todas las opciones no da problemas de seguridad;\nel costo es rendimiento (FPS) en el dispositivo.\n\n":
            @"Enabling every option is not a security problem;\nthe cost is device performance (FPS).\n\n",
        @"Proyecto desarrollado por\nJose Lopez - Ing. de Sistemas\n\n":
            @"Project developed by\nJose Lopez - Systems Engineer\n\n",
        @"Contacto:": @"Contact:",
        @"Listo": @"Done",
        /* v0.8.0: panel horizontal CLOUD */
        @"OBJETIVOS": @"TARGETS",
        @"LECTURA": @"READOUT",
        @"CONTROL": @"CONTROL",
        @"CAJA": @"BOX",
        @"MIRA": @"CROSSHAIR",
        @"MUNDO": @"WORLD",
        @"RADAR": @"RADAR",
        @"HUD": @"HUD",
        @"PANTALLA": @"DISPLAY",
        @"PRESETS": @"PRESETS",
        @"PERFILES": @"PROFILES",
        @"ESTILO DEL MENU": @"MENU STYLE",
        @"ESTADO DEL SISTEMA": @"SYSTEM STATUS",
        @"SOPORTE Y CUENTA": @"SUPPORT & ACCOUNT",
        @"COMBATE": @"COMBAT",
        @"VISUAL": @"VISUAL",
        @"PERFIL": @"PROFILE",
        @"INFO": @"INFO",
        @"Todos": @"All",
        @"Rango ESP": @"ESP range",
        @"Limite cercano": @"Nearest limit",
        @"Prioridad cercano": @"Nearest priority",
        @"Tema ESP": @"ESP theme",
        @"Anti-solape": @"Declutter",
        @"Flecha fuera de pantalla": @"Off-screen arrow",
        @"Barra rapida": @"Quick bar",
        @"Guard de captura": @"Capture guard",
        @"Stream Mode": @"Stream Mode",
        @"Modo seguro": @"Safe mode",
        @"PANICO / OCULTAR": @"PANIC / HIDE",
        @"MP · MULTIJUGADOR": @"MP · MULTIPLAYER",
        @"BR · BATTLE ROYALE": @"BR · BATTLE ROYALE",
        @"STREAM · LIMPIO": @"STREAM · CLEAN",
        @"BAJO · RENDIMIENTO": @"LOW · PERFORMANCE",
        @"Magenta": @"Magenta",
        @"Aqua": @"Aqua",
        @"El aim es fijo y seguro en esta build.":
            @"Aim is fixed and safe in this build.",
        @"Radar y flechas no leen memoria extra.":
            @"Radar and arrows read no extra memory.",
        @"2 dedos en el header cambia de perfil.":
            @"2 fingers on the header switch profile.",
    };
    NSString *r = t[es];
    return (r != nil) ? r : es;
}

static void mm_haptic(int style)
{
    if (!mm_def_bool(@"mm_haptics", YES)) return;
    @try {
        if (style == 2) {
            static UISelectionFeedbackGenerator *sel = nil;
            if (sel == nil) sel = [[UISelectionFeedbackGenerator alloc] init];
            [sel selectionChanged];
        } else {
            static UIImpactFeedbackGenerator *imp = nil;
            if (imp == nil) imp = [[UIImpactFeedbackGenerator alloc] initWithStyle:
                                   (style == 1) ? UIImpactFeedbackStyleMedium
                                                : UIImpactFeedbackStyleLight];
            [imp impactOccurred];
        }
    } @catch (NSException *e) {}
}

@interface MMTargets : NSObject <UIColorPickerViewControllerDelegate>
+ (MMTargets *)shared;
- (void)onFrame:(CADisplayLink *)link;
- (void)onPanelPan:(UIPanGestureRecognizer *)g;
- (void)onSeg:(UISegmentedControl *)s;
- (void)onNav:(UIButton *)b;
- (void)onTelegram;
- (void)onBoxStyle:(UISegmentedControl *)s;
- (void)onTheme:(UISegmentedControl *)s;
- (void)onThemeAccent:(UISegmentedControl *)s;
- (void)onMenuOpacity:(UISlider *)s;
- (void)onMenuScale:(UISlider *)s;
- (void)onCrossStyle:(UISegmentedControl *)s;
- (void)onMaxN:(UISlider *)s;
- (void)onAimStrength:(UISlider *)s;
- (void)onAimFov:(UISlider *)s;
- (void)onAimSmooth:(UISlider *)s;
- (void)onAimHeight:(UISlider *)s;
- (void)onCamFov:(UISlider *)s;
- (void)onAimKeyDown:(UIButton *)b;
- (void)onAimKeyUp:(UIButton *)b;
- (void)onPanic:(UILongPressGestureRecognizer *)g;
- (void)onProfileSlot:(UISegmentedControl *)s;
- (void)onProfileSave;
- (void)onProfileLoad;
- (void)onGuestReset;
- (void)onQuick:(UIButton *)b;
- (void)onHeaderDoubleTap:(UITapGestureRecognizer *)g;
- (void)onHeaderSwipe:(UISwipeGestureRecognizer *)g;
- (void)onSelfTest:(UIButton *)b;
- (void)onSelfTestCopy;
- (void)onTargetListTap:(UITapGestureRecognizer *)g;
- (void)onButtonDoubleTap:(UITapGestureRecognizer *)g;
- (void)onButtonTripleTap:(UITapGestureRecognizer *)g;
- (void)onProfileSwipe:(UISwipeGestureRecognizer *)g;
- (void)onThemeSlot:(UISegmentedControl *)s;
- (void)onThemeSave;
- (void)onThemeLoad;
- (void)onLang:(UISegmentedControl *)s;
- (void)onProfileName;
- (void)onProfileExport;
- (void)onProfileImport;
- (void)onPreset:(UIButton *)b;
- (void)onColorMode:(UISegmentedControl *)s;
- (void)onAccentPick:(UIButton *)b;
- (void)onLicensePaste;
- (void)onLicenseCheck;
@end

@implementation MMTargets
+ (MMTargets *)shared
{
    static MMTargets *s = nil;
    if (s == nil) s = [[MMTargets alloc] init];
    return s;
}

- (void)onTap { mm_haptic(0); mm_set_panel(!g_panel_open); }

/* v0.3.3: contacto de Telegram desde INFO. URL publica, sin APIs privadas. */
- (void)onTelegram
{
    @try {
        NSURL *u = [NSURL URLWithString:@"https://t.me/l0pez9801"];
        if (u == nil) return;
        [[UIApplication sharedApplication] openURL:u options:@{} completionHandler:nil];
    } @catch (NSException *e) {
        MM_LOG(@"%s telegram: %@", MM_TAG, e.reason);
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
        if (g_quickbar != nil && !g_quickbar.hidden) mm_layout_quickbar();
        if (g.state == UIGestureRecognizerStateEnded) {
            NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
            [ud setFloat:c.x forKey:@"mm_btn_x"];
            [ud setFloat:c.y forKey:@"mm_btn_y"];
            if (g_panel_open) mm_position_panel();
        }
    } @catch (NSException *e) {
        MM_LOG(@"%s onPan: %@", MM_TAG, e.reason);
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
        /* v0.8.0: bounds no refleja la escala aplicada por transform. */
        CGFloat sx = fabs(p.transform.a) > 0.01 ? fabs(p.transform.a) : 1.0;
        CGFloat sy = fabs(p.transform.d) > 0.01 ? fabs(p.transform.d) : 1.0;
        CGFloat hw = p.bounds.size.width  * sx / 2.0;
        CGFloat hh = p.bounds.size.height * sy / 2.0;
        c.x = MAX(hw + 4.0, MIN(root.bounds.size.width  - hw - 4.0, c.x));
        c.y = MAX(hh + 24.0, MIN(root.bounds.size.height - hh - 4.0, c.y));
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
        MM_LOG(@"%s onPanelPan: %@", MM_TAG, e.reason);
    }
}

- (void)onSeg:(UISegmentedControl *)s
{
    NSInteger i = s.selectedSegmentIndex;
    if (g_p_esp   != nil) g_p_esp.hidden   = (i != 0);
    if (g_p_aim   != nil) g_p_aim.hidden   = (i != 1);
    if (g_p_vis   != nil) g_p_vis.hidden   = (i != 2);
    if (g_p_misc  != nil) g_p_misc.hidden  = (i != 3);
    if (g_p_info  != nil) g_p_info.hidden  = (i != 4);
    /* v0.8.0: el selector real es horizontal; g_seg queda solo como estado
       para conservar los gestos y la persistencia existente. */
    for (NSUInteger n = 0; n < g_nav_btns.count; n++) {
        UIButton *b = g_nav_btns[n];
        BOOL on = ((NSInteger)n == i);
        b.backgroundColor = on
            ? [mm_neon_green() colorWithAlphaComponent:0.16]
            : [UIColor colorWithWhite:1.0 alpha:0.035];
        { UIView *nb = [b viewWithTag:99]; if (nb != nil) nb.hidden = !on; }
        b.layer.borderColor = (on
            ? [mm_neon_green() colorWithAlphaComponent:0.72]
            : [UIColor colorWithWhite:1.0 alpha:0.07]).CGColor;
        [b setTitleColor:(on ? [UIColor whiteColor]
                            : [UIColor colorWithWhite:0.64 alpha:1.0])
                forState:UIControlStateNormal];
    }
}

- (void)onNav:(UIButton *)b
{
    if (g_seg == nil) return;
    NSInteger i = (NSInteger)b.tag;
    if (i < 0 || i >= (NSInteger)g_seg.numberOfSegments) return;
    g_seg.selectedSegmentIndex = i;
    [self onSeg:g_seg];
    mm_haptic(0);
}

- (void)onSwitch:(UISwitch *)s
{
    NSString *k = s.accessibilityIdentifier;
    if (k.length == 0) return;
    mm_haptic(2);
    [[NSUserDefaults standardUserDefaults] setBool:s.on forKey:k];
    mm_opts_invalidate();
    if ([k isEqualToString:@"mm_esp_master"]) mm_apply_esp_lock();
    if ([k isEqualToString:@"mm_esp_count"]) mm_refresh_count_glass();
    if ([k isEqualToString:@"mm_x_targetlist"]) {
        if (!s.on) g_tl_sel_pawn = 0;
        if (g_esp != nil) [g_esp setNeedsDisplay];
    }
    if ([k isEqualToString:@"mm_build_mark"] && g_info != nil) {
        g_info.attributedText = nil;
        mm_refresh_info();
    }
    if ([k isEqualToString:@"mm_safe_mode"]) mm_apply_safe_mode();
    if ([k isEqualToString:@"mm_quickbar"]) mm_refresh_quickbar();
    if ([k isEqualToString:@"mm_guard_capture"]) mm_place_ui();
    if ([k isEqualToString:@"mm_auto_stream"]) mm_apply_stream();
    if ([k isEqualToString:@"mm_x_aim_on"]) { g_aim_on = s.on; mm_aim_apply(); }
    if ([k isEqualToString:@"mm_x_aimlock"]) {   /* 0.14: write-struct */
        g_lock_on = s.on;
        if (!s.on) g_lock_active = 0;
    }
    if ([k isEqualToString:@"mm_x_aimlock"] || [k hasPrefix:@"mm_lock_"]) mm_lock_opts_sync();
    if ([k isEqualToString:@"mm_x_fast_reload"]) mm_reload_apply();   /* C-18 */
    if ([k isEqualToString:@"mm_x_aim_key"]) {
        g_aim_key_mode = s.on;
        mm_aim_apply();
        if (g_aimkey_btn != nil) g_aimkey_btn.hidden = !(g_aim_key_mode && g_aim_on);
    }
    if ([k isEqualToString:@"mm_stream"]) {
        mm_apply_stream();
        /* Al activarlo desde VIS se cierra el panel para dejar limpia la
           grabacion; al reabrirlo con el boton atenuado ya no se vuelve a
           cerrar solo (v0.3.0). */
        if (s.on) mm_set_panel(NO);
    }
    mm_write_status(@"ajuste");
}

/* v0.6.1: Debug como boton de fila completa. En algunos equipos el UISwitch
   pegado al borde no recibia el toque; un boton grande en la misma pagina
   (donde Guardar/Cargar si responden) no falla. Tocar alterna y, al prender,
   escribe el status en el acto. */
- (void)onDebugToggle:(UIButton *)b
{
    BOOL on = !mm_def_bool(@"mm_debug", NO);
    [[NSUserDefaults standardUserDefaults] setBool:on forKey:@"mm_debug"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    mm_refresh_debug_button();
    mm_write_status(on ? @"manual: debug ON" : @"manual: debug OFF");
}

- (void)onStatusNow:(UIButton *)b
{
    mm_haptic(1);
    /* Vuelca el status sin importar el estado del toggle (lo prende). */
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"mm_debug"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    mm_refresh_debug_button();
    /* C-25: sin probe BR (era un dump de ~500 ms al tocar el boton). */
    mm_write_status(@"manual: escribir status");
    [b setTitle:mm_tr(@"Escrito: Documents/modmenu_status.txt")
        forState:UIControlStateNormal];
    __weak UIButton *wb = b;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        if (wb != nil)
            [wb setTitle:mm_tr(@"Escribir status TXT ahora")
                 forState:UIControlStateNormal];
    });
}

/* v0.6.4: barra rapida. Cada boton invierte su clave y repinta; no abre el
   menu ni toca la UI del juego. */
- (void)onQuick:(UIButton *)b
{
    NSString *k = b.accessibilityIdentifier;
    if (k.length == 0) return;
    if ([k isEqualToString:@"__panic"]) {
        mm_haptic(1);
        mm_toggle_panic();
        return;
    }
    BOOL on = !mm_def_bool(k, NO);
    [[NSUserDefaults standardUserDefaults] setBool:on forKey:k];
    /* Encender cualquier atajo con el maestro apagado no mostraria nada:
       se enciende el maestro y se sincroniza el switch visible. */
    if (on && !mm_def_bool(@"mm_esp_master", NO)) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"mm_esp_master"];
        mm_apply_esp_lock();
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    mm_opts_invalidate();
    mm_sync_switches(g_panel);
    mm_haptic(0);
    mm_refresh_quickbar();
    mm_write_status(@"quickbar");
}

/* v0.6.4: gestos. Doble toque en el encabezado cierra; swipe sobre el selector
   cambia de pagina. El boton flotante conserva tap/arrastre/long-press. */
- (void)onHeaderDoubleTap:(UITapGestureRecognizer *)g
{
    if (g.state != UIGestureRecognizerStateEnded) return;
    mm_haptic(1);
    mm_set_panel(NO);
}

- (void)onHeaderSwipe:(UISwipeGestureRecognizer *)g
{
    if (g.state != UIGestureRecognizerStateEnded) return;
    if (g_seg == nil) return;
    NSInteger n = (NSInteger)g_seg.numberOfSegments;
    if (n <= 0) return;
    NSInteger i = (NSInteger)g_seg.selectedSegmentIndex;
    i += (g.direction == UISwipeGestureRecognizerDirectionLeft) ? 1 : -1;
    if (i < 0) i = n - 1;
    if (i >= n) i = 0;
    g_seg.selectedSegmentIndex = i;
    [self onSeg:g_seg];
    mm_haptic(2);
}

- (void)onSelfTest:(UIButton *)b
{
    mm_haptic(1);
    mm_self_test();
}

/* 1.20: copiar el ultimo self_test.txt al portapapeles (codigo copiable). */
- (void)onSelfTestCopy
{
    NSString *docs = mm_docs_dir();
    NSString *p = (docs.length > 0)
        ? [docs stringByAppendingPathComponent:@"self_test.txt"] : nil;
    NSString *s = p ? [NSString stringWithContentsOfFile:p
                                                encoding:NSUTF8StringEncoding
                                                   error:NULL] : nil;
    if (s.length == 0) {
        mm_show_alert(@"Auto-test", @"No hay self_test.txt. Corre el auto-test primero.");
        return;
    }
    [UIPasteboard generalPasteboard].string = s;
    mm_haptic(1);
    mm_show_alert(@"Auto-test", @"self_test.txt copiado al portapapeles.");
}

/* 1.2: tocar una fila de la lista resalta esa caja durante 6 s. */
- (void)onTargetListTap:(UITapGestureRecognizer *)g
{
    UIView *v = g.view;
    if (v == nil) return;
    CGPoint p = [g locationInView:v];
    int idx[MM_TL_ROWS];
    int n = mm_tl_order(idx, MM_TL_ROWS);
    int row = (int)floor((p.y - MM_TL_ROW_Y) / MM_TL_ROW_H);
    if (row < 0 || row >= n) {
        g_tl_sel_pawn = 0;
    } else {
        g_tl_sel_pawn = g_tracks[idx[row]].pawn;
        g_tl_sel_t = CACurrentMediaTime();
        mm_haptic(0);
    }
    if (g_esp != nil) [g_esp setNeedsDisplay];
}

/* 1.10: doble toque = maestro; triple toque = radar. Un toque sigue abriendo
   el panel. Los reconocedores se encadenan para no disparar el panel antes. */
- (void)onButtonDoubleTap:(UITapGestureRecognizer *)g
{
    BOOL on = !mm_def_bool(@"mm_esp_master", NO);
    [[NSUserDefaults standardUserDefaults] setBool:on forKey:@"mm_esp_master"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    mm_opts_invalidate();
    mm_apply_esp_lock();
    mm_sync_switches(g_panel);
    mm_haptic(on ? 1 : 0);
    mm_write_status(on ? @"master ON (doble toque)" : @"master OFF (doble toque)");
}

- (void)onButtonTripleTap:(UITapGestureRecognizer *)g
{
    BOOL on = !mm_def_bool(@"mm_x_radar", NO);
    [[NSUserDefaults standardUserDefaults] setBool:on forKey:@"mm_x_radar"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    mm_opts_invalidate();
    mm_sync_switches(g_panel);
    mm_haptic(1);
    if (g_esp != nil) [g_esp setNeedsDisplay];
    mm_write_status(on ? @"radar ON (triple toque)" : @"radar OFF (triple toque)");
}

/* 1.10: swipe de dos dedos en el encabezado -> perfil anterior/siguiente.
   Dos dedos para no chocar con el arrastre de una mano. */
- (void)onProfileSwipe:(UISwipeGestureRecognizer *)g
{
    int dir = (g.direction == UISwipeGestureRecognizerDirectionRight) ? -1 : 1;
    g_profile_slot = (g_profile_slot + dir + 5) % 5;
    if (g_profile_seg != nil) g_profile_seg.selectedSegmentIndex = g_profile_slot;
    if (g_profile_name_label != nil)
        g_profile_name_label.text = mm_profile_name(g_profile_slot);
    if (mm_profile_load(g_profile_slot)) {
        mm_mark_action("perfil swipe");
        mm_write_status(@"perfil por swipe");
        mm_haptic(1);
    } else {
        mm_haptic(0);
        mm_write_status(@"slot de perfil vacio");
    }
}

/* 1.16: temas guardados (3 slots). Guardan el acento activo y los dos colores
   custom; no tocan features ni posiciones. */
- (void)onThemeSlot:(UISegmentedControl *)s
{
    g_theme_slot = (int)s.selectedSegmentIndex;
    if (g_theme_slot < 0 || g_theme_slot > 2) g_theme_slot = 0;
}

- (void)onThemeSave
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *p = [NSString stringWithFormat:@"mm_thsave_%d_", g_theme_slot];
    [ud setInteger:[[NSUserDefaults standardUserDefaults] integerForKey:@"mm_theme_accent"]
            forKey:[p stringByAppendingString:@"accent"]];
    [ud setFloat:[ud floatForKey:@"mm_accent1_r"] forKey:[p stringByAppendingString:@"a1r"]];
    [ud setFloat:[ud floatForKey:@"mm_accent1_g"] forKey:[p stringByAppendingString:@"a1g"]];
    [ud setFloat:[ud floatForKey:@"mm_accent1_b"] forKey:[p stringByAppendingString:@"a1b"]];
    [ud setFloat:[ud floatForKey:@"mm_accent2_r"] forKey:[p stringByAppendingString:@"a2r"]];
    [ud setFloat:[ud floatForKey:@"mm_accent2_g"] forKey:[p stringByAppendingString:@"a2g"]];
    [ud setFloat:[ud floatForKey:@"mm_accent2_b"] forKey:[p stringByAppendingString:@"a2b"]];
    [ud synchronize];
    mm_haptic(1);
    mm_show_alert(@"Temas", [NSString stringWithFormat:@"Tema guardado en T%d.", g_theme_slot + 1]);
}

- (void)onThemeLoad
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *p = [NSString stringWithFormat:@"mm_thsave_%d_", g_theme_slot];
    if ([ud objectForKey:[p stringByAppendingString:@"accent"]] == nil) {
        mm_show_alert(@"Temas", [NSString stringWithFormat:@"T%d esta vacio.", g_theme_slot + 1]);
        return;
    }
    [ud setInteger:[ud integerForKey:[p stringByAppendingString:@"accent"]]
            forKey:@"mm_theme_accent"];
    [ud setFloat:[ud floatForKey:[p stringByAppendingString:@"a1r"]] forKey:@"mm_accent1_r"];
    [ud setFloat:[ud floatForKey:[p stringByAppendingString:@"a1g"]] forKey:@"mm_accent1_g"];
    [ud setFloat:[ud floatForKey:[p stringByAppendingString:@"a1b"]] forKey:@"mm_accent1_b"];
    [ud setFloat:[ud floatForKey:[p stringByAppendingString:@"a2r"]] forKey:@"mm_accent2_r"];
    [ud setFloat:[ud floatForKey:[p stringByAppendingString:@"a2g"]] forKey:@"mm_accent2_g"];
    [ud setFloat:[ud floatForKey:[p stringByAppendingString:@"a2b"]] forKey:@"mm_accent2_b"];
    [ud synchronize];
    if (g_panel != nil) {
        g_panel.layer.borderColor =
            [mm_neon_green() colorWithAlphaComponent:0.78].CGColor;
        g_panel.layer.shadowColor =
            [mm_neon_purple() colorWithAlphaComponent:0.90].CGColor;
    }
    mm_opts_invalidate();
    if (g_esp != nil) [g_esp setNeedsDisplay];
    mm_haptic(1);
    mm_write_status(@"tema guardado cargado");
}

- (void)onLang:(UISegmentedControl *)s
{
    [[NSUserDefaults standardUserDefaults] setFloat:(s.selectedSegmentIndex ? 1.0f : 0.0f)
                                            forKey:@"mm_lang"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    mm_haptic(2);
    mm_show_alert(@"Idioma / Language",
                  @"Se aplica al reiniciar el juego.\nApplies after the game restarts.");
}

- (void)onSlider:(UISlider *)s
{
    [[NSUserDefaults standardUserDefaults] setFloat:s.value forKey:s.accessibilityIdentifier];
    mm_opts_invalidate();
    if (g_range_val != nil)
        g_range_val.text = [NSString stringWithFormat:@"%d m", (int)(s.value + 0.5f)];
    mm_write_status(@"ajuste");
}

/* Fase C: fuerza de aim (relay en cod.__DATA). Persiste y escribe el slot. */
- (void)onAimStrength:(UISlider *)s
{
    g_aim_strength = s.value;
    [[NSUserDefaults standardUserDefaults] setFloat:s.value forKey:@"mm_x_aim_strength"];
    mm_aim_apply();
    mm_write_status(@"fuerza aim");
}

/* Fase C-2: FOV del aim (grados). <= fuera del cono el relay devuelve 0. */
- (void)onAimFov:(UISlider *)s
{
    g_aim_fov = s.value;
    [[NSUserDefaults standardUserDefaults] setFloat:s.value forKey:@"mm_x_aim_fov"];
    mm_aim_apply();
    mm_write_status(@"fov aim");
}

/* Fase C-4: suavizado del aim (0 = snap, 1 = lento). */
- (void)onAimSmooth:(UISlider *)s
{
    g_aim_smooth = s.value;
    [[NSUserDefaults standardUserDefaults] setFloat:s.value forKey:@"mm_x_aim_smooth"];
    mm_aim_apply();
    mm_write_status(@"suavizado aim");
}

/* 0.9.4: altura del punto de aim (metros sobre la posicion del pawn). */
- (void)onAimHeight:(UISlider *)s
{
    g_aim_height = s.value;
    [[NSUserDefaults standardUserDefaults] setFloat:s.value forKey:@"mm_aim_height"];
    mm_write_status(@"altura aim");
}

/* Fase C-7: FOV de camara (0 = no tocar; se reaplica a ~4 Hz). */
- (void)onCamFov:(UISlider *)s
{
    g_cam_fov = s.value;
    [[NSUserDefaults standardUserDefaults] setFloat:s.value forKey:@"mm_cam_fov"];
    if (g_cam_fov < 0.5f) g_cam_fov = 0.0f;
    mm_write_status(@"fov camara");
}

/* Fase C-3: Aim Key (mantener el boton AIM para que asista). */
- (void)onAimKeyDown:(UIButton *)b
{
    g_aim_key_held = YES;
    mm_aim_apply();
    b.backgroundColor = [UIColor colorWithRed:0.05 green:0.42 blue:0.22 alpha:0.95];
}

- (void)onAimKeyUp:(UIButton *)b
{
    g_aim_key_held = NO;
    mm_aim_apply();
    b.backgroundColor = [UIColor colorWithRed:0.02 green:0.08 blue:0.05 alpha:0.92];
}

/* v0.3.0: estilo de caja y tema de color del ESP. El lienzo lee la clave en
   cada repintado, asi que el cambio es inmediato. */
- (void)onBoxStyle:(UISegmentedControl *)s
{
    NSInteger v = (s.selectedSegmentIndex == 1) ? 1 : 0;
    [[NSUserDefaults standardUserDefaults] setInteger:v forKey:@"mm_esp_box_style"];
    mm_opts_invalidate();
    mm_write_status(@"estilo caja");
}

- (void)onTheme:(UISegmentedControl *)s
{
    NSInteger v = s.selectedSegmentIndex;
    if (v < 0 || v > 2) v = 0;
    [[NSUserDefaults standardUserDefaults] setInteger:v forKey:@"mm_esp_theme"];
    mm_opts_invalidate();
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
    if (g_panel != nil && !g_panel.hidden) mm_position_panel();
}

/* v0.4.2: estilo de crosshair + limite de objetivos (el lienzo los lee en vivo). */
- (void)onCrossStyle:(UISegmentedControl *)s
{
    [[NSUserDefaults standardUserDefaults] setFloat:(float)s.selectedSegmentIndex
                                             forKey:@"mm_x_cross_style"];
    mm_opts_invalidate();
    mm_write_status(@"crosshair style");
}
- (void)onMaxN:(UISlider *)s
{
    int n = (int)(s.value + 0.5f);
    if (n < 0) n = 0;
    if (n > MM_MAX_BOXES) n = MM_MAX_BOXES;
    s.value = (float)n;
    [[NSUserDefaults standardUserDefaults] setFloat:(float)n forKey:@"mm_x_maxn"];
    if (g_maxn_val != nil)
        g_maxn_val.text = (n == 0) ? mm_tr(@"Todos") : [NSString stringWithFormat:@"%d", n];
    mm_opts_invalidate();
}

/* v0.4.0 #8: kill-switch. Long-press en el boton -> oculta TODO al instante;
   otro long-press restaura. El modo panico se respeta en mm_esp_frame. */
- (void)onPanic:(UILongPressGestureRecognizer *)g
{
    if (g.state != UIGestureRecognizerStateBegan) return;
    mm_toggle_panic();
}

/* v0.4.0 #7 / v0.7.0 (1.8): perfiles de config (5 slots, nombre, presets). */
- (void)onProfileSlot:(UISegmentedControl *)s
{
    g_profile_slot = (int)s.selectedSegmentIndex;
    if (g_profile_name_label != nil)
        g_profile_name_label.text = mm_profile_name(g_profile_slot);
}
- (void)onProfileSave
{
    mm_profile_save(g_profile_slot);
    mm_mark_action("perfil guardar");
    mm_show_alert(@"Perfiles",
                  [NSString stringWithFormat:@"%@ guardado.", mm_profile_name(g_profile_slot)]);
}
- (void)onProfileLoad
{
    if (mm_profile_load(g_profile_slot)) {
        mm_mark_action("perfil cargar");
        mm_write_status(@"perfil cargado");
        mm_show_alert(@"Perfiles",
                      [NSString stringWithFormat:@"%@ cargado y aplicado.", mm_profile_name(g_profile_slot)]);
    } else {
        mm_show_alert(@"Perfiles",
                      [NSString stringWithFormat:@"%@ esta vacio. Guardalo primero.", mm_profile_name(g_profile_slot)]);
    }
}

- (void)onProfileName
{
    mm_haptic(0);
    UIAlertController *a = [UIAlertController
        alertControllerWithTitle:@"Nombre del perfil"
                         message:[NSString stringWithFormat:@"Slot %d", g_profile_slot + 1]
                  preferredStyle:UIAlertControllerStyleAlert];
    [a addTextFieldWithConfigurationHandler:^(UITextField *tf) {
        tf.text = mm_profile_name(g_profile_slot);
        tf.placeholder = @"MP / BR / Stream / Bajo";
    }];
    [a addAction:[UIAlertAction actionWithTitle:@"Cancelar"
                                          style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:@"Guardar"
                                          style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction *x) {
        UITextField *tf = a.textFields.firstObject;
        mm_profile_set_name(g_profile_slot, tf.text);
        if (g_profile_name_label != nil)
            g_profile_name_label.text = mm_profile_name(g_profile_slot);
    }]];
    [mm_top_vc() presentViewController:a animated:YES completion:nil];
}

- (void)onProfileExport
{
    mm_mark_action("perfil export");
    mm_profile_export();
}

- (void)onProfileImport
{
    mm_mark_action("perfil import");
    mm_profile_import();
}

/* 1.8: presets contextuales. tag 0 MP / 1 BR / 2 Stream / 3 Bajo. */
- (void)onPreset:(UIButton *)b
{
    mm_haptic(1);
    mm_profile_apply_preset((int)b.tag);
    static const char *names[] = { "preset MP", "preset BR", "preset Stream", "preset bajo" };
    if (b.tag >= 0 && b.tag < 4) mm_mark_action(names[b.tag]);
    mm_write_status(@"preset aplicado");
}

/* 1.16: paleta para daltonismo (0 normal / 1 protan-deutan / 3 tritan). */
- (void)onColorMode:(UISegmentedControl *)s
{
    int v = (int)s.selectedSegmentIndex;
    if (v < 0 || v > 2) v = 0;
    g_cb_mode = (v == 1) ? 1 : ((v == 2) ? 3 : 0);
    [[NSUserDefaults standardUserDefaults] setInteger:g_cb_mode forKey:@"mm_color_mode"];
    mm_opts_invalidate();
    if (g_esp != nil) [g_esp setNeedsDisplay];
    mm_write_status(@"paleta daltonismo");
}

/* 1.16: acento personalizado con UIColorPickerViewController (iOS 14+).
   tag 0 = acento primario, tag 1 = secundario. */
- (void)onAccentPick:(UIButton *)b
{
    mm_haptic(0);
    g_accent_slot = (b.tag == 1) ? 1 : 0;
    if (@available(iOS 14.0, *)) {
        UIColorPickerViewController *p = [[UIColorPickerViewController alloc] init];
        p.delegate = self;
        p.supportsAlpha = NO;
        p.selectedColor = (g_accent_slot == 1) ? mm_neon_purple() : mm_neon_green();
        UIViewController *vc = mm_top_vc();
        if (vc != nil) [vc presentViewController:p animated:YES completion:nil];
    }
}

- (void)colorPickerViewControllerDidSelectColor:(UIColorPickerViewController *)vc
{
    CGFloat r = 0.2f, g = 1.0f, b = 0.58f, a = 1.0f;
    @try { [vc.selectedColor getRed:&r green:&g blue:&b alpha:&a]; } @catch (NSException *e) {}
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *suf = (g_accent_slot == 1) ? @"2" : @"1";
    [ud setFloat:(float)r forKey:[@"mm_accent" stringByAppendingFormat:@"%@_r", suf]];
    [ud setFloat:(float)g forKey:[@"mm_accent" stringByAppendingFormat:@"%@_g", suf]];
    [ud setFloat:(float)b forKey:[@"mm_accent" stringByAppendingFormat:@"%@_b", suf]];
    [ud setInteger:MM_THEME_CUSTOM forKey:@"mm_theme_accent"];
    [ud synchronize];
    if (g_panel != nil) {
        g_panel.layer.borderColor = [mm_neon_green() colorWithAlphaComponent:0.78].CGColor;
        g_panel.layer.shadowColor = [mm_neon_purple() colorWithAlphaComponent:0.90].CGColor;
    }
    mm_opts_invalidate();
    if (g_esp != nil) [g_esp setNeedsDisplay];
    mm_write_status(g_accent_slot == 1 ? @"acento 2 custom" : @"acento 1 custom");
}

- (void)colorPickerViewControllerDidFinish:(UIColorPickerViewController *)vc
{
    mm_mark_action("acento custom");
}

/* 4.2: licencia in-menu sin red (token por portapapeles). */
- (void)onLicensePaste
{
    NSString *t = [UIPasteboard generalPasteboard].string;
    t = [t stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (t.length == 0) {
        mm_show_alert(@"Licencia", @"El portapapeles esta vacio.");
        return;
    }
    mm_lic_save_token(t);
    mm_lic_check();
    mm_refresh_license_label();
    mm_mark_action("licencia pegar");
    mm_show_alert(@"Licencia", mm_lic_short_status());
}

- (void)onLicenseCheck
{
    mm_lic_check();
    mm_refresh_license_label();
    mm_mark_action("licencia revisar");
    mm_show_alert(@"Licencia", mm_lic_short_status());
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

/*---------------------------------------------------------------------------
 * v0.7.0 (4.1): remote config FIRMADO, leido de Documents.
 *   fusion_config.json  +  fusion_config.json.sig (ES256, DER hex)
 * Sin firma valida no se aplica NADA. No hay red: el archivo lo entrega el
 * operador (Studio/share) y la firma se verifica con la clave del proyecto.
 * `disabled` apaga claves de feature en toda la flota sin recompilar la IPA.
 *--------------------------------------------------------------------------*/
static NSData *mm_hex_to_data(NSString *hex)
{
    if (hex.length == 0 || (hex.length & 1)) return nil;
    NSMutableData *d = [NSMutableData dataWithCapacity:hex.length / 2];
    for (NSUInteger i = 0; i < hex.length; i += 2) {
        unsigned int b = 0;
        NSString *pair = [hex substringWithRange:NSMakeRange(i, 2)];
        if (![[NSScanner scannerWithString:pair] scanHexInt:&b]) return nil;
        uint8_t c = (uint8_t)b;
        [d appendBytes:&c length:1];
    }
    return d;
}

static SecKeyRef mm_project_pubkey(void)
{
    NSData *pk = [NSData dataWithBytes:MM_LIC_PUBKEY length:sizeof(MM_LIC_PUBKEY)];
    NSDictionary *attr = @{ (__bridge id)kSecAttrKeyType:(__bridge id)kSecAttrKeyTypeECSECPrimeRandom,
                            (__bridge id)kSecAttrKeyClass:(__bridge id)kSecAttrKeyClassPublic,
                            (__bridge id)kSecAttrKeySizeInBits:@256 };
    CFErrorRef err = NULL;
    SecKeyRef key = SecKeyCreateWithData((__bridge CFDataRef)pk,
                                         (__bridge CFDictionaryRef)attr, &err);
    if (err) CFRelease(err);
    return key;
}

static BOOL mm_verify_bytes_der(NSData *data, NSData *der)
{
    if (data == nil || der == nil) return NO;
    SecKeyRef key = mm_project_pubkey();
    if (key == NULL) return NO;
    CFErrorRef err = NULL;
    BOOL ok = SecKeyVerifySignature(key, kSecKeyAlgorithmECDSASignatureMessageX962SHA256,
                                    (__bridge CFDataRef)data,
                                    (__bridge CFDataRef)der, &err);
    CFRelease(key);
    if (err) CFRelease(err);
    return ok;
}

static void mm_cfg_load(void)
{
    g_cfg_loaded = 1;
    @try {
        NSString *docs = mm_docs_dir();
        if (docs.length == 0) return;
        NSString *cf = [docs stringByAppendingPathComponent:@"fusion_config.json"];
        NSString *sf = [cf stringByAppendingString:@".sig"];
        NSData *raw = [NSData dataWithContentsOfFile:cf];
        if (raw == nil) return;                        /* sin config: normal */
        NSData *sigRaw = [NSData dataWithContentsOfFile:sf];
        if (sigRaw == nil) { g_cfg_error = @"sin .sig"; return; }
        NSDictionary *sj = [NSJSONSerialization JSONObjectWithData:sigRaw options:0 error:nil];
        NSString *hex = [sj isKindOfClass:[NSDictionary class]] ? sj[@"sig"] : nil;
        NSData *der = mm_hex_to_data(hex);
        if (!mm_verify_bytes_der(raw, der)) { g_cfg_error = @"firma invalida"; return; }

        NSDictionary *c = [NSJSONSerialization JSONObjectWithData:raw options:0 error:nil];
        if (![c isKindOfClass:[NSDictionary class]]) { g_cfg_error = @"json invalido"; return; }
        NSArray *dis = c[@"disabled"];
        if ([dis isKindOfClass:[NSArray class]]) {
            NSMutableSet *s = [NSMutableSet set];
            for (id k in dis) if ([k isKindOfClass:[NSString class]] && [k hasPrefix:@"mm_"])
                [s addObject:k];
            g_cfg_disabled = s;
        }
        NSArray *rev = c[@"revoked"];
        if ([rev isKindOfClass:[NSArray class]]) {
            NSMutableSet *s = [NSMutableSet set];
            for (id k in rev) if ([k isKindOfClass:[NSString class]] && [k length] >= 16)
                [s addObject:[k lowercaseString]];
            g_cfg_revoked = s;
        }
        NSString *latest = c[@"latest_pack"];
        if ([latest isKindOfClass:[NSString class]]) g_cfg_latest = latest;
        g_cfg_valid = 1;
    } @catch (NSException *e) {
        g_cfg_error = e.reason ?: @"excepcion";
    }
}

/* defaults con valor por defecto (sin el, boolForKey devuelve NO) */
static BOOL mm_def_bool(NSString *k, BOOL d)
{
    /* 4.1: kill switch de flota. Un config firmado puede apagar la clave. */
    if (g_cfg_disabled != nil && [g_cfg_disabled containsObject:k]) return NO;
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
                           @"mm_x_priority", @"mm_x_warn",
                           @"mm_x_arrow", @"mm_x_cross_style", @"mm_x_maxn",
                           @"mm_x_radar", @"mm_x_height", @"mm_x_telem",
                           @"mm_x_bearings", @"mm_x_trails", @"mm_x_declutter",
                           @"mm_x_radar_cam", @"mm_x_targetlist",
                           @"mm_auto_stream", @"mm_guard_capture",
                           @"mm_usage_optin", @"mm_build_mark" ];
        for (NSString *k in keys) [ud removeObjectForKey:k];
        [ud synchronize];
        mm_opts_invalidate();
    } @catch (NSException *e) {
        MM_LOG(@"[MODMENU] reset de opciones: %@", e.reason);
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
              @"mm_x_priority", @"mm_x_warn", @"mm_x_arrow",
              @"mm_x_cross_style", @"mm_x_maxn",
              @"mm_x_radar", @"mm_x_height", @"mm_x_telem",
              @"mm_x_bearings", @"mm_x_trails", @"mm_x_declutter",
              @"mm_x_radar_cam", @"mm_x_targetlist",
              @"mm_auto_stream", @"mm_guard_capture", @"mm_color_mode",
              @"mm_quickbar" ];   /* v0.7.0: lote 1.8/1.13/1.15/1.16 */
}

/* v0.7.0 (1.8): cinco slots con nombre, presets contextuales y JSON.
   Los presets escriben SOLO claves de feature; no tocan idioma, haptics ni
   posiciones. Nombre y JSON viven en NSUserDefaults / portapapeles. */
static NSString *mm_profile_name(int slot)
{
    NSString *k = [NSString stringWithFormat:@"mm_profile_name_%d", slot];
    NSString *n = [[NSUserDefaults standardUserDefaults] stringForKey:k];
    if (n.length == 0) n = [NSString stringWithFormat:@"P%d", slot + 1];
    return n;
}

static void mm_profile_set_name(int slot, NSString *name)
{
    NSString *n = [name stringByTrimmingCharactersInSet:
                        [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (n.length == 0) n = [NSString stringWithFormat:@"P%d", slot + 1];
    [[NSUserDefaults standardUserDefaults]
        setObject:n forKey:[NSString stringWithFormat:@"mm_profile_name_%d", slot]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

static void mm_preset_set(NSDictionary *d)
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    for (NSString *k in d) [ud setObject:d[k] forKey:k];
    [ud synchronize];
    mm_opts_invalidate();
}

static void mm_profile_apply_preset(int which)
{
    NSNumber *Y = @YES, *N = @NO;
    if (which == 0) {          /* MP: tiroteo, poco ruido */
        mm_preset_set(@{ @"mm_esp_master": Y, @"mm_esp_box": Y, @"mm_esp_players": Y,
            @"mm_esp_bots": Y, @"mm_esp_name": Y, @"mm_esp_dist": Y, @"mm_esp_health": Y,
            @"mm_esp_lines": N, @"mm_esp_lines_top": N, @"mm_esp_fill": N,
            @"mm_esp_range": @150.0f, @"mm_esp_count": N, @"mm_esp_box_style": @0.0f,
            @"mm_esp_theme": @0.0f, @"mm_stream": N, @"mm_auto_stream": Y,
            @"mm_x_cross": Y, @"mm_x_aimring": N, @"mm_x_head": N, @"mm_x_distcol": Y,
            @"mm_x_lowhp": Y, @"mm_x_fps": Y, @"mm_x_priority": Y, @"mm_x_warn": Y,
            @"mm_x_arrow": Y, @"mm_x_radar": N, @"mm_x_height": Y, @"mm_x_telem": N,
            @"mm_x_bearings": N, @"mm_x_trails": N, @"mm_x_declutter": Y,
            @"mm_x_radar_cam": Y, @"mm_x_targetlist": Y, @"mm_x_maxn": @0.0f });
    } else if (which == 1) {   /* BR: mapa y zona */
        mm_preset_set(@{ @"mm_esp_master": Y, @"mm_esp_box": Y, @"mm_esp_players": Y,
            @"mm_esp_bots": Y, @"mm_esp_name": Y, @"mm_esp_dist": Y, @"mm_esp_health": Y,
            @"mm_esp_lines": Y, @"mm_esp_lines_top": Y, @"mm_esp_fill": N,
            @"mm_esp_range": @300.0f, @"mm_esp_count": Y, @"mm_esp_box_style": @0.0f,
            @"mm_esp_theme": @1.0f, @"mm_stream": N, @"mm_auto_stream": Y,
            @"mm_x_cross": N, @"mm_x_aimring": N, @"mm_x_head": N, @"mm_x_distcol": Y,
            @"mm_x_lowhp": Y, @"mm_x_fps": Y, @"mm_x_priority": Y, @"mm_x_warn": Y,
            @"mm_x_arrow": Y, @"mm_x_radar": Y, @"mm_x_height": Y, @"mm_x_telem": Y,
            @"mm_x_bearings": Y, @"mm_x_trails": Y, @"mm_x_declutter": Y,
            @"mm_x_radar_cam": Y, @"mm_x_targetlist": Y, @"mm_x_maxn": @0.0f });
    } else if (which == 2) {   /* Stream: solo lo que se quiere grabar */
        mm_preset_set(@{ @"mm_esp_master": Y, @"mm_esp_box": Y, @"mm_esp_players": Y,
            @"mm_esp_bots": Y, @"mm_esp_name": Y, @"mm_esp_dist": Y, @"mm_esp_health": N,
            @"mm_esp_lines": N, @"mm_esp_lines_top": N, @"mm_esp_fill": N,
            @"mm_esp_range": @200.0f, @"mm_esp_count": N, @"mm_esp_box_style": @0.0f,
            @"mm_esp_theme": @2.0f, @"mm_stream": Y, @"mm_auto_stream": Y,
            @"mm_x_cross": N, @"mm_x_aimring": N, @"mm_x_head": N, @"mm_x_distcol": N,
            @"mm_x_lowhp": N, @"mm_x_fps": N, @"mm_x_priority": N, @"mm_x_warn": N,
            @"mm_x_arrow": N, @"mm_x_radar": N, @"mm_x_height": N, @"mm_x_telem": N,
            @"mm_x_bearings": N, @"mm_x_trails": N, @"mm_x_declutter": Y,
            @"mm_x_radar_cam": Y, @"mm_x_targetlist": N, @"mm_x_maxn": @0.0f });
    } else {                   /* Bajo: equipo justo */
        mm_preset_set(@{ @"mm_esp_master": Y, @"mm_esp_box": Y, @"mm_esp_players": Y,
            @"mm_esp_bots": Y, @"mm_esp_name": Y, @"mm_esp_dist": Y, @"mm_esp_health": N,
            @"mm_esp_lines": N, @"mm_esp_lines_top": N, @"mm_esp_fill": N,
            @"mm_esp_range": @120.0f, @"mm_esp_count": N, @"mm_esp_box_style": @1.0f,
            @"mm_esp_theme": @0.0f, @"mm_stream": N, @"mm_auto_stream": Y,
            @"mm_x_cross": N, @"mm_x_aimring": N, @"mm_x_head": N, @"mm_x_distcol": N,
            @"mm_x_lowhp": N, @"mm_x_fps": N, @"mm_x_priority": Y, @"mm_x_warn": N,
            @"mm_x_arrow": N, @"mm_x_radar": N, @"mm_x_height": N, @"mm_x_telem": N,
            @"mm_x_bearings": N, @"mm_x_trails": N, @"mm_x_declutter": N,
            @"mm_x_radar_cam": Y, @"mm_x_targetlist": N, @"mm_x_maxn": @12.0f });
    }
    mm_sync_switches(g_panel);
    mm_apply_esp_lock();
    mm_apply_stream();
    if (g_esp != nil) [g_esp setNeedsDisplay];
    mm_mark_action("preset");
}

static void mm_profile_export(void)
{
    @try {
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        NSMutableDictionary *d = [NSMutableDictionary dictionary];
        for (NSString *k in mm_profile_keys()) {
            id v = [ud objectForKey:k];
            if (v != nil) d[k] = v;
        }
        d[@"_fusion"] = @{ @"slot": @(g_profile_slot),
                           @"name": mm_profile_name(g_profile_slot),
                           @"build": @MODMENU_VERSION };
        NSData *j = [NSJSONSerialization dataWithJSONObject:d options:0 error:nil];
        if (j == nil) return;
        NSString *s = [[NSString alloc] initWithData:j encoding:NSUTF8StringEncoding];
        [UIPasteboard generalPasteboard].string = s ?: @"";
        mm_haptic(1);
        mm_show_alert(mm_tr(@"Perfil exportado"),
                      [NSString stringWithFormat:@"%@\n%d claves en el portapapeles.",
                       mm_profile_name(g_profile_slot), (int)d.count]);
    } @catch (NSException *e) {
        MM_LOG(@"%s perfil export: %@", MM_TAG, e.reason);
    }
}

static void mm_profile_import(void)
{
    @try {
        NSString *s = [UIPasteboard generalPasteboard].string;
        if (s.length == 0) {
            mm_show_alert(mm_tr(@"Importar perfil"), mm_tr(@"El portapapeles esta vacio."));
            return;
        }
        NSData *d = [s dataUsingEncoding:NSUTF8StringEncoding];
        id o = [NSJSONSerialization JSONObjectWithData:d options:0 error:nil];
        if (![o isKindOfClass:[NSDictionary class]]) {
            mm_show_alert(mm_tr(@"Importar perfil"), mm_tr(@"El JSON no es un objeto."));
            return;
        }
        NSDictionary *dict = (NSDictionary *)o;
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        int n = 0;
        for (NSString *k in mm_profile_keys()) {
            id v = dict[k];
            if (v != nil) { [ud setObject:v forKey:k]; n++; }
        }
        [ud synchronize];
        mm_opts_invalidate();
        mm_sync_switches(g_panel);
        mm_apply_esp_lock();
        mm_apply_stream();
        if (g_esp != nil) [g_esp setNeedsDisplay];
        mm_haptic(1);
        mm_show_alert(mm_tr(@"Perfil importado"),
                      [NSString stringWithFormat:@"%d claves aplicadas.", n]);
    } @catch (NSException *e) {
        MM_LOG(@"%s perfil import: %@", MM_TAG, e.reason);
    }
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
        MM_LOG(@"%s perfil guardar: %@", MM_TAG, e.reason);
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
        mm_opts_invalidate();
        if (g_panel != nil) mm_sync_switches(g_panel);
        mm_apply_esp_lock();
        mm_apply_stream();
        if (g_esp != nil) [g_esp setNeedsDisplay];
        return YES;
    } @catch (NSException *e) {
        MM_LOG(@"%s perfil cargar: %@", MM_TAG, e.reason);
        return NO;
    }
}

/*---------------------------------------------------------------------------
 * ESP v0.2.3 - motor de dibujo.
 *  El CADisplayLink llama a mm_esp_frame() a 60 Hz: los datos del juego se
 *  leen a ~30 Hz (mm_esp_collect_real) y el lienzo se repinta solo si cambio
 *  algo visible (v0.6.2: huella del frame). Sin el maestro ON no se toca NADA.
 *--------------------------------------------------------------------------*/
/* v0.7.3 (perf): skip O(1) por contador de version de escena.
   Antes (v0.6.2) se hasheaba view/proj/boxes/tracks/opts por frame (FNV-1a
   sobre arrays enteros). En gameplay el view mat cambia cada frame -> el
   hash siempre difiere -> nunca ahorraba repintados pero igual costaba.
   Ahora los productores (colector, lector BR, invalidador de opts, panic/
   safe/thermal) bumpean g_scene_ver. En reposo (lobby) nadie bumpea y el
   frame se salta sin tocar CoreGraphics; en movimiento el bump cae al
   compas real del colector (~30 Hz). */
static unsigned long long mm_frame_digest(void)
{
    return g_scene_ver;
}

static void mm_esp_frame(double t)
{
    /* C-7: FOV de camara. Se reaplica a ~4 Hz para ganarle al ADS del juego. */
    if (0) {   /* C-9: FOV changer retirado: el juego reescribe el FOV y no quedaba */
        static double s_fov = 0.0;
        if (t - s_fov > 0.25) {
            s_fov = t;
            void *cam = g_fov_cam_get();
            if (cam != NULL) g_fp_cam_setfov(cam, g_cam_fov);
        }
    }
    @try {
        if (g_esp == nil) return;
        /* v0.4.3 (0.1): version gate - no leer offsets de 1.0.57 contra otra version del juego. */
        static int g_ver_ok = -1;
        static unsigned long long s_digest = 0;
        if (g_ver_ok < 0) {
            NSString *gv = NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"];
            g_ver_ok = (gv != nil && [gv isEqualToString:@FUSION_OFFSETS_VERSION]) ? 1 : 0;
            if (!g_ver_ok) MM_LOG(@"%s version gate: juego %@ != offsets %s -> ESP OFF",
                                 MM_TAG, gv, FUSION_OFFSETS_VERSION);
        }
        if (!g_ver_ok) { if (!g_esp.hidden) g_esp.hidden = YES; return; }
        if (g_panic) {                 /* v0.4.0 #8: todo oculto en modo panico */
            if (!g_esp.hidden) g_esp.hidden = YES;
            return;
        }
        /* v0.6.4: modo seguro = overlay apagado de verdad, aunque un toggle
           haya quedado prendido. El boton/panel siguen para poder salir.
           perf: usa el snapshot cacheado (mm_draw_opts) en vez de NSUserDefaults
           a 60 fps. */
        if (mm_draw_opts()->safe_mode) {
            if (g_box_count != 0 || g_track_count != 0) {
                g_box_count = 0;
                g_track_count = 0;
                [g_esp setNeedsDisplay];
            }
            if (!g_esp.hidden) g_esp.hidden = YES;
            mm_refresh_count_glass();
            return;
        }
        if (!mm_draw_opts()->master) {
            if (g_box_count != 0) {
                g_box_count = 0;
                [g_esp setNeedsDisplay];
            }
            if (!g_esp.hidden) g_esp.hidden = YES;
            mm_refresh_count_glass();
            return;
        }
        /* 1.12: guard termico. serious = 1 de cada 2 frames; critical = 1 de 4.
           No toca preferencias ni el estado del overlay: solo baja el ritmo. */
        if (g_thermal_level >= 2) {
            static unsigned s_thermal_skip = 0;
            unsigned mod = (g_thermal_level >= 3) ? 4u : 2u;
            if ((++s_thermal_skip % mod) != 0) return;
        }
        if (g_esp.hidden) { g_esp.hidden = NO; s_digest = 0; }   /* v0.6.2: fuerza 1er paint */

        /* v0.4.0 (#2 FPS): media exponencial del ritmo real del lienzo. */
        static double s_lastT = 0.0;
        if (s_lastT > 0.0 && t > s_lastT) {
            double inst = 1.0 / (t - s_lastT);
            g_fps = (g_fps > 0.0) ? (g_fps * 0.9 + inst * 0.1) : inst;
        }
        s_lastT = t;

        mm_aim_lock();                     /* 0.10.0: cada frame (60 Hz) */
        static int s_tick = 0;              /* datos ~30 Hz, pintado a 60 fps */
        /* 0.10.2: el relay se pierde si se escribe antes de que el juego este
           listo. Re-aplicarlo cada ~30 frames evita tener que tocar el switch. */
        if ((s_tick % 30) == 0) mm_aim_apply();
        if ((s_tick++ & 1) == 0) {
            mm_esp_collect_real();
            mm_reload_diag();               /* 0.8.4: sonda del reload (4 Hz, propia) */
            mm_esp_read_diag();             /* 0.8.8: sonda de lecturas (1 Hz) */
            mm_refresh_count_glass();       /* v0.3.2: contador glass */
        }
        /* v0.6.2: repintar solo si algo visible cambio. Parado en el lobby o
           con el juego en pausa el lienzo no gasta CPU; con movimiento, 60 fps. */
        double now = CACurrentMediaTime();
        static double s_last_paint = 0.0;
        /* v0.6.4: ritmo por feature. fps/telemetria no necesitan 60 Hz; aviso y
           estelas si (30). Con el panel abierto, 20 Hz: el menu tapa el lienzo.
           El digest se calcula solo cuando ya toca pintar (no 60 veces/s). */
        double minGap = g_panel_open ? (1.0 / 20.0) : (1.0 / 60.0);
        if (s_last_paint > 0.0 && now - s_last_paint < minGap) return;
        const MMDrawOpts *o = mm_draw_opts();
        unsigned long long dg = mm_frame_digest();
        BOOL animado = o->fps || o->telem || o->trails || o->warn;
        double animGap = (o->warn || o->trails) ? (1.0 / 30.0) : 0.25;
        BOOL pinta = (dg != s_digest) ||
                     (animado && (s_last_paint <= 0.0 || now - s_last_paint >= animGap));
        if (pinta) {
            s_digest = dg;
            s_last_paint = now;
            [g_esp setNeedsDisplay];
        }
    } @catch (NSException *e) {}
}

/*---------------------------------------------------------------------------
 * Sonda de SOLO LECTURA (v0.2.2 - fase B).
 *  Comprueba en el equipo que la tabla methodPointers del juego es legible y
 *  que sus punteros caen en su binario. NO llama a nada del juego: solo lee.
 *  La lectura va con vm_read_overwrite: si la direccion no es valida devuelve
 *  error en vez de tumbar la app (sin eso la sonda seria un riesgo).
 *  Direccion de la tabla (en archivo): VA_PROBE_TABLE, definida en
 *  corpus/1.0.57/offsets.json y emitida al header generado.
 *--------------------------------------------------------------------------*/
static uint64_t mm_safe_read64(uintptr_t addr, BOOL *ok)
{
    uint64_t v = 0;
    vm_size_t outsz = 0;
    g_vm_reads++;   /* Fase 1.7: lectura/s en el HUD de telemetria */
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
        /* 0.5: la tabla y los slots salen de fusion_offsets.generated.h,
           generado desde corpus/1.0.57/offsets.json. No se hardcodea aca. */
        uintptr_t tbl  = base + (uintptr_t)(VA_PROBE_TABLE - FUSION_IMAGE_BASE);
        NSMutableString *s = [NSMutableString stringWithFormat:
            @"base=0x%lX tabla=0x%lX",
            (unsigned long)base, (unsigned long)tbl];

        static const struct { int pos; const char *que; } slots[] = { MM_PROBE_SLOTS };

        int enCod = 0, malos = 0;
        const int nslots = (int)(sizeof(slots) / sizeof(slots[0]));
        for (int i = 0; i < nslots; i++) {
            BOOL ok = NO;
            uint64_t v = mm_safe_read64(tbl + (uintptr_t)slots[i].pos * MM_PROBE_SLOT_SIZE, &ok);
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
        MM_LOG(@"%s sonda: %@", MM_TAG, s);
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
            MM_LOG(@"%s nojb: %s%s %s es heredado de NSObject, se salta",
                  MM_TAG, h->isClass ? "+" : "-", h->cls, h->sel);
            continue;
        }
        IMP prev = method_setImplementation(m, h->rep);
        g_nojb_state[i] = 1;
        done++;
        MM_LOG(@"%s nojb: swz %s%s %s (antes=%p) -> 0",
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
            MM_LOG(@"%s nojb: %s NO coincide (esperado 0x%llX, leido 0x%llX); no se escribe",
                  MM_TAG, s->name, (unsigned long long)s->expect,
                  (unsigned long long)cur);
            continue;
        }
        int r = mm_mem_write(a, s->patch, len);
        if (r == 1) {
            g_nojb_anogs[i] = 1;
            MM_LOG(@"%s nojb: %s armado en 0x%X (%zu B)", MM_TAG, s->name, s->off, len);
        } else if (g_nojb_anogs_log[i] == 0) {
            g_nojb_anogs_log[i] = 1;
            MM_LOG(@"%s nojb: %s fallo al escribir (r=%d); se reintenta",
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
            MM_LOG(@"%s nojb fin: %@ (pasadas=%d)", MM_TAG, mm_nojb_resumen(), g_nojb_passes);
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
    MM_LOG(@"%s nojb: inicio (fase C v0.2.9, anogs OFF)", MM_TAG);
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
    g_vm_reads++;   /* Fase 1.7: lectura/s en el HUD de telemetria */
    kern_return_t kr = vm_read_overwrite(mach_task_self(), (vm_address_t)addr,
                                         (vm_size_t)n, (vm_address_t)dst, &outsz);
    return (kr == KERN_SUCCESS && outsz == (vm_size_t)n);
}

/* 0.9.7: escritura de memoria (para el silent aim sobre el pawn). */
static BOOL mm_vm_write(uintptr_t addr, const void *src, size_t n)
{
    /* vm_write esta en <mach/vm_map.h>; mach_vm.h no existe en el SDK de iOS. */
    kern_return_t kr = vm_write(mach_task_self(), (vm_address_t)addr,
                                (vm_offset_t)src, (mach_msg_type_number_t)n);
    return kr == KERN_SUCCESS;
}

static BOOL mm_r64(uintptr_t addr, uint64_t *out)
{
    BOOL ok = NO;
    uint64_t v = mm_safe_read64(addr, &ok);
    if (ok && out != NULL) *out = v;
    return ok;
}

/* 0.9.1: AIM LOCK — sigue al enemigo SIN apuntar. Escribe la rotacion de la
   camara hacia el objetivo mas cercano al centro de la mira, dentro del FOV.
   Filtra por tipo de arma (fusil / subfusil / escopeta / franco). */
static void mm_read_csstr(uint64_t sp, char *out, size_t cap)
{
    if (out == NULL || cap == 0) return;
    out[0] = 0;
    if (sp == 0) return;
    int32_t len = 0;
    if (!mm_vm_read((uintptr_t)sp + 0x10, &len, sizeof(len)) || len <= 0 || len > 48) return;
    uint16_t buf[49];
    size_t n = (size_t)len;
    if (n > cap - 1) n = cap - 1;
    if (!mm_vm_read((uintptr_t)sp + 0x14, buf, n * 2)) return;
    for (size_t i = 0; i < n; i++) out[i] = (buf[i] < 128) ? (char)buf[i] : '?';
    out[n] = 0;
}

/* 0 = sin dato, 1 fusil, 2 subfusil, 3 escopeta, 4 franco (por SubCategoryName). */
static int mm_local_weapon_kind(void)
{
    @try {
        if (g_fp_localpawn == NULL) return 0;
        void *lp = g_fp_localpawn();
        if (lp == NULL) return 0;
        uint64_t inv = 0, wep = 0, conf = 0, sp = 0;
        if (!mm_r64((uintptr_t)lp + OFF_PAWN_INVMGR, &inv) || inv == 0) return 0;
        if (!mm_r64((uintptr_t)inv + OFF_INVM_CURWEP, &wep) || wep == 0) return 0;
        if (!mm_r64((uintptr_t)wep + OFF_WEP_CONFIG, &conf) || conf == 0) return 0;
        if (!mm_r64((uintptr_t)conf + OFF_WEP_SUBCAT, &sp) || sp == 0) return 0;
        char nm[48];
        mm_read_csstr(sp, nm, sizeof(nm));
        for (char *p = nm; *p != 0; p++)
            if (*p >= 'A' && *p <= 'Z') *p = (char)(*p - 'A' + 'a');
        if (strstr(nm, "sni") != NULL || strstr(nm, "franco") != NULL) return 4;
        if (strstr(nm, "shot") != NULL || strstr(nm, "escop") != NULL) return 3;
        if (strstr(nm, "smg") != NULL || strstr(nm, "sub") != NULL) return 2;
        if (strstr(nm, "rifle") != NULL || strstr(nm, "lmg") != NULL ||
            strstr(nm, "fus") != NULL) return 1;
    } @catch (NSException *e) {}
    return 0;
}

/* 0.9.3: el jugador local esta apuntando (ADS)? Cache 0,2 s. */
static BOOL mm_local_ads(void)
{
    @try {
        static int s_ads = -1;
        static double s_ads_t = 0.0;
        double now = CACurrentMediaTime();
        if (s_ads >= 0 && (now - s_ads_t) < 0.2) return s_ads ? YES : NO;
        s_ads_t = now;
        s_ads = 0;
        if (g_fp_localpawn == NULL) return NO;
        void *lp = g_fp_localpawn();
        if (lp == NULL) return NO;
        uint64_t inv = 0, wep = 0;
        if (mm_r64((uintptr_t)lp + OFF_PAWN_INVMGR, &inv) && inv != 0 &&
            mm_r64((uintptr_t)inv + OFF_INVM_CURWEP, &wep) && wep != 0) {
            uint8_t a = 0;
            if (mm_vm_read((uintptr_t)wep + OFF_WEP_AIMING, &a, 1) && (a & 1)) s_ads = 1;
        }
        return s_ads ? YES : NO;
    } @catch (NSException *e) {}
    return NO;
}

/* Helpers de quaternion (Hamilton, x,y,z,w). */
static void mm_q_mul(const float a[4], const float b[4], float out[4])
{
    out[0] = a[3]*b[0] + a[0]*b[3] + a[1]*b[2] - a[2]*b[1];
    out[1] = a[3]*b[1] - a[0]*b[2] + a[1]*b[3] + a[2]*b[0];
    out[2] = a[3]*b[2] + a[0]*b[1] - a[1]*b[0] + a[2]*b[3];
    out[3] = a[3]*b[3] - a[0]*b[0] - a[1]*b[1] - a[2]*b[2];
}
static void mm_q_rotate(const float q[4], const float v[3], float out[3])
{
    float u[3] = { q[0], q[1], q[2] };
    float t[3] = {
        u[1]*v[2] - u[2]*v[1] + q[3]*v[0],
        u[2]*v[0] - u[0]*v[2] + q[3]*v[1],
        u[0]*v[1] - u[1]*v[0] + q[3]*v[2]
    };
    out[0] = v[0] + 2.0f*(u[1]*t[2] - u[2]*t[1]);
    out[1] = v[1] + 2.0f*(u[2]*t[0] - u[0]*t[2]);
    out[2] = v[2] + 2.0f*(u[0]*t[1] - u[1]*t[0]);
}
static void mm_q_norm(float q[4])
{
    float n = sqrtf(q[0]*q[0] + q[1]*q[1] + q[2]*q[2] + q[3]*q[3]);
    if (n < 1.0e-6f) { q[0]=q[1]=q[2]=0.0f; q[3]=1.0f; return; }
    for (int i = 0; i < 4; i++) q[i] /= n;
}
/* Interpola entre dos rotaciones por el arco corto. */
static void mm_q_slerp(const float a[4], const float b_in[4], float t, float out[4])
{
    float b[4] = { b_in[0], b_in[1], b_in[2], b_in[3] };
    float d = a[0]*b[0] + a[1]*b[1] + a[2]*b[2] + a[3]*b[3];
    if (d < 0.0f) { for (int i = 0; i < 4; i++) b[i] = -b[i]; d = -d; }
    if (d > 0.9995f) { for (int i = 0; i < 4; i++) out[i] = a[i] + (b[i]-a[i])*t; mm_q_norm(out); return; }
    float th = acosf(d), st = sinf(th);
    float wa = sinf((1.0f - t)*th)/st, wb = sinf(t*th)/st;
    for (int i = 0; i < 4; i++) out[i] = a[i]*wa + b[i]*wb;
    mm_q_norm(out);
}

/* 0.9.6: AIM LOCK por ARCO EN ESPACIO DE MUNDO.
   En vez de inventar yaw/pitch (lo que rompia la camara), se toma la rotacion
   REAL de la camara, se calcula el vector forward que produce, y se aplica la
   rotacion minima que lleva ese forward al objetivo. Es independiente de la
   convencion de ejes que use el motor. */
/* 0.14: el detour vm_protect fue eliminado — viola firma de codigo iOS y
   causaba SIGKILL al activar. Ahora mm_aim_lock() escribe directamente en
   OFF_PAWN_AIMROT (datos en heap, no codigo ejecutable). */

/* 0.9.8: AIM LOCK igual que los mods de referencia (SP3CTERIOS y StarCodm).
   StarCodm, desensamblado, hace literalmente:
     q0 = getAimRotation(pawn)
     dir = normalize(objetivo - posPawn)
     from-to -> qTarget = qDelta * q0
     slerp(q0, qTarget, aim_speed)
     setAimRotation(pawn, q)
   Nosotros hacemos lo mismo; la camara es opcional (apagada por defecto). */
static void mm_aim_lock(void)
{
    @try {
        if (!g_lock_on) { g_lock_active = 0; return; }
        if (g_panel_open || g_esp == nil || g_esp.hidden) { g_lock_active = 0; return; }
        if (g_fp_trpos == NULL || g_fp_localpawn == NULL ||
            g_fp_maincam == NULL || g_fp_gettrans == NULL) { g_lock_active = 0; return; }
        if (g_box_count <= 0) { g_lock_active = 0; return; }

        static int s_kind = -1;
        static double s_kind_t = 0.0;
        double nowk = CACurrentMediaTime();
        if (s_kind < 0 || (nowk - s_kind_t) > 0.75) {
            s_kind = mm_local_weapon_kind();
            s_kind_t = nowk;
        }
        int kind = s_kind;
        BOOL allow = (kind == 1) ? g_lock_rifle :
                     (kind == 2) ? g_lock_smg :
                     (kind == 3) ? g_lock_shotgun :
                     (kind == 4) ? g_lock_sniper :
                     (g_lock_rifle || g_lock_smg || g_lock_shotgun || g_lock_sniper);
        if (!allow) { g_lock_active = 0; return; }
        if (g_lock_ads && !mm_local_ads()) { g_lock_active = 0; return; }

        void *lp = g_fp_localpawn();
        if (lp == NULL) { g_lock_active = 0; return; }

        /* 0.14.2 (F4): EL BUG DE LOS PIES.
           La rotacion que escribimos es la del PAWN, asi que el pivote del giro es
           el pawn. Pero el angulo se medía desde la CAMARA. En tercera persona la
           camara esta mas alta y atras: la direccion camara->objetivo es mas plana
           que pawn->objetivo, y al aplicarla al pawn el arma queda apuntando POR
           DEBAJO del objetivo.
           Explica los tres sintomas medidos en dispositivo:
             - franco: a largo alcance la diferencia angular es despreciable -> anda
             - escopeta: a corta la dispersion lo tapa -> anda
             - rifle/SMG a media distancia: pega en los pies -> "no anda"
           Regla: el origen del vector tiene que ser el PIVOTE del giro. */
        float o[3] = { 0.0f, 0.0f, 0.0f };
        BOOL haveO = NO;
        int  o_src = 0;                 /* 0 = pawn (correcto), 1 = camara (fallback) */
        uint64_t trl = 0;
        if (mm_r64((uintptr_t)lp + OFF_PAWN_TRANSFORM, &trl) && trl != 0) {
            g_fp_trpos((void *)(uintptr_t)trl, o);
            if (isfinite(o[0]) && isfinite(o[1]) && isfinite(o[2]) &&
                (fabsf(o[0]) + fabsf(o[1]) + fabsf(o[2])) > 1.0f) haveO = YES;
        }
        if (!haveO) {                   /* fallback: camara (comportamiento 0.14.1) */
            void *cam = g_fp_maincam();
            void *ctr = (cam != NULL) ? g_fp_gettrans(cam) : NULL;
            if (ctr != NULL) {
                g_fp_trpos(ctr, o);
                if (isfinite(o[0]) && isfinite(o[1]) && isfinite(o[2]) &&
                    (fabsf(o[0]) + fabsf(o[1]) + fabsf(o[2])) > 1.0f) { haveO = YES; o_src = 1; }
            }
        }
        if (!haveO) { g_lock_active = 0; return; }

        /* base = rotacion de aim ACTUAL del pawn (su forward manda) */
        float base[4] = { 0.0f, 0.0f, 0.0f, 1.0f };
        memcpy(base, (const void *)((uintptr_t)lp + OFF_PAWN_AIMROT), sizeof(base));
        mm_q_norm(base);

        /* 0.14.2 (F5): el "solo anda cuando me muevo".
           Si al empezar el frame el valor leido NO es el que escribimos el frame
           anterior, el juego lo reescribio y ganamos la pulseada solo cuando su
           propia escritura no ocurre. Medimos los dos casos y los logueamos. */
        if (g_lock_last_ok) {
            float d2 = 0.0f;
            for (int k = 0; k < 4; k++) { float d = base[k] - g_lock_last[k]; d2 += d * d; }
            if (d2 < 0.0004f) g_lock_diag[0]++; else g_lock_diag[1]++;
        }
        float fwd[3];
        { float f[3] = { 0.0f, 0.0f, 1.0f }; mm_q_rotate(base, f, fwd); }

        float halfFov = g_aim_fov * 0.5f;
        if (halfFov < 6.0f) halfFov = 6.0f;
        if (halfFov > 120.0f) halfFov = 120.0f;

        int best = -1;
        float bestAng = 1.0e9f;
        float bpx = 0.0f, bpy = 0.0f, bpz = 0.0f;
        for (int i = 0; i < g_box_count; i++) {
            float px = g_boxes[i].wx;
            float py = g_boxes[i].wy + g_aim_height;
            float pz = g_boxes[i].wz;
            float vx = px - o[0], vy = py - o[1], vz = pz - o[2];
            float d2 = vx*vx + vy*vy + vz*vz;
            if (d2 < 4.0f) continue;
            float inv = 1.0f/sqrtf(d2);
            vx *= inv; vy *= inv; vz *= inv;
            float dot = fwd[0]*vx + fwd[1]*vy + fwd[2]*vz;
            if (dot < 0.15f) continue;
            float ang = acosf(fminf(1.0f, dot)) * 180.0f / (float)M_PI;
            if (ang > halfFov) continue;
            if (ang < bestAng) { bestAng = ang; best = i; bpx = px; bpy = py; bpz = pz; }
        }
        if (best < 0) { g_lock_active = 0; return; }

        float dv[3] = { bpx - o[0], bpy - o[1], bpz - o[2] };
        float dl = sqrtf(dv[0]*dv[0] + dv[1]*dv[1] + dv[2]*dv[2]);
        if (dl < 0.5f) { g_lock_active = 0; return; }
        dv[0] /= dl; dv[1] /= dl; dv[2] /= dl;

        float dot = fwd[0]*dv[0] + fwd[1]*dv[1] + fwd[2]*dv[2];
        dot = fmaxf(-1.0f, fminf(1.0f, dot));
        float ang = acosf(dot);
        float angDeg = ang * 180.0f / (float)M_PI;
        if (angDeg < 0.10f) { g_lock_active = 0; return; }

        float ax[3] = {
            fwd[1]*dv[2] - fwd[2]*dv[1],
            fwd[2]*dv[0] - fwd[0]*dv[2],
            fwd[0]*dv[1] - fwd[1]*dv[0]
        };
        float al = sqrtf(ax[0]*ax[0] + ax[1]*ax[1] + ax[2]*ax[2]);
        if (al < 1.0e-5f) { g_lock_active = 0; return; }
        ax[0] /= al; ax[1] /= al; ax[2] /= al;

        float sh = sinf(ang * 0.5f), ch = cosf(ang * 0.5f);
        float qd[4] = { ax[0]*sh, ax[1]*sh, ax[2]*sh, ch };
        float qtar[4];
        mm_q_mul(qd, base, qtar);
        mm_q_norm(qtar);

        /* 0.14.1 (F1): el suavizado era POR FRAME, no por tiempo. Eso lo hacia
           depender de los FPS y, peor, del guard termico (que saltea 1 de 2 o 1 de 4
           frames): en un equipo caliente el aim iba a la mitad o a un cuarto de
           velocidad. Ahora el tope es en GRADOS POR SEGUNDO y se escala por dt. */
        static double s_prev_t = 0.0;
        double now_t = CACurrentMediaTime();
        float dt = 1.0f / 60.0f;
        if (s_prev_t > 0.0 && now_t > s_prev_t) dt = (float)(now_t - s_prev_t);
        s_prev_t = now_t;
        if (dt < 0.002f) dt = 0.002f;      /* evita divisiones raras */
        if (dt > 0.100f) dt = 0.100f;      /* frame perdido: no dar un salto */

        /* smooth 0 -> 900 deg/s (snap), smooth 1 -> 60 deg/s (suave) */
        float degPerSec = 900.0f - g_aim_smooth * 840.0f;
        if (degPerSec < 30.0f) degPerSec = 30.0f;
        float maxDeg = degPerSec * dt;

        float a = 1.0f - g_aim_smooth * 0.90f;
        if (a * angDeg > maxDeg) a = maxDeg / angDeg;
        if (a < 0.02f) a = 0.02f;
        if (a > 1.0f) a = 1.0f;

        float q[4];
        mm_q_slerp(base, qtar, a, q);

        /* 0.14.1 (F3): el getter del juego elige entre m_AimRotation (0x380) y
           m_SimulatedAimRotation (0x3C0) segun una condicion interna (verificado en
           el desensamblado: csel 0x380/0x3C0). Escribir solo 0x380 no tenia efecto
           en los estados en que el juego lee el simulado. Se escriben las dos. */
        memcpy((void *)((uintptr_t)lp + OFF_PAWN_AIMROT), q, sizeof(q));
        memcpy((void *)((uintptr_t)lp + OFF_PAWN_SIMAIMROT), q, sizeof(q));
        if (g_fp_setaimrot) { MMQuat qv = {q[0],q[1],q[2],q[3]}; g_fp_setaimrot(lp, qv); }
        g_lock_last[0] = q[0]; g_lock_last[1] = q[1];
        g_lock_last[2] = q[2]; g_lock_last[3] = q[3];
        g_lock_last_ok = 1;
        g_lock_pawn = (uint64_t)(uintptr_t)lp;
        g_lock_active = 1;
        g_lock_frames++;

        {   /* sonda 2 Hz */
            static double s_lg = 0.0;
            double nowl = CACurrentMediaTime();
            if ((nowl - s_lg) > 0.5) {
                s_lg = nowl;
                NSString *docs = mm_docs_dir();
                if (docs.length > 0) {
                    NSString *t = [NSString stringWithFormat:
                        @"build=%s\nmodo=write-struct\n"
                        @"origen=%.2f,%.2f,%.2f src=%d\ntarget=%.2f,%.2f,%.2f\n"
                        @"fwd=%.3f,%.3f,%.3f des=%.3f,%.3f,%.3f\n"
                        @"dot=%.4f angDeg=%.2f alpha=%.3f tipo=%d frames=%ld dt=%.4f "
                        @"stuck=%ld pisan=%ld\n"
                        @"q_base=%.4f,%.4f,%.4f,%.4f\nq_lock=%.4f,%.4f,%.4f,%.4f\n",
                        MODMENU_VERSION, (double)o[0], (double)o[1], (double)o[2], o_src,
                        (double)bpx, (double)bpy, (double)bpz,
                        (double)fwd[0], (double)fwd[1], (double)fwd[2],
                        (double)dv[0], (double)dv[1], (double)dv[2],
                        (double)dot, (double)angDeg, (double)a, kind, (long)g_lock_frames,
                        (double)dt, g_lock_diag[0], g_lock_diag[1],
                        (double)base[0], (double)base[1], (double)base[2], (double)base[3],
                        (double)q[0], (double)q[1], (double)q[2], (double)q[3]];
                    [t writeToFile:[docs stringByAppendingPathComponent:@"fusion_lock.txt"]
                        atomically:YES encoding:NSUTF8StringEncoding error:NULL];
                }
            }
        }
    } @catch (NSException *e) { g_lock_active = 0; }
}

/* 0.8.4: SONDA DEL RELOAD (solo lectura, sin tocar nada del juego).
   Mientras el estado actual del arma es "cambiando cargador" (elapse > 0),
   escribe Documents/fusion_reload.txt con los cuatro floats que decide la
   duracion. Sirve para saber si el parche de GetChangeClipTime realmente
   llega al vtable:
     doChangeClipTime ~ 0.125  -> el parche SI esta (el problema es otro)
     doChangeClipTime ~ 2.x    -> el vtable llama a otro metodo, no al parcheado
   Throttle 4 Hz; si no hay recarga en curso no escribe nada. */
static void mm_reload_diag(void)
{
    @try {
        if (!mm_def_bool(@"mm_debug", NO)) return;   /* 0.9.2: sondas solo con debug */
        static double s_rd_last = 0.0;
        if (g_fp_localpawn == NULL) return;
        double now = CACurrentMediaTime();
        if (s_rd_last > 0.0 && (now - s_rd_last) < 0.25) return;
        void *lp = g_fp_localpawn();
        if (lp == NULL) return;
        uint64_t inv = 0, wep = 0, sm = 0, st = 0;
        if (!mm_r64((uintptr_t)lp + OFF_PAWN_INVMGR, &inv) || inv == 0) return;
        if (!mm_r64((uintptr_t)inv + OFF_INVM_CURWEP, &wep) || wep == 0) return;
        if (!mm_r64((uintptr_t)wep + OFF_WEP_STATEMACH, &sm) || sm == 0) return;
        if (!mm_r64((uintptr_t)sm + OFF_SM_CURSTATE, &st) || st == 0) return;
        float elapse = 0.0f, dur = 0.0f, rate = 0.0f, factor = 0.0f;
        if (!mm_vm_read((uintptr_t)st + OFF_ST_ELAPSE, &elapse, sizeof(elapse))) return;
        if (!isfinite(elapse) || elapse <= 0.001f || elapse > 30.0f) return;
        mm_vm_read((uintptr_t)st + OFF_ST_DOCHANGE, &dur, sizeof(dur));
        mm_vm_read((uintptr_t)st + OFF_ST_RATE, &rate, sizeof(rate));
        mm_vm_read((uintptr_t)st + OFF_ST_FACTOR, &factor, sizeof(factor));
        s_rd_last = now;
        NSString *docs = mm_docs_dir();
        if (docs.length == 0) return;
        NSString *s = [NSString stringWithFormat:
            @"build=%s\n"
            @"elapse=%.4f\n"
            @"doChangeClipTime=%.4f\n"
            @"rate=%.4f\n"
            @"mClipChangingTime=%.4f\n"
            @"weapon=0x%llX\n"
            @"state=0x%llX\n",
            MODMENU_VERSION, (double)elapse, (double)dur, (double)rate, (double)factor,
            (unsigned long long)wep, (unsigned long long)st];
        [s writeToFile:[docs stringByAppendingPathComponent:@"fusion_reload.txt"]
            atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    } @catch (NSException *e) {}
}

/* 0.8.8: SONDA DE LAS LECTURAS NUEVAS (solo lectura). Con cualquiera de los
   tres toggles encendido, escribe Documents/fusion_esp_read.txt una vez por
   segundo con lo que devolvio cada lector para las primeras 8 cajas: equipo,
   armadura, invisible, curando, vehiculo, y la cadena de municion paso a paso
   (invm/wep/fl/cnt/owner). Sirve para ver DONDE se corta sin adivinar. */
static void mm_esp_read_diag(void)
{
    @try {
        if (!mm_def_bool(@"mm_debug", NO)) return;   /* 0.9.2: sondas solo con debug */
        static double s_t = 0.0;
        const MMDrawOpts *o = mm_draw_opts();
        if (!o->teamFilter && !o->stateTags && !o->ammoTag) return;
        double now = CACurrentMediaTime();
        if (s_t > 0.0 && (now - s_t) < 1.0) return;
        NSString *docs = mm_docs_dir();
        if (docs.length == 0) return;
        s_t = now;
        NSMutableString *s = [NSMutableString stringWithFormat:
            @"build=%s\ncajas=%d muestra=%d\nteam_local=%u\nflags: team=%d estado=%d ammo=%d\n",
            MODMENU_VERSION, g_box_count, g_read_n, (unsigned)g_team_local,
            (int)o->teamFilter, (int)o->stateTags, (int)o->ammoTag];
        for (int i = 0; i < g_read_n; i++) {
            MMEspRead *r = &g_read[i];
            [s appendFormat:
                @"#%d pawn=0x%llX ent=0x%llX team=%u armor=%d invis=%d heal=%d veh=%d "
                @"| ammo=%d/%d ads=%d invm=%d wep=%d fl=%d cnt=%d owner=%d\n",
                i, r->pawn, r->ent, r->team, r->armor, r->invis, r->healing, r->veh,
                r->ammo, r->ammoMax, r->ads, r->invOk, r->wepOk, r->flOk, r->fcount, r->ownerOk];
        }
        [s writeToFile:[docs stringByAppendingPathComponent:@"fusion_esp_read.txt"]
            atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    } @catch (NSException *e) {}
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
            MMFindFn   fp7 = (MMFindFn)(b + MM_GAME_DELTA(VA_TRFIND));   /* C-5 */
            MMPosFn    fp8 = (MMPosFn)(b + MM_GAME_DELTA(VA_TRPOS));    /* C-5 */
            MMSetFovFn fp9 = (MMSetFovFn)(b + MM_GAME_DELTA(VA_CAM_SETFOV)); /* C-7 */

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
            g_fov_cam_get  = (void *(*)(void))fp2;   /* C-7 */
            g_fp_cam_getfov = (MMGetFovFn)(b + MM_GAME_DELTA(VA_CAM_GETFOV));   /* C-11 */
            g_fp_getname = (MMStrFn)(b + MM_GAME_DELTA(VA_GETNAME));
            g_fp_childcount = (MMIntFn1)(b + MM_GAME_DELTA(VA_CHILDCOUNT));
            g_fp_getchild = (MMObjIntFn)(b + MM_GAME_DELTA(VA_GETCHILD));
            g_fp_w2c       = fp3;
            g_fp_proj      = fp4;
            g_fp_transpos  = fp5;
            g_fp_health    = hpOk ? fp6 : NULL;
            g_fp_health_f  = hpOk ? (MMGetFltFn)fp6 : NULL;   /* v0.2.6 */
            g_fp_find      = mm_ptr_en_imagen((const void *)fp7, b) ? fp7 : NULL;
            g_fp_trpos     = mm_ptr_en_imagen((const void *)fp8, b) ? fp8 : NULL;
            /* 0.9.4: aim lock — camara -> transform y escritura de rotacion.
               Faltaban estas tres asignaciones: el lock salia por NULL y lo unico
               que se veia era el aim assist del juego. */
            g_fp_gettrans  = (MMCompTransFn)(b + MM_GAME_DELTA(VA_GETTRANS));
            g_fp_setrot    = (MMSetRotFn)(b + MM_GAME_DELTA(VA_SETROT));
            g_fp_getrot    = (MMGetRotFn)(b + MM_GAME_DELTA(VA_GETROT));
            g_fp_setaimrot = (MMSetAimRotFn)(b + MM_GAME_DELTA(VA_AIMROT_SET));
            g_fp_getaimrot = (MMGetAimRotFn)(b + MM_GAME_DELTA(VA_AIMROT_GET));
            MM_LOG(@"%s aimrot setter=%p", MM_TAG, (void *)g_fp_setaimrot);
            g_fp_cam_setfov = mm_ptr_en_imagen((const void *)fp9, b) ? fp9 : NULL;
            g_fp_state     = 1;
            MM_LOG(@"%s ESP cadena lista: base=0x%lX imagen=%d cam=%p gp=%p pawn=%p tr=%p cams=%p/%p hp=%s",
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
        MM_LOG(@"%s ESP: no pude validar los punteros del juego (imagenes=%d)", MM_TAG, (int)nimg);
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
     py   = ndc.y + H/2 - ndc.y*(H/2)
   v0.5.0: si el punto quedo detras de la camara (cz < 0.01) devuelve NO y
   deja *detras=1 + la direccion en espacio de camara (*vxo,*vyo: x derecha,
   y arriba) para el indicador de enemigos a la espalda. */
static BOOL mm_w2s(const float *view, const float *proj, const float p[3],
                   BOOL cabeza, CGFloat W, CGFloat H, CGPoint *out,
                   int *detras, float *vxo, float *vyo)
{
    /* 0.13: la formula vive en mm_math.h y se testea en C nativo. */
    float x = 0.0f, y = 0.0f;
    if (!mm_math_w2s(view, proj, p, cabeza ? 1 : 0, (float)W, (float)H,
                     &x, &y, detras, vxo, vyo))
        return NO;
    if (out != NULL) { out->x = (CGFloat)x; out->y = (CGFloat)y; }
    return YES;
}

/* Una pasada de ESP real (~15 Hz). Deja el motivo en g_esp_diag. */

static void mm_esp_collect_real(void)
{
    g_box_count = 0;
    g_read_n = 0;                          /* 0.8.8: muestra de la sonda */
    g_track_count = 0;                     /* v0.5.0: track mundial */
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
    double _col_t0 = CACurrentMediaTime();
    g_fp_w2c(cam, view);
    g_fp_proj(cam, proj);
    memcpy(g_view_mtx, view, sizeof(g_view_mtx)); g_have_view = 1;   /* v0.4.4: radar */
    memcpy(g_proj_mtx, proj, sizeof(g_proj_mtx)); g_have_proj = 1;   /* Fase 1.5: estelas */
    {
        float ps = fabsf(proj[5]);   /* escala vertical de la proyeccion */
        if (isfinite(ps) && ps > 0.05f) {
            float fv = 2.0f * atanf(1.0f / ps) * 180.0f / (float)M_PI;
            g_fov_deg = (fv >= 20.0f && fv <= 140.0f) ? fv : 60.0f;
        }
    }

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
    memcpy(g_local_pos, lpos, sizeof(g_local_pos));   /* v0.4.4: radar/altura */
    g_have_local = haveLocal ? 1 : 0;

    /* 2026-11: equipo del jugador local (PlayerInfo.m_TeamID). 0 = sin dato y
       en ese caso el filtro de equipo NO se aplica (nunca esconder a todos). */
    uint32_t teamLocal = 0;
    if (localPawn != NULL) {
        uint64_t lent = 0;
        if (mm_r64((uintptr_t)localPawn + OFF_PAWN_ENTITY, &lent) && lent != 0) {
            uint32_t tv = 0;
            if (mm_vm_read((uintptr_t)lent + OFF_ENT_TEAM, &tv, sizeof(tv)) &&
                tv > 0 && tv < 100000)
                teamLocal = tv;
        }
    }

    const MMDrawOpts *opts = mm_draw_opts();
    g_team_local = teamLocal;              /* 0.8.8: para la sonda */
    /* C-17: localY para el filtro de caidos del relay. Si el toggle esta OFF
       se escribe un valor muy bajo para que la condicion nunca se cumpla. */
    {
        const struct mach_header *hrel = _dyld_get_image_header(0);
        if (hrel != NULL)
            *(float *)((uintptr_t)hrel + (uintptr_t)0x0DC63A00ULL) =
                opts->ignoreDown ? lpos[1] : -10000.0f;
    }
    float rango = opts->range;
    BOOL conSalud  = opts->health;   /* v0.2.4 */
    BOOL conJug    = opts->players;  /* v0.2.7: a fabrica */
    BOOL conBots   = opts->bots;     /* v0.2.7: a fabrica */
    double _col_now = CACurrentMediaTime();
    static double s_col_prev = 0.0;
    float col_dt = (s_col_prev > 0.0) ? (float)(_col_now - s_col_prev) : 0.0f;
    if (col_dt < 0.005f || col_dt > 0.25f) col_dt = 0.0f;
    static int s_heavy = 0;
    BOOL heavy = ((s_heavy++ & 7) == 0);   /* 0.9.2: cadena cara a ~3,75 Hz */
    int drawn = 0;
    MMEspBox nuevos[MM_MAX_BOXES];
    memset(nuevos, 0, sizeof(nuevos));

    /* v0.2.4: GL escanea hasta 200 pawns; el tope de cajas es solo para
       DIBUJAR. Antes se recortaba el escaneo a 24 y se perdia rango real. */
    if (loopn > 200) loopn = 200;

    /* v0.6.2: la lista de pawns se lee en bloques de 32 punteros (una lectura
       de 256 B) en vez de un vm_read de 8 B por entrada. Con 200 pawns y
       ~30 Hz eso elimina miles de syscalls por segundo. */
    enum { MM_PTR_CHUNK = 32 };
    uint64_t pawns[MM_PTR_CHUNK];
    int chunkBase = -1, chunkN = 0;
    for (int i = 0; i < loopn; i++) {   /* v0.4.3 (0.6): escanea TODOS; closest-N al insertar */
        if (i - chunkBase >= chunkN) {
            chunkBase = i;
            chunkN = MIN(MM_PTR_CHUNK, loopn - i);
            if (!mm_vm_read((uintptr_t)items + OFF_ARR_DATA + (uintptr_t)i * 8,
                            pawns, (size_t)chunkN * sizeof(uint64_t)))
                chunkN = 0;
        }
        if (chunkN <= 0) continue;
        uint64_t pawn = pawns[i - chunkBase];
        if (pawn == 0) continue;
        if (localPawn != NULL && (void *)(uintptr_t)pawn == localPawn) continue;

        uint64_t a = 0, ent = 0, tr = 0;
        /* 0.7: batch de vm_read. Los campos alive/transform/entity del pawn
           caen en una ventana contigua (0x300..0x5C8); con el objeto vivo el
           rango esta mapeado. Si la lectura del bloque falla, se vuelve a las
           lecturas individuales de siempre. */
        uint8_t pawnBlock[MM_PAWN_BLOCK_SIZE];
        if (mm_vm_read((uintptr_t)pawn + MM_PAWN_BLOCK_BASE, pawnBlock, sizeof(pawnBlock))) {
            memcpy(&a,   pawnBlock + (OFF_PAWN_ALIVE     - MM_PAWN_BLOCK_BASE), sizeof(a));
            memcpy(&ent, pawnBlock + (OFF_PAWN_ENTITY    - MM_PAWN_BLOCK_BASE), sizeof(ent));
            memcpy(&tr,  pawnBlock + (OFF_PAWN_TRANSFORM - MM_PAWN_BLOCK_BASE), sizeof(tr));
        } else {
            if (!mm_r64((uintptr_t)pawn + OFF_PAWN_ALIVE, &a)) continue;
            mm_r64((uintptr_t)pawn + OFF_PAWN_ENTITY, &ent);
            mm_r64((uintptr_t)pawn + OFF_PAWN_TRANSFORM, &tr);
        }
        if ((a & 0xFF) == 0) continue;

        int robot = 0;
        int downed = 0;   /* C-19 */
        int invisible = 0, healing = 0, inVeh = 0;
        int armor = 0;
        uint32_t teamEnt = 0;
        if (ent != 0) {
            /* 2026-11: una sola lectura (PlayerInfo 0x70..0x2B4) trae robot,
               equipo, invisible, curando y vehiculo. Si el bloque falla se cae
               a la lectura individual de robot de siempre. */
            enum { MM_ENT_A = 0x70, MM_ENT_B = 0x2B4 };
            uint8_t eb[MM_ENT_B - MM_ENT_A];
            if (mm_vm_read((uintptr_t)ent + MM_ENT_A, eb, sizeof(eb))) {
                robot     = eb[OFF_ENT_ROBOT - MM_ENT_A] & 0xFF;
                invisible = eb[OFF_ENT_INVIS - MM_ENT_A] & 0xFF;
                memcpy(&teamEnt, eb + (OFF_ENT_TEAM - MM_ENT_A), sizeof(teamEnt));
                float mt = 0.0f;
                memcpy(&mt, eb + (OFF_ENT_MEDTIME - MM_ENT_A), sizeof(mt));
                if (isfinite(mt) && mt > 0.0f) healing = 1;
                uint32_t vid = 0;
                memcpy(&vid, eb + (OFF_ENT_VEHICLE - MM_ENT_A), sizeof(vid));
                if (vid != 0 && vid < 1000000) inVeh = 1;
            } else {
                uint64_t rb = 0;
                if (mm_r64((uintptr_t)ent + OFF_ENT_ROBOT, &rb)) robot = (int)(rb & 0xFF);
            }
            float rt = 0.0f;
            if (mm_vm_read((uintptr_t)ent + OFF_ENT_REVIVE, &rt, sizeof(rt)) &&
                isfinite(rt) && rt > 0.5f) downed = 1;
            /* 2026-11: armadura cinetica (PlayerInfo 0x5C4/0x5C8). Fuera del
               bloque de arriba: solo se pide si el operador quiere etiquetas. */
            if (heavy && opts->stateTags) {
                uint32_t ar = 0, armax = 0;
                if (mm_vm_read((uintptr_t)ent + OFF_ENT_ARMOR, &ar, sizeof(ar)) &&
                    mm_vm_read((uintptr_t)ent + OFF_ENT_ARMORMAX, &armax, sizeof(armax)) &&
                    ar > 0 && ar <= 9999 && armax >= ar && armax <= 9999)
                    armor = (int)ar;
            }
        }

        /* v0.2.4: filtros por tipo */
        if (robot && !conBots) continue;
        if (!robot && !conJug) continue;

        /* 2026-11: filtro de equipo. Solo actua si AMBOS lados traen un team
           valido: con un 0 de cualquiera de los dos no se filtra nada. */
        if (opts->teamFilter && teamLocal != 0 && teamEnt != 0 && teamEnt == teamLocal)
            continue;
        /* fuera de las etiquetas si el operador no las pidio */
        if (!opts->stateTags) { invisible = 0; healing = 0; inVeh = 0; armor = 0; }

        uint64_t tchk = 0;
        if (tr == 0) continue;
        if (!mm_r64((uintptr_t)tr, &tchk)) continue;

        float wp[3] = { 0.0f, 0.0f, 0.0f };
        g_fp_transpos((void *)(uintptr_t)tr, wp);
        if (!isfinite(wp[0]) || !isfinite(wp[1]) || !isfinite(wp[2])) continue;
        if (fabsf(wp[0]) > 20000.0f || fabsf(wp[1]) > 20000.0f || fabsf(wp[2]) > 20000.0f)
            continue;

        float dist = 0.0f;
        if (haveLocal) {
            dist = mm_math_dist3(wp, lpos);
            if (dist > rango) continue;
        }

        /* v0.5.0: TRACK MUNDIAL (independiente de la proyeccion). Antes, si el
           pawn no se podia proyectar (detras de la camara) se descartaba del
           todo: desaparecia del radar y del contador JUG/BOT. El track existe
           siempre que el pawn este vivo, del tipo pedido y dentro de rango. */
        MMTrack tk;
        memset(&tk, 0, sizeof(tk));
        tk.pawn = pawn;
        tk.wx = wp[0]; tk.wy = wp[1]; tk.wz = wp[2];
        tk.dist = dist; tk.robot = robot; tk.alive = 1; tk.downed = downed;
        int tslot = -1;
        if (g_track_count < MM_MAX_TRACKS) tslot = g_track_count++;
        else {
            int farT = 0; float fdT = g_tracks[0].dist;
            for (int q = 1; q < MM_MAX_TRACKS; q++)
                if (g_tracks[q].dist > fdT) { fdT = g_tracks[q].dist; farT = q; }
            if (dist < fdT) tslot = farT;   /* si no entra, igual sigue a cajas */
        }
        if (tslot >= 0) g_tracks[tslot] = tk;

        /* v0.2.5: caja de cuerpo completo. La posicion del pawn proyecta a la
           altura del cuello, no a los pies (verificado en captura): el +0.5
           de clip que usa GL para la "cabeza" solo separaba unos pixeles y
           dejaba un cuadrito pegado a la cara. Se proyectan dos puntos del
           mundo, coronilla (pos + 0.25 m) y pies (pos - 1.52 m); asi la caja
           cubre el cuerpo entero a cualquier distancia. */
        float wpTop[3]  = { wp[0], wp[1] + MM_BOX_TOP_UP,  wp[2] };
        float wpFeet[3] = { wp[0], wp[1] - MM_BOX_FEET_DN, wp[2] };
        CGPoint cab, pies;
        int detCab = 0, detPies = 0;
        float camX = 0.0f, camY = 0.0f;
        BOOL okCab  = mm_w2s(view, proj, wpTop,  NO, W, H, &cab,  &detCab,  &camX, &camY);
        BOOL okPies = mm_w2s(view, proj, wpFeet, NO, W, H, &pies, &detPies, &camX, &camY);
        if (!okCab || !okPies) {
            /* v0.5.0: sin caja (detras de la camara o no proyectable), pero el
               track queda: el radar, el contador y la flecha lo siguen viendo. */
            if (tslot >= 0) {
                g_tracks[tslot].behind = (detCab || detPies) ? 1 : 0;
                g_tracks[tslot].vx = camX; g_tracks[tslot].vy = camY;
            }
            continue;
        }
        /* 0.13: geometria de la caja en mm_math.h (testeada en C nativo).
           1 = dibujable; 0 = fuera de cuadro (queda apuntable); -1 = alto invalido. */
        float bcx = 0.0f, bh = 0.0f;
        int bstate = mm_math_box((float)cab.x, (float)cab.y, (float)pies.x, (float)pies.y,
                                 (float)W, (float)H, &bcx, &bh);
        if (bstate == 0) {
            /* v0.5.0: muy fuera del cuadro: sin caja, pero la flecha puede
               apuntarlo (misma idea que el viejo "fuera de pantalla"). */
            if (tslot >= 0) {
                g_tracks[tslot].has_sx = 1;
                g_tracks[tslot].sx = (float)((cab.x + pies.x) * 0.5);
                g_tracks[tslot].sy = (float)((cab.y + pies.y) * 0.5);
            }
            continue;
        }
        if (bstate < 0) {
            /* v0.7.6: a distancias largas (~>=430m) el pawn visto HEAD-ON
               proyecta a <3 px: la pinhole divide por local_z y ese es ~=
               world_dist cuando el pawn esta en el eje optico. Mirado desde
               un lado, local_z = world_dist * cos(angulo) < world_dist y la
               caja proyecta mas grande, por eso el pawn "aparece de lado y
               desaparece de frente" al jugador. Antes mm_math_box devolvia
               -1 y se descartaba: ahora clamp a 3 px para que el pawn siga
               siendo un pip visible (sigue descartando bh > 2*h, que son
               proyecciones basura por pawn invertido o fuera del frustum). */
            float pre_bh = (float)(pies.y - cab.y);
            if (pre_bh > 0.0f && pre_bh < 3.0f) {
                bh  = 3.0f;
                bcx = (float)((cab.x + pies.x) * 0.5);
            } else {
                continue;
            }
        }

        CGFloat bw = (CGFloat)bh * 0.45;
        CGFloat cx = (CGFloat)bcx;

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

        /* --- 2026-11: municion + ADS del enemigo (toggle propio, apagado por
           defecto). Cadena: pawn -> InventoryManager -> arma actual ->
           WeaponFireComponent[] -> m_ClipAmmoCount. Todo con guardas: si algo
           no cuadra se queda en "sin dato" y no se dibuja. --- */
        int ammo = -1, ammoMax = 0, ads = 0;
        int dInv = 0, dWep = 0, dFl = 0, dCnt = 0, dOwner = -1;
        if (heavy && opts->ammoTag) {
            uint64_t invm = 0, wep = 0;
            if (mm_r64((uintptr_t)pawn + OFF_PAWN_INVMGR, &invm) && invm != 0 &&
                mm_r64((uintptr_t)invm + OFF_INVM_CURWEP, &wep) && wep != 0) {
                dInv = 1; dWep = 1;
                uint8_t aim = 0;
                if (mm_vm_read((uintptr_t)wep + OFF_WEP_AIMING, &aim, 1) && (aim & 1)) ads = 1;
                uint64_t fl = 0;
                if (mm_r64((uintptr_t)wep + OFF_WEP_FIRELST, &fl) && fl != 0) {
                    dFl = 1;
                    int32_t fcount = 0;
                    if (mm_vm_read((uintptr_t)fl + OFF_LIST_SIZE, &fcount, sizeof(fcount)) &&
                        fcount > 0 && fcount <= 8) {
                        dCnt = fcount;
                        for (int fi = 0; fi < fcount && ammoMax == 0; fi++) {
                            uint64_t fc = 0;
                            if (!mm_r64((uintptr_t)fl + OFF_ARR_DATA + (uintptr_t)fi * 8, &fc) ||
                                fc == 0)
                                continue;
                            uint64_t owner = 0;
                            if (!mm_r64((uintptr_t)fc + OFF_FC_OWNER, &owner)) continue;
                            dOwner = (owner == pawn) ? 1 : 0;
                            if (owner != pawn) continue;   /* componente de otra arma/dueno */
                            int clip = -1, cmax = 0;
                            if (mm_vm_read((uintptr_t)fc + OFF_FC_CLIP, &clip, sizeof(clip)) &&
                                mm_vm_read((uintptr_t)fc + OFF_FC_CLIPMAX, &cmax, sizeof(cmax)) &&
                                clip >= 0 && clip <= 9999 && cmax > 0 && cmax <= 9999 &&
                                clip <= cmax) {
                                ammo = clip;
                                ammoMax = cmax;
                            }
                        }
                    }
                }
            }
            if (ammoMax <= 0) ads = 0;   /* ADS solo si el arma actual valido */
        }

        /* 0.8.8: muestra para la sonda (primeras MM_ESPREAD_N cajas) */
        if (g_read_n < MM_ESPREAD_N) {
            MMEspRead *r = &g_read[g_read_n++];
            memset(r, 0, sizeof(*r));
            r->pawn = pawn; r->ent = ent;
            r->team = teamEnt;
            r->armor = armor; r->invis = invisible;
            r->healing = healing; r->veh = inVeh;
            r->ammo = ammo; r->ammoMax = ammoMax; r->ads = ads;
            r->invOk = dInv; r->wepOk = dWep; r->flOk = dFl;
            r->fcount = dCnt; r->ownerOk = dOwner;
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
        nb.wx = wp[0]; nb.wy = wp[1]; nb.wz = wp[2];   /* v0.4.4: world-pos */
        nb.hp = hp;
        nb.hpMax = hpMax;
        nb.robot = robot;
        nb.downed = downed;
        nb.tags = (uint32_t)((healing ? 1u : 0u) | (invisible ? 2u : 0u) |
                             (inVeh ? 4u : 0u) | (ads ? 8u : 0u));
        nb.ammo = ammo;
        nb.ammoMax = ammoMax;
        nb.armor = armor;
        nb.alive = 1;
        nb.hasName = (nm[0] != 0) ? 1 : 0;
        memcpy(nb.name, nm, sizeof(nb.name));

        /* v0.2.4: estabilidad por pawn. La lista cambia de orden y las cajas
           saltaban; cada pawn conserva su caja y se interpola suavemente. */
        for (int q = 0; q < g_box_count; q++) {
            if (g_boxes[q].pawn != pawn || !g_boxes[q].alive) continue;
            if (col_dt > 0.0f) {   /* 0.9.3: velocidad desde la posicion anterior */
                nb.vx = (wp[0] - g_boxes[q].wx) / col_dt;
                nb.vy = (wp[1] - g_boxes[q].wy) / col_dt;
                nb.vz = (wp[2] - g_boxes[q].wz) / col_dt;
                if (nb.vx > 15.0f) nb.vx = 15.0f; if (nb.vx < -15.0f) nb.vx = -15.0f;
                if (nb.vy > 15.0f) nb.vy = 15.0f; if (nb.vy < -15.0f) nb.vy = -15.0f;
                if (nb.vz > 15.0f) nb.vz = 15.0f; if (nb.vz < -15.0f) nb.vz = -15.0f;
            }
            if (!heavy) {   /* 0.9.2: conserva municion/armadura del pase anterior */
                nb.ammo = g_boxes[q].ammo;
                nb.ammoMax = g_boxes[q].ammoMax;
                nb.armor = g_boxes[q].armor;
                nb.tags = (uint32_t)((nb.tags & 8u) | (g_boxes[q].tags & 7u));
            }
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
        if (tslot >= 0) g_tracks[tslot].proj = 1;   /* v0.5.0: track con caja */
    }

    /* v0.5.0: contadores desde el TRACK mundial (no desde las cajas): incluye
       a los que quedaron detras de la camara o fuera del cuadro. Antes el
       marcador JUG/BOT solo contaba lo dibujable y la espalda "no existia". */
    g_count_players = 0; g_count_bots = 0;
    for (int q = 0; q < g_track_count && q < MM_MAX_TRACKS; q++) {
        if (!g_tracks[q].alive) continue;
        if (g_tracks[q].robot) g_count_bots++; else g_count_players++;
    }

    memcpy(g_boxes, nuevos, sizeof(MMEspBox) * (size_t)drawn);
    g_box_count = drawn;
    if (opts->trails) mm_trails_update(g_boxes, g_box_count);
    else              mm_trails_clear();
    g_collect_ms = (CACurrentMediaTime() - _col_t0) * 1000.0;   /* v0.4.4: telemetria */
    s_col_prev = _col_now;
    mm_scene_bump();   /* v0.7.3 (perf): la escena cambio para el skip O(1) */
    g_esp_diag = [NSString stringWithFormat:
                  @"cam=ok lista=%d cajas=%d trk=%d jug=%d bot=%d hp=%s%@",
                  total, drawn, g_track_count, g_count_players, g_count_bots,
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
            MM_LOG(@"%s alerta sin VC: %@ / %@", MM_TAG, titulo, msg);
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
        MM_LOG(@"%s alerta: %@", MM_TAG, e.reason);
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
        MM_LOG(@"%s guest: %@ (%@)", MM_TAG, p,
              ok ? @"borrado" : (err.localizedDescription ?: @"no existia"));
    }

    NSDictionary *q = @{ (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword };
    OSStatus st = SecItemDelete((__bridge CFDictionaryRef)q);
    MM_LOG(@"%s guest: keychain generic=%d", MM_TAG, (int)st);
}

static void mm_guest_countdown(UIAlertController *a, int sec)
{
    if (a != nil) {
        a.message = [NSString stringWithFormat:
                     @"El juego se cerrará en %d segundos.", sec];
    }
    if (sec <= 0) {
        MM_LOG(@"%s guest: _exit(0)", MM_TAG);
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
        MM_LOG(@"%s guest reset: %@", MM_TAG, e.reason);
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
            @"ui=safe=%d quickbar=%d haptics=%d lang=%d objetivos=%d pint_s=%.0f\n"
            @"salud=temp=%d captura=%d auto_stream=%d guard=%d boot=%d stream_eff=%d cfg=%d crumb=%s\n"
            @"overlay=brujula=%d estelas=%d declutter=%d radar_cam=%d lect_s=%.0f mem_mb=%.0f fov=%.0f\n"
            @"render=%s cajas=%d link=%s\n"
            @"probe=%s\n"
            @"br_probe=%s\n"
            @"br_zone=%s\n"
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
            (int)mm_def_float(@"mm_esp_range", 500.0f),
            (int)mm_def_bool(@"mm_esp_count", NO),
            (int)mm_def_float(@"mm_esp_box_style", 0.0f),
            (int)mm_def_float(@"mm_esp_theme", 0.0f),
            (int)mm_def_bool(@"mm_stream", NO),
            (int)mm_def_bool(@"mm_safe_mode", NO),
            (int)mm_def_bool(@"mm_quickbar", NO),
            (int)mm_def_bool(@"mm_haptics", YES),
            mm_lang(),
            (int)mm_def_bool(@"mm_x_targetlist", NO),
            g_paint_fps,
            g_thermal_level, g_captured,
            (int)mm_def_bool(@"mm_auto_stream", YES),
            g_secure_canvas_state, g_dirty_boots,
            (int)mm_stream_effective(), g_cfg_valid, g_last_action,
            (int)mm_def_bool(@"mm_x_bearings", NO),
            (int)mm_def_bool(@"mm_x_trails", NO),
            (int)mm_def_bool(@"mm_x_declutter", NO),
            (int)mm_def_bool(@"mm_x_radar_cam", YES),
            g_reads_per_s, g_mem_mb, g_fov_deg,
            (g_esp != nil && g_esp.superview != nil && !g_esp.hidden) ? "on" : "off",
            g_box_count,
            (g_link != nil && !g_link.paused) ? "activo" : "parado",
            g_probe != nil ? g_probe.UTF8String : "pendiente",
            g_br_probe != nil ? g_br_probe.UTF8String : "pendiente",
            g_br_zone_info != nil ? g_br_zone_info.UTF8String : "off",
            (g_esp_diag != nil) ? g_esp_diag : @"-",
            g_esp_players, g_box_count, g_count_players, g_count_bots,
            mm_nojb_resumen(),
            nota];

        [txt writeToFile:[docs stringByAppendingPathComponent:@"modmenu_status.txt"]
               atomically:YES
                 encoding:NSUTF8StringEncoding
                    error:NULL];
    } @catch (NSException *e) {
        MM_LOG(@"%s no pude escribir el archivo de estado: %@", MM_TAG, e.reason);
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
_Static_assert(MM_THEME_COUNT == MM_THEME_CUSTOM,
               "MM_THEME_CUSTOM debe coincidir con g_mm_themes");

/* v0.7.0 (1.16): acento personalizado. El indice MM_THEME_COUNT es el slot
   custom; los temas fijos no cambian. Se lee una vez por uso, no por frame. */
static UIColor *mm_accent_custom(BOOL secundario)
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *suf = secundario ? @"2" : @"1";
    float r = [ud floatForKey:[@"mm_accent" stringByAppendingFormat:@"%@_r", suf]];
    float g = [ud floatForKey:[@"mm_accent" stringByAppendingFormat:@"%@_g", suf]];
    float b = [ud floatForKey:[@"mm_accent" stringByAppendingFormat:@"%@_b", suf]];
    if ((r + g + b) < 0.05f) {
        if (secundario) { r = 0.63f; g = 0.30f; b = 1.00f; }
        else            { r = 0.20f; g = 1.00f; b = 0.58f; }
    }
    return [UIColor colorWithRed:r green:g blue:b alpha:1.0];
}

static int mm_theme_idx(void)
{
    int i = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"mm_theme_accent"];
    if (i < 0 || i > MM_THEME_CUSTOM) i = 0;   /* == CUSTOM -> acento custom */
    return i;
}

static UIColor *mm_neon_green(void)
{
    if (mm_theme_idx() == MM_THEME_CUSTOM) return mm_accent_custom(NO);
    MMTheme t = g_mm_themes[mm_theme_idx()];
    return [UIColor colorWithRed:t.ar green:t.ag blue:t.ab alpha:1.0];
}

static UIColor *mm_neon_purple(void)
{
    if (mm_theme_idx() == MM_THEME_CUSTOM) return mm_accent_custom(YES);
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
        [UIBezierPath bezierPathWithRoundedRect:b cornerRadius:22.0].CGPath;
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
           !mm_stream_effective();
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
    /* perf: el coletor llama esto ~30 Hz; el contador cambia lento. 4 Hz basta. */
    static double s_last = 0.0;
    double nowc = CACurrentMediaTime();
    if (s_last > 0.0 && nowc - s_last < 0.25) return;
    s_last = nowc;

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

/*---------------------------------------------------------------------------
 * v0.8.0: primitivas del panel horizontal CLOUD.
 * Son vistas estaticas: nada se recalcula por frame. El estado vivo sigue en
 * NSUserDefaults y en los callbacks existentes, para no tocar el motor ESP.
 *--------------------------------------------------------------------------*/
static UIFont *mm_cloud_font(CGFloat size, UIFontWeight weight)
{
    return [UIFont systemFontOfSize:size weight:weight];
}

static UILabel *mm_cloud_label(NSString *text, CGFloat size, UIFontWeight weight,
                               UIColor *color)
{
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectZero];
    l.text = text;
    l.textColor = color;
    l.font = mm_cloud_font(size, weight);
    l.adjustsFontSizeToFitWidth = YES;
    l.minimumScaleFactor = 0.70;
    l.numberOfLines = 1;
    return l;
}

/* Tarjeta de contenido: vidrio oscuro, radio amplio y acento fino. */
static UIView *mm_cloud_card(NSString *title, CGFloat x, CGFloat w, CGFloat h)
{
    UIView *card = [[UIView alloc] initWithFrame:CGRectMake(x, 0.0, w, h)];
    card.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.036];
    card.layer.cornerRadius = 16.0;
    card.layer.borderWidth = 0.7;
    card.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.075].CGColor;
    card.clipsToBounds = YES;

    UIView *tick = [[UIView alloc] initWithFrame:CGRectMake(14.0, 14.0, 3.0, 11.0)];
    tick.backgroundColor = [mm_neon_green() colorWithAlphaComponent:0.90];
    tick.layer.cornerRadius = 1.5;
    [card addSubview:tick];

    UILabel *l = mm_cloud_label([mm_tr(title) uppercaseString], 9.6,
                                UIFontWeightSemibold,
                                [UIColor colorWithWhite:0.63 alpha:1.0]);
    l.frame = CGRectMake(24.0, 10.0, w - 37.0, 19.0);
    [card addSubview:l];

    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(14.0, 34.0, w - 28.0, 0.5)];
    line.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.06];
    line.userInteractionEnabled = NO;
    [card addSubview:line];
    /* C-13: brillo glass en el borde superior. */
    UIView *gl = [[UIView alloc] initWithFrame:CGRectMake(10.0, 0.0, w - 20.0, 0.7)];
    gl.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.10];
    gl.userInteractionEnabled = NO;
    [card addSubview:gl];
    return card;
}

static UILabel *mm_cloud_caption(NSString *text, CGFloat w)
{
    UILabel *l = mm_cloud_label(mm_tr(text), 9.4, UIFontWeightSemibold,
                                [UIColor colorWithWhite:0.60 alpha:1.0]);
    l.frame = CGRectMake(0.0, 0.0, w, 14.0);
    return l;
}

/* Fila compacta: etiqueta + switch. `dim` la ata al maestro ESP. */
static UIView *mm_cloud_switch_row(NSString *title, NSString *key, BOOL def,
                                   CGFloat w, BOOL dim)
{
    UIView *row = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, w, MM_CLOUD_ROW_H)];
    UILabel *l = mm_cloud_label(mm_tr(title), 10.8, UIFontWeightMedium,
                                [UIColor colorWithWhite:0.91 alpha:1.0]);
    l.frame = CGRectMake(0.0, 0.0, w - 43.0, MM_CLOUD_ROW_H);
    [row addSubview:l];

    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(0.0, 0.0, 51.0, 31.0)];
    sw.on = mm_def_bool(key, def);
    sw.onTintColor = mm_neon_green();
    sw.accessibilityIdentifier = key;
    sw.accessibilityLabel = mm_tr(title);
    sw.center = CGPointMake(w - 18.0, MM_CLOUD_ROW_H / 2.0);
    sw.transform = CGAffineTransformMakeScale(0.74, 0.74);
    [sw addTarget:[MMTargets shared] action:@selector(onSwitch:)
        forControlEvents:UIControlEventValueChanged];
    [row addSubview:sw];
    if (dim) [g_sub_switches addObject:sw];
    return row;
}

static UISegmentedControl *mm_cloud_seg(NSArray *items, CGFloat w)
{
    UISegmentedControl *s = [[UISegmentedControl alloc] initWithItems:items];
    s.frame = CGRectMake(0.0, 0.0, w, 28.0);
    s.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.045];
    if (@available(iOS 13.0, *))
        s.selectedSegmentTintColor = [mm_neon_green() colorWithAlphaComponent:0.24];
    s.layer.cornerRadius = 8.0;
    s.layer.masksToBounds = YES;
    s.layer.borderWidth = 0.6;
    s.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.07].CGColor;
    UIFont *f = mm_cloud_font(8.7, UIFontWeightSemibold);
    [s setTitleTextAttributes:@{ NSForegroundColorAttributeName:
                                     [UIColor colorWithWhite:0.70 alpha:1.0],
                                 NSFontAttributeName: f }
                      forState:UIControlStateNormal];
    [s setTitleTextAttributes:@{ NSForegroundColorAttributeName: [UIColor whiteColor],
                                 NSFontAttributeName: f }
                      forState:UIControlStateSelected];
    return s;
}

static UIButton *mm_cloud_action(NSString *title, UIColor *bg, CGFloat w, CGFloat h)
{
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    b.frame = CGRectMake(0.0, 0.0, w, h);
    b.backgroundColor = bg;
    b.layer.cornerRadius = 8.0;
    b.layer.borderWidth = 0.6;
    b.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.10].CGColor;
    b.titleLabel.font = mm_cloud_font(10.0, UIFontWeightSemibold);
    b.titleLabel.adjustsFontSizeToFitWidth = YES;
    b.titleLabel.minimumScaleFactor = 0.72;
    [b setTitle:mm_tr(title) forState:UIControlStateNormal];
    [b setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    return b;
}

static UISlider *mm_cloud_slider(float lo, float hi, float value, NSString *key,
                                SEL action, CGFloat w)
{
    UISlider *s = [[UISlider alloc] initWithFrame:CGRectMake(0.0, 0.0, w, 24.0)];
    s.minimumValue = lo;
    s.maximumValue = hi;
    s.value = value;
    s.continuous = YES;
    s.tintColor = mm_neon_green();
    s.thumbTintColor = [UIColor colorWithWhite:0.96 alpha:1.0];
    s.accessibilityIdentifier = key;
    [s addTarget:[MMTargets shared] action:action
        forControlEvents:UIControlEventValueChanged];
    return s;
}

/* Coloca una vista dentro de una tarjeta, respetando el padding interno. */
static void mm_cloud_put(UIView *card, UIView *v, CGFloat y)
{
    CGRect f = v.frame;
    f.origin.x = MM_CLOUD_CARD_INNER;
    f.origin.y = y;
    v.frame = f;
    [card addSubview:v];
}

/*---------------------------------------------------------------------------
 * v0.8.0: paginas del panel CLOUD.
 * Tres tarjetas por pagina. Cada control conserva su clave y su callback
 * historicos: la UI cambia, el contrato de datos no.
 *--------------------------------------------------------------------------*/
static void mm_cloud_row(UIView *card, NSString *title, NSString *key,
                         BOOL def, CGFloat y, BOOL dim)
{
    CGFloat w = MM_CLOUD_CARD_W - (MM_CLOUD_CARD_INNER * 2.0);
    UIView *row = mm_cloud_switch_row(title, key, def, w, dim);
    mm_cloud_put(card, row, y);
}

/* Fila informativa (sin toggle): feature fija que el cliente ve como ACTIVA. */
static void mm_cloud_static_row(UIView *card, NSString *title, NSString *value,
                                CGFloat y)
{
    CGFloat w = MM_CLOUD_CARD_W - (MM_CLOUD_CARD_INNER * 2.0);
    UIView *row = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, w, MM_CLOUD_ROW_H)];
    UILabel *l = mm_cloud_label(mm_tr(title), 10.8, UIFontWeightMedium,
                                [UIColor colorWithWhite:0.91 alpha:1.0]);
    l.frame = CGRectMake(0.0, 0.0, w - 64.0, MM_CLOUD_ROW_H);
    [row addSubview:l];
    UILabel *v = mm_cloud_label(value, 9.6, UIFontWeightSemibold, mm_neon_green());
    v.textAlignment = NSTextAlignmentRight;
    v.frame = CGRectMake(w - 64.0, 0.0, 64.0, MM_CLOUD_ROW_H);
    [row addSubview:v];
    mm_cloud_put(card, row, y);
}

static void mm_cloud_card_caption(UIView *card, NSString *text, CGFloat y)
{
    CGFloat w = MM_CLOUD_CARD_W - (MM_CLOUD_CARD_INNER * 2.0);
    UILabel *l = mm_cloud_caption(text, w);
    l.frame = CGRectMake(MM_CLOUD_CARD_INNER, y, w, 14.0);
    [card addSubview:l];
}

static void mm_cloud_build_combat(UIView *page)
{
    CGFloat iw = MM_CLOUD_CARD_W - (MM_CLOUD_CARD_INNER * 2.0);

    /* ESP: que se dibuja de cada enemigo. */
    UIView *a = mm_cloud_card(@"OBJETIVOS", 0.0, MM_CLOUD_CARD_W, MM_CLOUD_BODY_H);
    NSArray *keys = @[ @"mm_esp_master", @"mm_esp_box", @"mm_esp_players",
                       @"mm_esp_bots", @"mm_esp_name", @"mm_esp_dist" ];
    NSArray *titles = @[ @"ESP maestro", @"Cajas", @"Jugadores", @"Bots",
                         @"Nombres", @"Distancia" ];
    for (NSUInteger i = 0; i < keys.count; i++)
        mm_cloud_row(a, titles[i], keys[i], NO,
                     38.0 + (CGFloat)i * MM_CLOUD_ROW_H, (i != 0));
    [page addSubview:a];

    /* Cuerpo: salud, lineas y relleno. */
    UIView *b = mm_cloud_card(@"CUERPO", MM_CLOUD_CARD_W + MM_CLOUD_CARD_GAP,
                              MM_CLOUD_CARD_W, MM_CLOUD_BODY_H);
    NSArray *rkeys = @[ @"mm_esp_health", @"mm_esp_lines", @"mm_esp_lines_top",
                        @"mm_esp_fill" ];
    NSArray *rtit = @[ @"Salud", @"Lineas", @"Lineas desde arriba", @"Relleno" ];
    for (NSUInteger i = 0; i < rkeys.count; i++)
        mm_cloud_row(b, rtit[i], rkeys[i], NO,
                     38.0 + (CGFloat)i * MM_CLOUD_ROW_H, YES);
    [page addSubview:b];

    /* Alcance y features fijas del binario. */
    UIView *c = mm_cloud_card(@"ALCANCE", (MM_CLOUD_CARD_W + MM_CLOUD_CARD_GAP) * 2.0,
                              MM_CLOUD_CARD_W, MM_CLOUD_BODY_H);
    float rng = mm_def_float(@"mm_esp_range", 500.0f);
    UILabel *rl = mm_cloud_caption(@"Rango ESP", 108.0);
    rl.frame = CGRectMake(MM_CLOUD_CARD_INNER, 30.0, 108.0, 14.0);
    [c addSubview:rl];
    g_range_val = mm_cloud_label([NSString stringWithFormat:@"%d m", (int)(rng + 0.5f)],
                                 10.2, UIFontWeightSemibold, mm_neon_green());
    g_range_val.textAlignment = NSTextAlignmentRight;
    g_range_val.frame = CGRectMake(MM_CLOUD_CARD_INNER + 112.0, 30.0, iw - 112.0, 14.0);
    [c addSubview:g_range_val];
    UISlider *rs = mm_cloud_slider(20.0f, 500.0f, rng, @"mm_esp_range",
                                   @selector(onSlider:), iw);
    rs.frame = CGRectMake(MM_CLOUD_CARD_INNER, 44.0, iw, 24.0);
    [c addSubview:rs];

    float maxn = mm_def_float(@"mm_x_maxn", 0.0f);
    UILabel *ml = mm_cloud_caption(@"Limite cercano", 108.0);
    ml.frame = CGRectMake(MM_CLOUD_CARD_INNER, 76.0, 108.0, 14.0);
    [c addSubview:ml];
    g_maxn_val = mm_cloud_label((maxn < 0.5f) ? mm_tr(@"Todos")
                                              : [NSString stringWithFormat:@"%d", (int)(maxn + 0.5f)],
                                10.2, UIFontWeightSemibold, mm_neon_green());
    g_maxn_val.textAlignment = NSTextAlignmentRight;
    g_maxn_val.frame = CGRectMake(MM_CLOUD_CARD_INNER + 112.0, 76.0, iw - 112.0, 14.0);
    [c addSubview:g_maxn_val];
    UISlider *ms = mm_cloud_slider(0.0f, (float)MM_MAX_BOXES, maxn, @"mm_x_maxn",
                                   @selector(onMaxN:), iw);
    ms.frame = CGRectMake(MM_CLOUD_CARD_INNER, 90.0, iw, 24.0);
    [c addSubview:ms];

    mm_cloud_static_row(c, @"No recoil", @"ACTIVO", 122.0);
    mm_cloud_static_row(c, @"No spread", @"ACTIVO", 150.0);
    mm_cloud_static_row(c, @"Fast reload", @"ACTIVO", 178.0);
    [page addSubview:c];
}


static void mm_cloud_build_aim(UIView *page)
{
    CGFloat iw = MM_CLOUD_CARD_W - (MM_CLOUD_CARD_INNER * 2.0);

    /* 1) AIMBOT — tres switches y la altura. Nada mas. */
    UIView *a = mm_cloud_card(@"AIMBOT", 0.0, MM_CLOUD_CARD_W, MM_CLOUD_BODY_H);
    mm_cloud_row(a, @"Aim lock", @"mm_x_aimlock", NO, 30.0, NO);
    mm_cloud_row(a, @"Solo al apuntar (ADS)", @"mm_lock_ads", NO, 58.0, NO);
    mm_cloud_card_caption(a, @"Altura vs cabeza (m)", 90.0);
    UISlider *ah = mm_cloud_slider(-0.6f, 0.3f, g_aim_height, @"mm_aim_height",
                                   @selector(onAimHeight:), iw);
    ah.frame = CGRectMake(MM_CLOUD_CARD_INNER, 100.0, iw, 24.0);
    [a addSubview:ah];
    [page addSubview:a];

    /* 2) ARMAS — con cuales actua el lock. */
    UIView *b = mm_cloud_card(@"ARMAS", MM_CLOUD_CARD_W + MM_CLOUD_CARD_GAP,
                              MM_CLOUD_CARD_W, MM_CLOUD_BODY_H);
    mm_cloud_row(b, @"Fusil", @"mm_lock_rifle", YES, 30.0, NO);
    mm_cloud_row(b, @"Subfusil", @"mm_lock_smg", YES, 58.0, NO);
    mm_cloud_row(b, @"Escopeta", @"mm_lock_shotgun", YES, 86.0, NO);
    mm_cloud_row(b, @"Franco", @"mm_lock_sniper", YES, 114.0, NO);
    [page addSubview:b];

    /* 3) ASISTENCIA — la del juego. NO depende del lock. */
    UIView *c = mm_cloud_card(@"ASISTENCIA", (MM_CLOUD_CARD_W + MM_CLOUD_CARD_GAP) * 2.0,
                              MM_CLOUD_CARD_W, MM_CLOUD_BODY_H);
    mm_cloud_row(c, @"Aimbot (asist)", @"mm_x_aim_on", g_aim_on, 30.0, NO);
    mm_cloud_card_caption(c, @"Fuerza de aim", 58.0);
    UISlider *as = mm_cloud_slider(0.0f, 28.0f, g_aim_strength, @"mm_x_aim_strength",
                                   @selector(onAimStrength:), iw);
    as.frame = CGRectMake(MM_CLOUD_CARD_INNER, 68.0, iw, 22.0);
    [c addSubview:as];
    mm_cloud_card_caption(c, @"FOV de aim", 92.0);
    UISlider *af = mm_cloud_slider(5.0f, 180.0f, g_aim_fov, @"mm_x_aim_fov",
                                   @selector(onAimFov:), iw);
    af.frame = CGRectMake(MM_CLOUD_CARD_INNER, 102.0, iw, 22.0);
    [c addSubview:af];
    mm_cloud_card_caption(c, @"Suavizado de aim", 126.0);
    UISlider *as2 = mm_cloud_slider(0.0f, 1.0f, g_aim_smooth, @"mm_x_aim_smooth",
                                    @selector(onAimSmooth:), iw);
    as2.frame = CGRectMake(MM_CLOUD_CARD_INNER, 136.0, iw, 22.0);
    [c addSubview:as2];
    UILabel *cn = mm_cloud_caption(@"El lock usa FOV y Suavizado. El asist va siempre.", iw);
    cn.frame = CGRectMake(MM_CLOUD_CARD_INNER, 166.0, iw, 20.0);
    cn.numberOfLines = 2;
    cn.textColor = [UIColor colorWithWhite:0.48 alpha:1.0];
    [c addSubview:cn];
    [page addSubview:c];
}

static void mm_cloud_build_visual(UIView *page)
{
    CGFloat iw = MM_CLOUD_CARD_W - (MM_CLOUD_CARD_INNER * 2.0);

    UIView *a = mm_cloud_card(@"ESTILO", 0.0, MM_CLOUD_CARD_W, MM_CLOUD_BODY_H);
    mm_cloud_card_caption(a, @"Estilo de caja", 38.0);
    int bstyle = (int)mm_def_float(@"mm_esp_box_style", 0.0f);
    UISegmentedControl *bs = mm_cloud_seg(@[ mm_tr(@"Completa"), mm_tr(@"Esquinas") ], iw);
    bs.frame = CGRectMake(MM_CLOUD_CARD_INNER, 54.0, iw, 28.0);
    bs.selectedSegmentIndex = (bstyle == 1) ? 1 : 0;
    [bs addTarget:[MMTargets shared] action:@selector(onBoxStyle:)
        forControlEvents:UIControlEventValueChanged];
    [a addSubview:bs];

    mm_cloud_card_caption(a, @"Tema ESP", 92.0);
    int etheme = (int)mm_def_float(@"mm_esp_theme", 0.0f);
    if (etheme < 0 || etheme > 2) etheme = 0;
    UISegmentedControl *ts = mm_cloud_seg(@[ mm_tr(@"Clasico"), mm_tr(@"Neon"),
                                             mm_tr(@"Blanco") ], iw);
    ts.frame = CGRectMake(MM_CLOUD_CARD_INNER, 108.0, iw, 28.0);
    ts.selectedSegmentIndex = etheme;
    [ts addTarget:[MMTargets shared] action:@selector(onTheme:)
        forControlEvents:UIControlEventValueChanged];
    [a addSubview:ts];

    /* Unica gestion de perfiles: tema + configuracion en 5 slots. */
    mm_cloud_card_caption(a, @"Perfiles (tema + config)", 142.0);
    g_profile_seg = mm_cloud_seg(@[ @"P1", @"P2", @"P3", @"P4", @"P5" ], iw);
    g_profile_seg.frame = CGRectMake(MM_CLOUD_CARD_INNER, 156.0, iw, 24.0);
    g_profile_seg.selectedSegmentIndex = g_profile_slot;
    [g_profile_seg addTarget:[MMTargets shared] action:@selector(onProfileSlot:)
            forControlEvents:UIControlEventValueChanged];
    [a addSubview:g_profile_seg];
    CGFloat halfW = (iw - 8.0) / 2.0;
    UIButton *psv = mm_cloud_action(@"Guardar",
        [UIColor colorWithRed:0.08 green:0.38 blue:0.20 alpha:0.96], halfW, 28.0);
    psv.frame = CGRectMake(MM_CLOUD_CARD_INNER, 184.0, halfW, 26.0);
    [psv addTarget:[MMTargets shared] action:@selector(onProfileSave)
        forControlEvents:UIControlEventTouchUpInside];
    [a addSubview:psv];
    UIButton *pld = mm_cloud_action(@"Cargar",
        [UIColor colorWithRed:0.08 green:0.24 blue:0.42 alpha:0.96], halfW, 28.0);
    pld.frame = CGRectMake(MM_CLOUD_CARD_INNER + halfW + 8.0, 184.0, halfW, 26.0);
    [pld addTarget:[MMTargets shared] action:@selector(onProfileLoad)
        forControlEvents:UIControlEventTouchUpInside];
    [a addSubview:pld];

    [page addSubview:a];

    UIView *c = mm_cloud_card(@"EXTRAS", (MM_CLOUD_CARD_W + MM_CLOUD_CARD_GAP),
                              MM_CLOUD_CARD_W, MM_CLOUD_BODY_H);
    mm_cloud_row(c, @"Estelas (ultimos 2 s)", @"mm_x_trails", NO, 38.0, YES);
    mm_cloud_row(c, @"Brujula de bearings", @"mm_x_bearings", NO, 66.0, YES);
    /* 2026-11: lecturas RE nuevas (team / estado / municion). Default OFF hasta
       validar en device (docs/re-lecturas-1057.md). */
    mm_cloud_row(c, @"Filtrar equipo", @"mm_x_team_filter", NO, 94.0, YES);
    mm_cloud_row(c, @"Ignorar caidos (aim)", @"mm_x_ignore_down", NO, 122.0, NO);
    mm_cloud_row(c, @"Estado (cura/invisible/veh)", @"mm_x_state_tags", NO, 154.0, YES);
    mm_cloud_row(c, @"Municion + ADS", @"mm_x_ammo", NO, 182.0, YES);
    [page addSubview:c];
}

static void mm_cloud_build_radar(UIView *page)
{
    CGFloat iw = MM_CLOUD_CARD_W - (MM_CLOUD_CARD_INNER * 2.0);

    UIView *a = mm_cloud_card(@"RADAR", 0.0, MM_CLOUD_CARD_W, MM_CLOUD_BODY_H);
    mm_cloud_row(a, @"Radar 2D", @"mm_x_radar", NO, 38.0, YES);
    mm_cloud_row(a, @"Radar: arriba = mi vista", @"mm_x_radar_cam", YES, 66.0, YES);
    mm_cloud_row(a, @"Flecha fuera de pantalla", @"mm_x_arrow", NO, 94.0, YES);
    mm_cloud_row(a, @"Aviso enemigo cerca", @"mm_x_warn", NO, 122.0, YES);
    UILabel *note = mm_cloud_caption(@"Radar y flechas no leen memoria extra.", iw);
    note.frame = CGRectMake(MM_CLOUD_CARD_INNER, 164.0, iw, 28.0);
    note.numberOfLines = 2;
    note.textColor = [UIColor colorWithWhite:0.48 alpha:1.0];
    [a addSubview:note];
    [page addSubview:a];

    UIView *b = mm_cloud_card(@"HUD", MM_CLOUD_CARD_W + MM_CLOUD_CARD_GAP,
                              MM_CLOUD_CARD_W, MM_CLOUD_BODY_H);
    mm_cloud_row(b, @"Contador JUG / BOT", @"mm_esp_count", NO, 38.0, NO);
    mm_cloud_row(b, @"Vibracion al tocar", @"mm_haptics", YES, 66.0, NO);
    mm_cloud_row(b, @"Guard de captura", @"mm_guard_capture", NO, 94.0, NO);
    mm_cloud_row(b, @"Stream Mode", @"mm_stream", NO, 122.0, NO);
    mm_cloud_row(b, @"FPS en pantalla", @"mm_x_fps", NO, 150.0, NO);
    [page addSubview:b];

    UIView *c = mm_cloud_card(@"PANTALLA", (MM_CLOUD_CARD_W + MM_CLOUD_CARD_GAP) * 2.0,
                              MM_CLOUD_CARD_W, MM_CLOUD_BODY_H);
    mm_cloud_card_caption(c, @"Opacidad del menu", 38.0);
    UISlider *op = mm_cloud_slider(0.4f, 1.0f,
                                   mm_def_float(@"mm_menu_opacity", 1.0f),
                                   @"mm_menu_opacity", @selector(onMenuOpacity:), iw);
    op.frame = CGRectMake(MM_CLOUD_CARD_INNER, 54.0, iw, 24.0);
    [c addSubview:op];
    mm_cloud_card_caption(c, @"Escala del menu", 84.0);
    UISlider *sc = mm_cloud_slider(0.8f, 1.2f,
                                   mm_def_float(@"mm_menu_scale", 1.0f),
                                   @"mm_menu_scale", @selector(onMenuScale:), iw);
    sc.frame = CGRectMake(MM_CLOUD_CARD_INNER, 100.0, iw, 24.0);
    [c addSubview:sc];
    mm_cloud_row(c, @"Modo seguro", @"mm_safe_mode", NO, 132.0, NO);

    UIButton *panic = mm_cloud_action(@"PANICO / OCULTAR",
        [UIColor colorWithRed:0.48 green:0.08 blue:0.10 alpha:0.95], iw, 30.0);
    panic.frame = CGRectMake(MM_CLOUD_CARD_INNER, 166.0, iw, 30.0);
    panic.accessibilityIdentifier = @"__panic";
    [panic addTarget:[MMTargets shared] action:@selector(onQuick:)
        forControlEvents:UIControlEventTouchUpInside];
    [c addSubview:panic];
    [page addSubview:c];
}

static void mm_cloud_build_profiles(UIView *page)
{
    CGFloat iw = MM_CLOUD_CARD_W - (MM_CLOUD_CARD_INNER * 2.0);

    UIView *a = mm_cloud_card(@"PRESETS", 0.0, MM_CLOUD_CARD_W, MM_CLOUD_BODY_H);
    NSArray *pt = @[ @"MP · MULTIJUGADOR", @"BR · BATTLE ROYALE",
                     @"STREAM · LIMPIO", @"BAJO · RENDIMIENTO" ];
    for (NSUInteger i = 0; i < pt.count; i++) {
        UIButton *b = mm_cloud_action(pt[i],
            [UIColor colorWithRed:0.07 green:0.20 blue:0.30 alpha:0.96], iw, 32.0);
        b.frame = CGRectMake(MM_CLOUD_CARD_INNER, 38.0 + (CGFloat)i * 40.0, iw, 32.0);
        b.tag = (NSInteger)i;
        [b addTarget:[MMTargets shared] action:@selector(onPreset:)
            forControlEvents:UIControlEventTouchUpInside];
        [a addSubview:b];
    }
    [page addSubview:a];

    UIView *b = mm_cloud_card(@"PERFILES", MM_CLOUD_CARD_W + MM_CLOUD_CARD_GAP,
                              MM_CLOUD_CARD_W, MM_CLOUD_BODY_H);
    g_profile_seg = mm_cloud_seg(@[ @"P1", @"P2", @"P3", @"P4", @"P5" ], iw);
    g_profile_seg.frame = CGRectMake(MM_CLOUD_CARD_INNER, 38.0, iw, 28.0);
    g_profile_seg.selectedSegmentIndex = g_profile_slot;
    [g_profile_seg addTarget:[MMTargets shared] action:@selector(onProfileSlot:)
            forControlEvents:UIControlEventValueChanged];
    [b addSubview:g_profile_seg];

    UIButton *sv = mm_cloud_action(@"Guardar",
        [UIColor colorWithRed:0.08 green:0.38 blue:0.20 alpha:0.96], 78.0, 30.0);
    sv.frame = CGRectMake(MM_CLOUD_CARD_INNER, 72.0, 78.0, 30.0);
    [sv addTarget:[MMTargets shared] action:@selector(onProfileSave)
        forControlEvents:UIControlEventTouchUpInside];
    [b addSubview:sv];
    UIButton *ld = mm_cloud_action(@"Cargar",
        [UIColor colorWithRed:0.08 green:0.24 blue:0.42 alpha:0.96], 78.0, 30.0);
    ld.frame = CGRectMake(MM_CLOUD_CARD_INNER + 86.0, 72.0, 78.0, 30.0);
    [ld addTarget:[MMTargets shared] action:@selector(onProfileLoad)
        forControlEvents:UIControlEventTouchUpInside];
    [b addSubview:ld];

    UIButton *ex = mm_cloud_action(@"Exportar", [UIColor colorWithWhite:0.13 alpha:0.96],
                                   78.0, 30.0);
    ex.frame = CGRectMake(MM_CLOUD_CARD_INNER, 106.0, 78.0, 30.0);
    [ex addTarget:[MMTargets shared] action:@selector(onProfileExport)
        forControlEvents:UIControlEventTouchUpInside];
    [b addSubview:ex];
    UIButton *im = mm_cloud_action(@"Importar", [UIColor colorWithWhite:0.13 alpha:0.96],
                                   78.0, 30.0);
    im.frame = CGRectMake(MM_CLOUD_CARD_INNER + 86.0, 106.0, 78.0, 30.0);
    [im addTarget:[MMTargets shared] action:@selector(onProfileImport)
        forControlEvents:UIControlEventTouchUpInside];
    [b addSubview:im];

    g_profile_name_label = mm_cloud_label(mm_profile_name(g_profile_slot), 9.6,
                                          UIFontWeightSemibold, mm_neon_green());
    g_profile_name_label.textAlignment = NSTextAlignmentCenter;
    g_profile_name_label.frame = CGRectMake(MM_CLOUD_CARD_INNER, 142.0, iw, 16.0);
    [b addSubview:g_profile_name_label];
    UILabel *note = mm_cloud_caption(@"2 dedos en el header cambia de perfil.", iw);
    note.frame = CGRectMake(MM_CLOUD_CARD_INNER, 166.0, iw, 28.0);
    note.numberOfLines = 2;
    note.textColor = [UIColor colorWithWhite:0.48 alpha:1.0];
    [b addSubview:note];
    [page addSubview:b];

    UIView *c = mm_cloud_card(@"ESTILO DEL MENU", (MM_CLOUD_CARD_W + MM_CLOUD_CARD_GAP) * 2.0,
                              MM_CLOUD_CARD_W, MM_CLOUD_BODY_H);
    int ti = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"mm_theme_accent"];
    if (ti < 0 || ti > 4) ti = 0;
    UISegmentedControl *tac = mm_cloud_seg(@[ @"FUSION", mm_tr(@"Hielo"),
                                               mm_tr(@"Magenta"), mm_tr(@"Fuego"),
                                               mm_tr(@"Aqua") ], iw);
    tac.frame = CGRectMake(MM_CLOUD_CARD_INNER, 38.0, iw, 26.0);
    tac.selectedSegmentIndex = ti;
    [tac addTarget:[MMTargets shared] action:@selector(onThemeAccent:)
        forControlEvents:UIControlEventValueChanged];
    [c addSubview:tac];

    UIButton *a1 = mm_cloud_action(@"Acento 1", [UIColor colorWithWhite:0.13 alpha:0.96],
                                   78.0, 28.0);
    a1.frame = CGRectMake(MM_CLOUD_CARD_INNER, 70.0, 78.0, 28.0);
    a1.tag = 0;
    [a1 addTarget:[MMTargets shared] action:@selector(onAccentPick:)
        forControlEvents:UIControlEventTouchUpInside];
    [c addSubview:a1];
    UIButton *a2 = mm_cloud_action(@"Acento 2", [UIColor colorWithWhite:0.13 alpha:0.96],
                                   78.0, 28.0);
    a2.frame = CGRectMake(MM_CLOUD_CARD_INNER + 86.0, 70.0, 78.0, 28.0);
    a2.tag = 1;
    [a2 addTarget:[MMTargets shared] action:@selector(onAccentPick:)
        forControlEvents:UIControlEventTouchUpInside];
    [c addSubview:a2];

    UISegmentedControl *ths = mm_cloud_seg(@[ @"T1", @"T2", @"T3" ], iw);
    ths.frame = CGRectMake(MM_CLOUD_CARD_INNER, 104.0, iw, 24.0);
    ths.selectedSegmentIndex = g_theme_slot;
    [ths addTarget:[MMTargets shared] action:@selector(onThemeSlot:)
        forControlEvents:UIControlEventValueChanged];
    [c addSubview:ths];
    UIButton *tsv = mm_cloud_action(@"Guardar",
        [UIColor colorWithRed:0.08 green:0.38 blue:0.20 alpha:0.96], 78.0, 26.0);
    tsv.frame = CGRectMake(MM_CLOUD_CARD_INNER, 132.0, 78.0, 26.0);
    [tsv addTarget:[MMTargets shared] action:@selector(onThemeSave)
        forControlEvents:UIControlEventTouchUpInside];
    [c addSubview:tsv];
    UIButton *tld = mm_cloud_action(@"Cargar",
        [UIColor colorWithRed:0.08 green:0.24 blue:0.42 alpha:0.96], 78.0, 26.0);
    tld.frame = CGRectMake(MM_CLOUD_CARD_INNER + 86.0, 132.0, 78.0, 26.0);
    [tld addTarget:[MMTargets shared] action:@selector(onThemeLoad)
        forControlEvents:UIControlEventTouchUpInside];
    [c addSubview:tld];
    [page addSubview:c];
}

static void mm_cloud_build_info(UIView *page)
{
    CGFloat iw = MM_CLOUD_CARD_W - (MM_CLOUD_CARD_INNER * 2.0);
    UIView *a = mm_cloud_card(@"ESTADO DEL SISTEMA", 0.0, 366.0, MM_CLOUD_BODY_H);
    g_info_scroll = [[UIScrollView alloc] initWithFrame:CGRectMake(14.0, 38.0, 338.0, 164.0)];
    g_info_scroll.showsVerticalScrollIndicator = YES;
    g_info_scroll.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    g_info_scroll.alwaysBounceVertical = YES;
    [a addSubview:g_info_scroll];

    g_info = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 338.0, 240.0)];
    g_info.numberOfLines = 0;
    g_info.clipsToBounds = YES;
    g_info.textColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    g_info.font = [UIFont fontWithName:@"Menlo" size:9.0] ?: [UIFont systemFontOfSize:9.0];
    [g_info_scroll addSubview:g_info];
    g_info_scroll.contentSize = CGSizeMake(338.0, 250.0);
    [page addSubview:a];

    UIView *b = mm_cloud_card(@"SOPORTE Y CUENTA", 380.0, 224.0, MM_CLOUD_BODY_H);
    UIButton *tg = mm_cloud_action(@"Telegram  @l0pez9801",
        [UIColor colorWithRed:0.12 green:0.48 blue:0.82 alpha:0.96], 196.0, 36.0);
    tg.frame = CGRectMake(14.0, 38.0, 196.0, 36.0);
    [tg addTarget:[MMTargets shared] action:@selector(onTelegram)
        forControlEvents:UIControlEventTouchUpInside];
    [b addSubview:tg];

    UIButton *gr = mm_cloud_action(@"Restablecer invitado",
        [UIColor colorWithRed:0.46 green:0.08 blue:0.10 alpha:0.96], 196.0, 30.0);
    gr.frame = CGRectMake(14.0, 80.0, 196.0, 30.0);
    [gr addTarget:[MMTargets shared] action:@selector(onGuestReset)
        forControlEvents:UIControlEventTouchUpInside];
    [b addSubview:gr];

    UILabel *lgl = mm_cloud_caption(@"Idioma (reiniciar)", 196.0);
    lgl.frame = CGRectMake(14.0, 116.0, 196.0, 14.0);
    [b addSubview:lgl];
    UISegmentedControl *lgs = mm_cloud_seg(@[ @"ES", @"EN" ], 196.0);
    lgs.frame = CGRectMake(14.0, 132.0, 196.0, 26.0);
    lgs.selectedSegmentIndex = (mm_lang() == 1) ? 1 : 0;
    [lgs addTarget:[MMTargets shared] action:@selector(onLang:)
        forControlEvents:UIControlEventValueChanged];
    [b addSubview:lgs];

    /* C-3: Aim Key (mantener el boton AIM flotante para que asista). */
    mm_cloud_row(b, @"Aim Key (mantener)", @"mm_x_aim_key", NO, 186.0, NO);

    g_lic_label = [[UILabel alloc] initWithFrame:CGRectMake(14.0, 162.0, 196.0, 22.0)];
    g_lic_label.numberOfLines = 2;
    g_lic_label.textColor = [UIColor colorWithWhite:0.66 alpha:1.0];
    g_lic_label.font = [UIFont fontWithName:@"Menlo" size:7.4] ?:
                       [UIFont systemFontOfSize:7.4];
    g_lic_label.adjustsFontSizeToFitWidth = YES;
    g_lic_label.minimumScaleFactor = 0.70;
    g_lic_label.text = mm_lic_short_status();
    [b addSubview:g_lic_label];

    UIButton *lp = mm_cloud_action(@"Pegar token", [UIColor colorWithWhite:0.13 alpha:0.96],
                                   94.0, 22.0);
    lp.frame = CGRectMake(14.0, 186.0, 94.0, 22.0);
    [lp addTarget:[MMTargets shared] action:@selector(onLicensePaste)
        forControlEvents:UIControlEventTouchUpInside];
    [b addSubview:lp];
    UIButton *lr = mm_cloud_action(@"Revalidar", [UIColor colorWithWhite:0.13 alpha:0.96],
                                   94.0, 22.0);
    lr.frame = CGRectMake(116.0, 186.0, 94.0, 22.0);
    [lr addTarget:[MMTargets shared] action:@selector(onLicenseCheck)
        forControlEvents:UIControlEventTouchUpInside];
    [b addSubview:lr];
    [page addSubview:b];

    (void)iw;
}

/* v0.2.9: barra "Listo" para cerrar el teclado numerico de los campos de ID. */
/*---------------------------------------------------------------------------
 * v0.5.0: EMBLEMA DEL BOTON FLOTANTE (reemplaza la "F" de texto blanca).
 * Glifo dibujado con Core Graphics: anillo neon tenue, "F" de trazo redondeado
 * con glow verde y punto de energia morado. Encima, un arco de acento que gira
 * lento con CABasicAnimation: costo GPU, cero CPU por frame.
 *--------------------------------------------------------------------------*/
@interface MMBtnGlyph : UIView
@property (nonatomic, strong) CAShapeLayer *arc;    /* estela ancha (glow)  */
@property (nonatomic, strong) CAShapeLayer *core;   /* rayo blanco interior */
@end

@implementation MMBtnGlyph
/* 2026-11: camino HEXAGONAL (antes era un circulo). El rayo recorre los seis
   lados del emblema, no una orbita redonda. */
static CGPathRef mm_glyph_hex_path(CGFloat w, CGFloat h)
{
    CGMutablePathRef p = CGPathCreateMutable();
    CGFloat cx = w / 2.0, cy = h / 2.0;
    CGFloat R = MIN(w, h) / 2.0 - 3.2;
    CGPoint pt[6];
    for (int i = 0; i < 6; i++) {
        CGFloat a = (CGFloat)(M_PI / 3.0 * i) - (CGFloat)(M_PI / 6.0);
        pt[i] = CGPointMake(cx + (CGFloat)cos(a) * R, cy + (CGFloat)sin(a) * R);
    }
    CGPathMoveToPoint(p, NULL, pt[0].x, pt[0].y);
    for (int i = 1; i < 6; i++) CGPathAddLineToPoint(p, NULL, pt[i].x, pt[i].y);
    CGPathCloseSubpath(p);
    return p;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil) {
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        self.userInteractionEnabled = NO;
        CGPathRef hp = mm_glyph_hex_path(frame.size.width, frame.size.height);

        /* estela: trazo ancho violeta con glow, corto, para que se lea como
           energia corriendo por el borde y no como una linea pintada. */
        _arc = [CAShapeLayer layer];
        _arc.frame = self.bounds;
        _arc.path = hp;
        _arc.fillColor = [UIColor clearColor].CGColor;
        _arc.strokeColor = [mm_neon_purple() colorWithAlphaComponent:0.55].CGColor;
        _arc.lineWidth = 4.6;
        _arc.lineCap = kCALineCapRound;
        _arc.lineJoin = kCALineJoinRound;
        _arc.shadowColor = mm_neon_purple().CGColor;
        _arc.shadowRadius = 5.0;
        _arc.shadowOpacity = 0.85f;
        _arc.shadowOffset = CGSizeZero;
        _arc.strokeStart = 0.0;
        _arc.strokeEnd = 0.18;
        [self.layer addSublayer:_arc];

        /* rayo: nucleo casi blanco, mas fino y mas corto, dentro de la estela. */
        _core = [CAShapeLayer layer];
        _core.frame = self.bounds;
        _core.path = hp;
        _core.fillColor = [UIColor clearColor].CGColor;
        _core.strokeColor = [UIColor colorWithRed:0.86 green:1.0 blue:0.98 alpha:1.0].CGColor;
        _core.lineWidth = 1.7;
        _core.lineCap = kCALineCapRound;
        _core.lineJoin = kCALineJoinRound;
        _core.shadowColor = [UIColor colorWithRed:0.55 green:1.0 blue:0.95 alpha:1.0].CGColor;
        _core.shadowRadius = 3.0;
        _core.shadowOpacity = 0.95f;
        _core.shadowOffset = CGSizeZero;
        _core.strokeStart = 0.0;
        _core.strokeEnd = 0.10;
        [self.layer addSublayer:_core];

        CGPathRelease(hp);
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (ctx == NULL) return;
    CGFloat cx = rect.size.width / 2.0, cy = rect.size.height / 2.0;
    CGFloat R = MIN(rect.size.width, rect.size.height) / 2.0;

    /* 1) marco hexagonal con gradiente verde -> violeta (fusion). */
    CGPoint hex[6];
    for (int i = 0; i < 6; i++) {
        CGFloat a = (CGFloat)(M_PI / 3.0 * i) - (CGFloat)(M_PI / 6.0);
        hex[i] = CGPointMake(cx + (CGFloat)cos(a) * (R - 3.2),
                             cy + (CGFloat)sin(a) * (R - 3.2));
    }
    CGMutablePathRef hp = CGPathCreateMutable();
    CGPathMoveToPoint(hp, NULL, hex[0].x, hex[0].y);
    for (int i = 1; i < 6; i++) CGPathAddLineToPoint(hp, NULL, hex[i].x, hex[i].y);
    CGPathCloseSubpath(hp);

    CGContextSaveGState(ctx);
    CGContextAddPath(ctx, hp);
    CGContextSetLineWidth(ctx, 1.7);
    CGContextReplacePathWithStrokedPath(ctx);
    CGContextClip(ctx);
    CGColorSpaceRef sp = CGColorSpaceCreateDeviceRGB();
    CGFloat cols[8] = { 0.30, 1.00, 0.62, 1.0, 0.72, 0.42, 1.00, 1.0 };
    CGFloat locs[2] = { 0.0, 1.0 };
    CGGradientRef gr = CGGradientCreateWithColorComponents(sp, cols, locs, 2);
    CGContextDrawLinearGradient(ctx, gr, CGPointMake(cx - R, cy - R),
                                CGPointMake(cx + R, cy + R), 0);
    CGGradientRelease(gr);
    CGColorSpaceRelease(sp);
    CGContextRestoreGState(ctx);
    CGPathRelease(hp);

    /* 2) "F" biselada. */
    CGMutablePathRef fp = CGPathCreateMutable();
    CGPathMoveToPoint(fp, NULL, cx - 5.2, cy + 9.0);
    CGPathAddLineToPoint(fp, NULL, cx - 5.2, cy - 9.0);
    CGPathAddLineToPoint(fp, NULL, cx + 7.6, cy - 9.0);
    CGPathMoveToPoint(fp, NULL, cx - 5.2, cy - 1.2);
    CGPathAddLineToPoint(fp, NULL, cx + 4.2, cy - 1.2);

    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextSetLineJoin(ctx, kCGLineJoinRound);

    /* 2a) cuerpo verde con glow. */
    CGContextSetShadowWithColor(ctx, CGSizeZero, 8.0,
        [mm_neon_green() colorWithAlphaComponent:0.85].CGColor);
    CGContextSetRGBStrokeColor(ctx, 0.18, 1.00, 0.62, 0.96);
    CGContextSetLineWidth(ctx, 4.8);
    CGContextAddPath(ctx, fp);
    CGContextStrokePath(ctx);

    /* 2b) fantasma violeta desplazado (efecto de fusion cromatica). */
    CGContextSetShadowWithColor(ctx, CGSizeZero, 0.0, NULL);
    CGContextSetRGBStrokeColor(ctx, 0.68, 0.36, 1.00, 0.60);
    CGContextSetLineWidth(ctx, 1.7);
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, 1.0, -1.0);
    CGContextAddPath(ctx, fp);
    CGContextStrokePath(ctx);
    CGContextRestoreGState(ctx);

    /* 2c) nucleo blanco. */
    CGContextSetRGBStrokeColor(ctx, 1.0, 1.0, 1.0, 0.95);
    CGContextSetLineWidth(ctx, 1.2);
    CGContextAddPath(ctx, fp);
    CGContextStrokePath(ctx);
    CGPathRelease(fp);
}
@end

/* 2026-11: el rayo recorre el HEXAGONO (strokeStart/End sobre el path), no gira
   en circulo. Estela y nucleo viajan con un desfase para que parezca descarga. */
static void mm_btn_spin(MMBtnGlyph *g)
{
    if (g == nil || g.arc == nil) return;
    if ([g.arc animationForKey:@"mm_travel"] != nil) return;
    CAMediaTimingFunction *lin = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];

    CABasicAnimation *s1 = [CABasicAnimation animationWithKeyPath:@"strokeStart"];
    s1.fromValue = @0.0; s1.toValue = @1.0; s1.duration = 2.6;
    s1.repeatCount = HUGE_VALF; s1.timingFunction = lin;
    [g.arc addAnimation:s1 forKey:@"mm_travel"];

    CABasicAnimation *e1 = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    e1.fromValue = @0.18; e1.toValue = @1.0; e1.duration = 2.6;
    e1.repeatCount = HUGE_VALF; e1.timingFunction = lin;
    [g.arc addAnimation:e1 forKey:@"mm_travelEnd"];

    if (g.core != nil) {
        CABasicAnimation *s2 = [CABasicAnimation animationWithKeyPath:@"strokeStart"];
        s2.fromValue = @0.0; s2.toValue = @1.0; s2.duration = 2.6;
        s2.repeatCount = HUGE_VALF; s2.timingFunction = lin;
        [g.core addAnimation:s2 forKey:@"mm_travel"];
        CABasicAnimation *e2 = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        e2.fromValue = @0.10; e2.toValue = @1.0; e2.duration = 2.6;
        e2.repeatCount = HUGE_VALF; e2.timingFunction = lin;
        [g.core addAnimation:e2 forKey:@"mm_travelEnd"];
        /* parpadeo electrico del nucleo */
        CAKeyframeAnimation *fl = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
        fl.values = @[ @0.55, @1.0, @0.75, @1.0, @0.6 ];
        fl.duration = 0.9;
        fl.repeatCount = HUGE_VALF;
        [g.core addAnimation:fl forKey:@"mm_flicker"];
    }
}

/* v0.6.1: pinta el boton Debug segun el estado real de la clave. */
static void mm_refresh_debug_button(void)
{
    if (g_dbgbtn == nil) return;
    BOOL on = mm_def_bool(@"mm_debug", NO);
    [g_dbgbtn setTitle:mm_tr(on ? @"Debug (status file): ON  -  tocar = escribir TXT"
                                  : @"Debug (status file): OFF  -  tocar = activar")
              forState:UIControlStateNormal];
    g_dbgbtn.backgroundColor = on
        ? [UIColor colorWithRed:0.08 green:0.42 blue:0.20 alpha:0.95]
        : [UIColor colorWithRed:0.08 green:0.20 blue:0.34 alpha:0.95];
}

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
        /* v0.5.0: emblema dibujado (anillo + F neon + arco giratorio) en vez
           de la "F" de texto. Ver MMBtnGlyph arriba. */
        g_btn.accessibilityLabel = @"FUSION";
        g_btn_glyph = [[MMBtnGlyph alloc] initWithFrame:g_btn.bounds];
        [g_btn addSubview:g_btn_glyph];
        mm_btn_spin(g_btn_glyph);
        /* v0.7.0 (1.10): un toque abre el panel; doble toque prende/apaga el
           maestro. El single espera al double (0.35 s) para no abrir el panel
           en medio de un doble toque. */
        UITapGestureRecognizer *bt2 = [[UITapGestureRecognizer alloc]
            initWithTarget:[MMTargets shared] action:@selector(onButtonDoubleTap:)];
        bt2.numberOfTapsRequired = 2;
        [g_btn addGestureRecognizer:bt2];
        UITapGestureRecognizer *bt1 = [[UITapGestureRecognizer alloc]
            initWithTarget:[MMTargets shared] action:@selector(onTap)];
        bt1.numberOfTapsRequired = 1;
        [bt1 requireGestureRecognizerToFail:bt2];
        [g_btn addGestureRecognizer:bt1];
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
           verde + glow suave fijo.
           v0.5.0: el glifo interno es un emblema dibujado (anillo neon + "F"
           de trazo redondeado con glow + arco de acento giratorio). */
    }

    /* --- contador JUG/BOT (v0.3.2: glass flotante arriba) --- */
    if (g_count_glass == nil) mm_build_count_glass();

    /* --- lienzo del ESP + latido de dibujo (~30 fps) --- */
    if (g_esp == nil) {
        g_esp = [[MMCanvasView alloc] initWithFrame:CGRectZero];
        g_esp.backgroundColor = [UIColor clearColor];
        g_esp.opaque = NO;   /* v0.2.7: sin fondo opaco (evita restos/parpadeo) */
        @try { [g_esp.layer setValue:@((1<<1)|(1<<4)) forKey:@"disableUpdateMask"]; } @catch (NSException *e) {}
        /* v0.7.0: el hitTest del lienzo solo acepta el rect de la lista. */
        g_esp.userInteractionEnabled = YES;
        UITapGestureRecognizer *tlt = [[UITapGestureRecognizer alloc]
            initWithTarget:[MMTargets shared] action:@selector(onTargetListTap:)];
        [g_esp addGestureRecognizer:tlt];
        g_esp.hidden = YES;
    }
    if (g_link == nil) {
        g_link = [CADisplayLink displayLinkWithTarget:[MMTargets shared]
                                             selector:@selector(onFrame:)];
        /* v0.6.2: tope 60 fps. A 120 el lienzo costaba el doble de CPU por el
           mismo resultado visual (cajas y texto). 60 es fluido y deja aire al
           juego. Fallback 60 en equipos sin la API. */
        if (@available(iOS 15.0, *))
            g_link.preferredFrameRateRange = CAFrameRateRangeMake(30.0, 60.0, 60.0);
        else
            g_link.preferredFramesPerSecond = 60;
        [g_link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }

    if (g_panel != nil) return;

    /* --- panel horizontal CLOUD (v0.8.0) ------------------------------- */
    g_panel = [[UIView alloc] initWithFrame:CGRectMake(0, 0, MM_PANEL_W, MM_PANEL_H)];
    g_panel.backgroundColor =
        [UIColor colorWithRed:0.012 green:0.018 blue:0.030 alpha:0.985];
    g_panel.layer.cornerRadius = 22.0;
    g_panel.layer.borderWidth = 1.0;
    g_panel.layer.borderColor =
        [mm_neon_green() colorWithAlphaComponent:0.34].CGColor;
    g_panel.layer.shadowColor =
        [mm_neon_green() colorWithAlphaComponent:0.55].CGColor;
    g_panel.layer.shadowOpacity = 0.35;
    g_panel.layer.shadowRadius = 28.0;
    g_panel.layer.shadowOffset = CGSizeMake(0.0, 10.0);
    g_panel.clipsToBounds = NO;
    g_panel.hidden = YES;
    g_panel.alpha = 0.0;

    /* Fondo: gradiente frio y estable. Sin blur de pantalla completa: el panel
       se abre sobre gameplay y el material dinamico costaba GPU por frame. */
    g_panel_neon = [CAGradientLayer layer];
    g_panel_neon.frame = g_panel.bounds;
    g_panel_neon.cornerRadius = 22.0;
    g_panel_neon.masksToBounds = YES;
    g_panel_neon.startPoint = CGPointMake(0.0, 0.0);
    g_panel_neon.endPoint = CGPointMake(1.0, 1.0);
    g_panel_neon.locations = @[@0.0, @0.52, @1.0];
    CGColorRef p1 = [mm_neon_green() colorWithAlphaComponent:0.10].CGColor;
    CGColorRef p2 = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0].CGColor;
    CGColorRef p3 = [mm_neon_purple() colorWithAlphaComponent:0.09].CGColor;
    g_panel_neon.colors = @[(__bridge id)p1, (__bridge id)p2, (__bridge id)p3];
    [g_panel.layer insertSublayer:g_panel_neon atIndex:0];

    g_panel_shade = [[UIView alloc] initWithFrame:g_panel.bounds];
    g_panel_shade.backgroundColor = [UIColor clearColor];
    g_panel_shade.userInteractionEnabled = NO;
    g_panel_shade.layer.cornerRadius = 22.0;
    g_panel_shade.layer.borderWidth = 0.6;
    g_panel_shade.layer.borderColor =
        [UIColor colorWithWhite:1.0 alpha:0.055].CGColor;
    [g_panel addSubview:g_panel_shade];
    mm_layout_panel_glass();

    /* Zona de arrastre: solo el header. Los controles se agregan despues y
       reciben el toque antes que este pan. */
    UIView *dz = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, MM_PANEL_W - 54.0, 64.0)];
    dz.backgroundColor = [UIColor clearColor];
    dz.userInteractionEnabled = YES;
    UIPanGestureRecognizer *dpan = [[UIPanGestureRecognizer alloc]
        initWithTarget:[MMTargets shared] action:@selector(onPanelPan:)];
    [dz addGestureRecognizer:dpan];
    UITapGestureRecognizer *dtap = [[UITapGestureRecognizer alloc]
        initWithTarget:[MMTargets shared] action:@selector(onHeaderDoubleTap:)];
    dtap.numberOfTapsRequired = 2;
    [dz addGestureRecognizer:dtap];
    [dtap requireGestureRecognizerToFail:dpan];
    UISwipeGestureRecognizer *psl = [[UISwipeGestureRecognizer alloc]
        initWithTarget:[MMTargets shared] action:@selector(onProfileSwipe:)];
    psl.direction = UISwipeGestureRecognizerDirectionLeft;
    psl.numberOfTouchesRequired = 2;
    [dz addGestureRecognizer:psl];
    UISwipeGestureRecognizer *psr = [[UISwipeGestureRecognizer alloc]
        initWithTarget:[MMTargets shared] action:@selector(onProfileSwipe:)];
    psr.direction = UISwipeGestureRecognizerDirectionRight;
    psr.numberOfTouchesRequired = 2;
    [dz addGestureRecognizer:psr];
    [g_panel addSubview:dz];

    /* Marca compacta: cuadro con gradiente de acento. */
    UIView *mark = [[UIView alloc] initWithFrame:CGRectMake(18.0, 15.0, 36.0, 36.0)];
    mark.layer.cornerRadius = 11.0;
    mark.clipsToBounds = YES;
    CAGradientLayer *mg = [CAGradientLayer layer];
    mg.frame = mark.bounds;
    mg.startPoint = CGPointMake(0.0, 0.0);
    mg.endPoint = CGPointMake(1.0, 1.0);
    mg.colors = @[(__bridge id)[mm_neon_green() colorWithAlphaComponent:0.95].CGColor,
                  (__bridge id)[mm_neon_purple() colorWithAlphaComponent:0.90].CGColor];
    [mark.layer addSublayer:mg];
    UILabel *fl = mm_cloud_label(@"F", 19.0, UIFontWeightHeavy, [UIColor whiteColor]);
    fl.textAlignment = NSTextAlignmentCenter;
    fl.frame = mark.bounds;
    [mark addSubview:fl];
    [g_panel addSubview:mark];

    UILabel *h = mm_cloud_label(@"FUSION", 19.0, UIFontWeightHeavy, [UIColor whiteColor]);
    h.frame = CGRectMake(64.0, 9.0, 210.0, 24.0);
    [g_panel addSubview:h];
    UILabel *sub = mm_cloud_label(@"PRO MOD MENU  ·  iOS",
                                  8.0, UIFontWeightSemibold,
                                  [UIColor colorWithWhite:0.52 alpha:1.0]);
    sub.frame = CGRectMake(65.0, 34.0, 148.0, 13.0);
    /* C-24: chip de version a la derecha del subtitulo. */
    {
        UILabel *ver = mm_cloud_label([NSString stringWithFormat:@"v%s", MODMENU_VERSION],
                                      8.0, UIFontWeightBold, mm_neon_green());
        ver.textAlignment = NSTextAlignmentCenter;
        ver.backgroundColor = [mm_neon_green() colorWithAlphaComponent:0.12];
        ver.layer.cornerRadius = 6.0;
        ver.layer.masksToBounds = YES;
        ver.layer.borderWidth = 0.6;
        ver.layer.borderColor = [mm_neon_green() colorWithAlphaComponent:0.35].CGColor;
        ver.frame = CGRectMake(216.0, 33.0, 56.0, 14.0);
        [g_panel addSubview:ver];
    }
    [g_panel addSubview:sub];

    g_status_strip = [[UILabel alloc] initWithFrame:CGRectMake(286.0, 18.0, 246.0, 28.0)];
    g_status_strip.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.04];
    g_status_strip.layer.cornerRadius = 9.0;
    g_status_strip.layer.masksToBounds = YES;
    g_status_strip.layer.borderWidth = 0.6;
    g_status_strip.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.07].CGColor;
    g_status_strip.textColor = [UIColor colorWithWhite:0.80 alpha:1.0];
    g_status_strip.font = [UIFont fontWithName:@"Menlo-Bold" size:8.2] ?:
                          [UIFont boldSystemFontOfSize:8.2];
    g_status_strip.textAlignment = NSTextAlignmentCenter;
    g_status_strip.adjustsFontSizeToFitWidth = YES;
    g_status_strip.minimumScaleFactor = 0.70;
    g_status_strip.text = @"● AIM   ● ESP   ● NOJB   TGT --";
    [g_panel addSubview:g_status_strip];

    UIButton *x = [UIButton buttonWithType:UIButtonTypeCustom];
    x.frame = CGRectMake(MM_PANEL_W - 48.0, 17.0, 30.0, 30.0);
    x.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.05];
    x.layer.cornerRadius = 9.0;
    x.layer.borderWidth = 0.7;
    x.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.09].CGColor;
    x.accessibilityLabel = @"Cerrar";
    UIImage *ximg = nil;
    if (@available(iOS 13.0, *)) ximg = [UIImage systemImageNamed:@"xmark"];
    if (ximg != nil) {
        [x setImage:[ximg imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
            forState:UIControlStateNormal];
        x.tintColor = [UIColor colorWithWhite:0.78 alpha:1.0];
    } else {
        [x setTitle:@"X" forState:UIControlStateNormal];
        [x setTitleColor:[UIColor colorWithWhite:0.78 alpha:1.0]
                forState:UIControlStateNormal];
        x.titleLabel.font = mm_cloud_font(12.0, UIFontWeightBold);
    }
    [x addTarget:[MMTargets shared] action:@selector(onClose)
        forControlEvents:UIControlEventTouchUpInside];
    [g_panel addSubview:x];

    UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(18.0, 64.0, MM_PANEL_W - 36.0, 0.5)];
    sep.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.06];
    sep.userInteractionEnabled = NO;
    [g_panel addSubview:sep];

    /* Navegacion horizontal real. g_seg queda oculto solo como estado para
       conservar el swipe y los metodos que ya existian. */
    NSArray *navTitles = @[ @"ESP", @"AIM", @"VISUAL", @"RADAR", @"CONFIG" ];
    CGFloat navW = (MM_PANEL_W - 36.0 - 8.0 * ((CGFloat)navTitles.count - 1.0)) / (CGFloat)navTitles.count;
    g_nav_btns = [NSMutableArray array];
    for (NSUInteger i = 0; i < navTitles.count; i++) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
        b.frame = CGRectMake(18.0 + (CGFloat)i * (navW + 8.0), MM_CLOUD_NAV_Y,
                             navW, 38.0);
        b.tag = (NSInteger)i;
        b.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.035];
        b.layer.cornerRadius = 11.0;
        b.layer.borderWidth = 0.7;
        b.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.07].CGColor;
        /* C-13: barra de acento inferior del tab activo. */
        UIView *nb = [[UIView alloc] initWithFrame:CGRectMake(10.0, 34.5,
                                                              navW - 20.0, 2.0)];
        nb.tag = 99;
        nb.backgroundColor = mm_neon_green();
        nb.layer.cornerRadius = 1.0;
        nb.hidden = (i != 0);
        [b addSubview:nb];
        b.titleLabel.font = mm_cloud_font(9.8, UIFontWeightSemibold);
        b.titleLabel.adjustsFontSizeToFitWidth = YES;
        b.titleLabel.minimumScaleFactor = 0.72;
        [b setTitle:[[mm_tr(navTitles[i]) uppercaseString]
                        stringByReplacingOccurrencesOfString:@"\n" withString:@" "]
            forState:UIControlStateNormal];
        [b addTarget:[MMTargets shared] action:@selector(onNav:)
            forControlEvents:UIControlEventTouchUpInside];
        [g_panel addSubview:b];
        [g_nav_btns addObject:b];
    }

    g_seg = [[UISegmentedControl alloc] initWithItems:navTitles];
    g_seg.frame = CGRectZero;
    g_seg.hidden = YES;
    g_seg.selectedSegmentIndex = 0;
    [g_panel addSubview:g_seg];

    /* Paginas: area ancha de tres columnas, 604 x 214. */
    CGRect body = CGRectMake(18.0, MM_CLOUD_BODY_Y, MM_PANEL_W - 36.0, MM_CLOUD_BODY_H);
    g_p_esp  = [[UIView alloc] initWithFrame:body];
    g_p_aim  = [[UIView alloc] initWithFrame:body];
    g_p_vis  = [[UIView alloc] initWithFrame:body];
    g_p_misc = [[UIView alloc] initWithFrame:body];
    g_p_info = [[UIView alloc] initWithFrame:body];
    g_p_aim.hidden = YES;
    g_p_vis.hidden = YES;
    g_p_misc.hidden = YES;
    g_p_info.hidden = YES;
    [g_panel addSubview:g_p_esp];
    [g_panel addSubview:g_p_aim];
    [g_panel addSubview:g_p_vis];
    [g_panel addSubview:g_p_misc];
    [g_panel addSubview:g_p_info];

    g_sub_switches = [NSMutableArray array];
    mm_cloud_build_combat(g_p_esp);
    mm_cloud_build_aim(g_p_aim);
    mm_cloud_build_visual(g_p_vis);
    mm_cloud_build_radar(g_p_misc);
    mm_cloud_build_info(g_p_info);

    UILabel *foot = mm_cloud_label(@"FUSION  ·  STEALTH  ·  AIM",
                                   7.4, UIFontWeightSemibold,
                                   [UIColor colorWithWhite:0.34 alpha:1.0]);
    foot.frame = CGRectMake(18.0, 342.0, 300.0, 10.0);
    [g_panel addSubview:foot];
    UILabel *footR = mm_cloud_label(@"DRAG HEADER  ·  2-FINGER PROFILE",
                                    7.4, UIFontWeightSemibold,
                                    [UIColor colorWithWhite:0.30 alpha:1.0]);
    footR.textAlignment = NSTextAlignmentRight;
    footR.frame = CGRectMake(MM_PANEL_W - 320.0, 342.0, 302.0, 10.0);
    [g_panel addSubview:footR];

    mm_apply_esp_lock();
    mm_apply_safe_mode();
    [[MMTargets shared] onSeg:g_seg];

}

/*---------------------------------------------------------------------------
 * Colocacion y estado de la UI
 *--------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
 * v0.6.4: barra rapida flotante, modo seguro y auto-test.
 *--------------------------------------------------------------------------*/
static void mm_layout_quickbar(void)
{
    if (g_quickbar == nil || g_btn == nil) return;
    UIView *root = g_quickbar.superview;
    CGFloat w = g_quickbar.bounds.size.width, h = g_quickbar.bounds.size.height;
    CGPoint c = g_btn.center;
    CGFloat x = c.x - w / 2.0, y = c.y + 30.0;
    if (root != nil) {
        x = MAX(4.0, MIN(root.bounds.size.width - w - 4.0, x));
        if (y + h > root.bounds.size.height - 8.0) y = c.y - h - 30.0;
        y = MAX(4.0, MIN(root.bounds.size.height - h - 4.0, y));
    }
    g_quickbar.frame = CGRectMake(x, y, w, h);
}

static void mm_refresh_quickbar(void)
{
    if (g_quickbar == nil) return;
    BOOL hide = !mm_def_bool(@"mm_quickbar", NO) || g_panel_open || g_panic ||
                mm_stream_effective() || mm_def_bool(@"mm_safe_mode", NO);
    g_quickbar.hidden = hide;
    if (hide) return;
    mm_layout_quickbar();
    for (UIButton *b in g_quick_btns) {
        BOOL v = [b.accessibilityIdentifier isEqualToString:@"__panic"]
            ? g_panic : mm_def_bool(b.accessibilityIdentifier, NO);
        b.backgroundColor = v
            ? [UIColor colorWithRed:0.10 green:0.46 blue:0.24 alpha:0.95]
            : [UIColor colorWithRed:0.04 green:0.09 blue:0.07 alpha:0.90];
        b.layer.borderColor =
            (v ? mm_neon_green() : [UIColor colorWithWhite:0.55 alpha:0.45]).CGColor;
        [b setTitleColor:(v ? [UIColor whiteColor]
                           : [UIColor colorWithWhite:0.72 alpha:1.0])
                forState:UIControlStateNormal];
    }
}

static void mm_build_quickbar(void)
{
    if (g_quickbar != nil) return;
    g_quick_keys = @[@"mm_esp_master", @"mm_esp_box", @"mm_esp_name",
                     @"mm_x_radar", @"__panic"];
    NSArray *titles = @[@"MASTER", @"CAJAS", @"NOMBRES", @"RADAR", @"PANIC"];
    g_quick_btns = [NSMutableArray array];
    g_quickbar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 286, 30)];
    g_quickbar.backgroundColor = [UIColor clearColor];
    g_quickbar.hidden = YES;
    CGFloat x = 0.0;
    for (NSUInteger i = 0; i < g_quick_keys.count; i++) {
        CGFloat w = (i == 0) ? 58.0 : ((i == 2) ? 62.0 : 52.0);
        UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
        b.frame = CGRectMake(x, 0, w, 30);
        b.layer.cornerRadius = 9.0;
        b.layer.borderWidth = 0.8;
        b.titleLabel.font = [UIFont boldSystemFontOfSize:9.5];
        b.accessibilityIdentifier = g_quick_keys[i];
        [b setTitle:mm_tr(titles[i]) forState:UIControlStateNormal];
        [b addTarget:[MMTargets shared] action:@selector(onQuick:)
            forControlEvents:UIControlEventTouchUpInside];
        [g_quickbar addSubview:b];
        [g_quick_btns addObject:b];
        x += w + 2.0;
    }
    g_quickbar.bounds = CGRectMake(0, 0, x - 2.0, 30);
}

/* Modo seguro: apaga y bloquea el overlay (el lienzo ni se pinta) hasta que se
   destilde. El boton y el panel siguen vivos para poder salir. */
static void mm_apply_safe_mode(void)
{
    BOOL on = mm_def_bool(@"mm_safe_mode", NO);
    if (on) {
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        NSArray *keys = @[ @"mm_esp_master", @"mm_esp_count", @"mm_x_cross", @"mm_x_aimring",
                           @"mm_x_fps", @"mm_x_head", @"mm_x_distcol", @"mm_x_lowhp",
                           @"mm_x_priority", @"mm_x_warn", @"mm_x_arrow",
                           @"mm_x_radar", @"mm_x_height", @"mm_x_telem",
                           @"mm_x_bearings", @"mm_x_trails", @"mm_x_declutter",
                           @"mm_x_targetlist" ];
        for (NSString *k in keys) [ud setBool:NO forKey:k];
        [ud synchronize];
        mm_opts_invalidate();
        g_box_count = 0;
        g_track_count = 0;
        if (g_esp != nil) {
            g_esp.hidden = YES;
            [g_esp setNeedsDisplay];
        }
    }
    for (UISwitch *s in g_sub_switches) {
        if (on) s.on = NO;
        s.enabled = !on;
        s.superview.alpha = on ? 0.35
            : (mm_def_bool(@"mm_esp_master", NO) ? 1.0 : 0.5);
    }
    mm_sync_switches(g_panel);
    mm_refresh_count_glass();
    mm_refresh_quickbar();
}

/* v0.7.1: kill-switch compartido por long-press y chip PANIC. */
static void mm_toggle_panic(void)
{
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
    mm_refresh_quickbar();
    mm_write_status(g_panic ? @"panic ON" : @"panic OFF");
}

/* Auto-test de solo lectura: version, imagen, contrato, ventana, boton y
   lienzo. No llama funciones del juego. Escribe Documents/self_test.txt. */
static void mm_self_test(void)
{
    NSMutableString *r = [NSMutableString string];
    int ok = 0, bad = 0;
    NSString *gv = NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"] ?: @"?";

#define MM_CK(label, cond, detail) do { \
    BOOL _c = (cond); \
    [r appendFormat:@"%@  %-12s %@\n", _c ? @"OK   " : @"FALLA", label, (detail)]; \
    if (_c) ok++; else bad++; } while (0)

    MM_CK("version", [gv isEqualToString:@FUSION_OFFSETS_VERSION],
          ([NSString stringWithFormat:@"juego %@ / offsets %s", gv, FUSION_OFFSETS_VERSION]));

    const struct mach_header *hdr = _dyld_get_image_header(0);
    uint32_t magic = 0;
    BOOL img = (hdr != NULL) && mm_vm_read((uintptr_t)hdr, &magic, sizeof(magic));
    MM_CK("imagen", img && (magic == 0xFEEDFACF || magic == 0xFEEDFACE),
          (img ? [NSString stringWithFormat:@"base=0x%lX", (unsigned long)(uintptr_t)hdr]
               : @"cabecera ilegible"));

    BOOL offs = (VA_GAMEPLAY != 0 && VA_LOCALPAWN != 0 && VA_MAINCAM != 0 &&
                 VA_W2C_INJ != 0 && VA_PROJ_INJ != 0 && VA_TRANSPOS != 0 &&
                 VA_HEALTH != 0);
    MM_CK("offsets", offs, offs ? @"7 funciones del contrato" : @"hay VAs en 0");

    BOOL structs = (OFF_PAWN_TRANSFORM != 0 && OFF_PAWN_ENTITY != 0 &&
                    OFF_LIST_ITEMS != 0 && OFF_ARR_DATA != 0);
    MM_CK("structs", structs, structs ? @"pawn/lista con offset" : @"offset en 0");

    UIWindow *w = mm_host_window();
    MM_CK("ventana", w != nil, w != nil ? @"ventana del juego" : @"sin ventana");

    BOOL btnOk = (g_btn != nil && g_btn.window != nil);
    MM_CK("boton", btnOk, btnOk ? @"enganchado" : @"no enganchado");

    BOOL canvasOk = (g_esp != nil && g_link != nil && !g_link.paused);
    MM_CK("lienzo", canvasOk,
          (canvasOk ? [NSString stringWithFormat:@"link %.0f fps", g_fps] : @"sin display link"));

    if (g_fp_state == 1)
        MM_CK("punteros", YES, @"ESP resolvio las funciones");
    else if (g_fp_state == 0)
        MM_CK("punteros", NO, g_esp_diag ?: @"ESP no pudo resolver");
    else
        [r appendFormat:@"INFO   %-12s %@\n", "punteros", @"sin probar (ESP nunca activado)"];

    if (g_collect_ms > 0.0)
        MM_CK("colecta", g_collect_ms < 12.0,
              ([NSString stringWithFormat:@"%.1f ms  cajas %d", g_collect_ms, g_box_count]));
    else
        [r appendFormat:@"INFO   %-12s %@\n", "colecta", @"sin datos (ESP nunca activado)"];

    [r appendFormat:@"INFO   %-12s %@\n", "br",
        (BR_STRUCT_MGR_VA != 0ULL) ? @"offsets verificados (reader ON)"
                                   : @"sin offsets (reader OFF, inerte)"];
    [r appendFormat:@"INFO   %-12s %s · %s · juego %@\n", "pack",
        FUSION_PACK_VERSION, FUSION_EXPERIMENT_ID, gv];
    [r appendFormat:@"INFO   %-12s valid=%d err=%@ disabled=%d rev=%d\n", "config",
        g_cfg_valid, g_cfg_error ?: @"-", (int)g_cfg_disabled.count, (int)g_cfg_revoked.count];
    [r appendFormat:@"INFO   %-12s %@\n", "marca",
        mm_def_bool(@"mm_build_mark", NO) ? mm_build_mark() : @"off (opt-in)"];
    [r appendFormat:@"INFO   %-12s temp=%d captura=%d boot=%d forzado=%d crumb=%s\n", "salud",
        g_thermal_level, g_captured, g_dirty_boots, g_boot_forced, g_last_action];
    [r appendFormat:@"INFO   %-12s %@\n", "guard",
        (g_secure_canvas_state == 1) ? @"canvas seguro disponible"
            : ((g_secure_canvas_state == 0) ? @"sin canvas (fallback a ventana)" : @"sin probar")];
    [r appendFormat:@"INFO   %-12s pint %.0f/s  lect %.0f/s  mem %.0f MB\n",
        "ritmo", g_paint_fps, g_reads_per_s, g_mem_mb];
#undef MM_CK

    NSString *txt = [NSString stringWithFormat:
        @"build=%s\nversion_juego=%@\nuptime_s=%d\n\n%@\n",
        MODMENU_VERSION, gv, (int)mm_uptime(), r];
    NSString *path = @"(sin Documents)";
    @try {
        NSString *docs = mm_docs_dir();
        if (docs.length > 0) {
            path = [docs stringByAppendingPathComponent:@"self_test.txt"];
            [txt writeToFile:path atomically:YES
                    encoding:NSUTF8StringEncoding error:NULL];
        }
    } @catch (NSException *e) {}

    mm_haptic(bad == 0 ? 1 : 0);
    [UIPasteboard generalPasteboard].string = txt;   /* 1.20: codigo copiable */
    mm_show_alert([NSString stringWithFormat:@"Auto-test: %d OK / %d fallas", ok, bad],
                  [NSString stringWithFormat:@"%@\n%@\n(copiado al portapapeles)", r, path]);
}

static void mm_apply_esp_lock(void)
{
    BOOL on = mm_def_bool(@"mm_esp_master", NO);
    BOOL safe = mm_def_bool(@"mm_safe_mode", NO);
    for (UISwitch *s in g_sub_switches)
        s.superview.alpha = safe ? 0.35 : (on ? 1.0 : 0.5);
    mm_refresh_count_glass();   /* v0.3.2: el maestro tambien manda */
}

/* v0.7.0 - Fase 1.11/1.12/1.13/4.5: estado local de la sesion. */
static void mm_mark_action(const char *a)
{
    if (a == NULL) return;
    strncpy(g_last_action, a, sizeof(g_last_action) - 1);
    g_last_action[sizeof(g_last_action) - 1] = '\0';
}

static BOOL mm_stream_effective(void)
{
    if (mm_def_bool(@"mm_stream", NO)) return YES;
    return (mm_def_bool(@"mm_auto_stream", YES) && g_captured) ? YES : NO;
}

/* 1.12 + 1.13 + 1.11: termico, captura de pantalla y arranque limpio. */
static void mm_write_usage(void)
{
    @try {
        NSString *docs = mm_docs_dir();
        if (docs.length == 0) return;
        NSArray *fkeys = @[ @"mm_esp_master", @"mm_esp_box", @"mm_esp_name",
                            @"mm_esp_dist", @"mm_esp_health", @"mm_x_radar",
                            @"mm_x_bearings", @"mm_x_trails", @"mm_x_targetlist",
                            @"mm_safe_mode", @"mm_stream", @"mm_auto_stream",
                            @"mm_guard_capture", @"mm_color_mode" ];
        NSMutableDictionary *f = [NSMutableDictionary dictionary];
        for (NSString *k in fkeys) f[k] = @(mm_def_bool(k, NO));
        NSDictionary *d = @{ @"build": @MODMENU_VERSION,
                             @"game": @FUSION_OFFSETS_VERSION,
                             @"session_s": @((int)mm_uptime()),
                             @"thermal": @(g_thermal_level),
                             @"captured": @(g_captured),
                             @"features": f };
        NSData *j = [NSJSONSerialization dataWithJSONObject:d options:0 error:nil];
        if (j != nil)
            [j writeToFile:[docs stringByAppendingPathComponent:@"fusion_usage.json"]
                atomically:YES];
    } @catch (NSException *e) {}
}

static void mm_health_update(void)
{
    @try {
        static int s_last_thermal = -1, s_last_stream = -1;
        static double s_last_usage = -100.0;
        NSProcessInfoThermalState ts = NSProcessInfo.processInfo.thermalState;
        g_thermal_level = (int)ts;
        if (g_thermal_level != s_last_thermal) {
            s_last_thermal = g_thermal_level;
            mm_opts_invalidate();
        }
        if (@available(iOS 11.0, *))
            g_captured = UIScreen.mainScreen.isCaptured ? 1 : 0;

        int st = mm_stream_effective() ? 1 : 0;
        if (st != s_last_stream) {
            s_last_stream = st;
            mm_apply_stream();
        }
        /* 4.8: telemetria local opt-in, un volcado por minuto. */
        if (mm_def_bool(@"mm_usage_optin", NO) && (mm_uptime() - s_last_usage) > 60.0) {
            s_last_usage = mm_uptime();
            mm_write_usage();
        }
        /* 1.11: 20 s con la UI viva = arranque limpio. */
        if (g_dirty_boots != 0 && mm_uptime() > 20.0) {
            g_dirty_boots = 0;
            NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
            [ud setInteger:0 forKey:@"mm_dirty_boots"];
            [ud synchronize];
        }
    } @catch (NSException *e) {}
}

/* 1.11: dos arranques sin cierre limpio seguidos -> modo seguro y aviso.
   Se ejecuta en el constructor, antes de que la UI exista. */
static void mm_boot_check(void)
{
    @try {
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        int d = (int)[ud integerForKey:@"mm_dirty_boots"];
        if (d >= 2) {
            g_boot_forced = 1;
            g_dirty_boots = 0;
            [ud setBool:YES forKey:@"mm_safe_mode"];
            [ud setInteger:0 forKey:@"mm_dirty_boots"];
        } else {
            g_dirty_boots = d + 1;
            [ud setInteger:g_dirty_boots forKey:@"mm_dirty_boots"];
        }
        [ud synchronize];
        mm_mark_action("boot");
    } @catch (NSException *e) {}
}

static void mm_apply_stream(void)
{
    BOOL on = mm_stream_effective();
    /* v0.3.0: el boton queda visible al 10% para poder reabrir el panel y
       apagar Stream Mode. 1.14: con Stream automatico pasa a "fantasma"
       (2%) con el mismo hotspot de 54 pt; nunca alpha 0 (perderia toques). */
    if (g_btn != nil) {
        g_btn.alpha = on ? 0.02 : 1.0;
        g_btn.userInteractionEnabled = YES;
    }
    if (g_marca != nil) {
        g_marca.alpha = on ? 0.0 : 1.0;
        g_marca.hidden = on;
    }
    /* v0.3.2: el contador tambien forma parte de la UI que Stream oculta. */
    mm_refresh_count_glass();
    mm_refresh_quickbar();
}

/* v0.8.0: el panel horizontal solo cabe completo en landscape de iPhone
   moderno. La escala total es el menor de (preferencia del operador, factor
   que entra en la ventana). El usuario no puede ampliar por encima de lo que
   la pantalla permite, pero si reducir. */
static CGFloat mm_menu_total_scale(CGRect host)
{
    CGFloat user = mm_def_float(@"mm_menu_scale", 1.0f);
    if (user < 0.8f) user = 0.8f;
    if (user > 1.2f) user = 1.2f;

    CGFloat fitW = (host.size.width  - 20.0) / MM_PANEL_W;
    CGFloat fitH = (host.size.height - 28.0) / MM_PANEL_H;
    CGFloat fit = MIN(fitW, fitH);
    if (fit > 1.2f) fit = 1.2f;
    if (fit < 0.45f) fit = 0.45f;

    CGFloat total = MIN(user, fit);
    if (total < 0.45f) total = 0.45f;
    if (total > 1.2f) total = 1.2f;
    return total;
}

static void mm_position_panel(void)
{
    if (g_panel == nil || g_panel.superview == nil) return;
    /* v0.4.1 FIX del bug de tamano: NUNCA setear .frame con un transform de escala
       activo (UIKit deja el frame indefinido y el panel salta/se deforma). Reset a
       identidad, posicionar en tamano base, y re-aplicar la escala del usuario. */
    g_panel.transform = CGAffineTransformIdentity;

    CGRect rb = g_panel.superview.bounds;
    CGFloat sc = mm_menu_total_scale(rb);
    CGFloat vw = MM_PANEL_W * sc;
    CGFloat vh = MM_PANEL_H * sc;
    CGFloat cx = CGRectGetMidX(rb);
    CGFloat cy = CGRectGetMidY(rb);
    CGFloat px, py;

    /* v0.8.0: sin posicion guardada el panel se centra. El boton flotante vive
       en un borde y anclar ahi un panel de 640 pt lo dejaria fuera de pantalla. */
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"mm_panel_pos"]) {
        cx = mm_def_float(@"mm_panel_x", cx);
        cy = mm_def_float(@"mm_panel_y", cy);
    }
    cx = MAX(6.0 + vw / 2.0, MIN(rb.size.width  - 6.0 - vw / 2.0, cx));
    cy = MAX(24.0 + vh / 2.0, MIN(rb.size.height - 6.0 - vh / 2.0, cy));
    px = cx - MM_PANEL_W / 2.0;
    py = cy - MM_PANEL_H / 2.0;

    g_panel.frame = CGRectMake(px, py, MM_PANEL_W, MM_PANEL_H);
    mm_layout_panel_glass();
    if (sc != 1.0f) g_panel.transform = CGAffineTransformMakeScale(sc, sc);
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
            CGFloat mmSc = mm_menu_total_scale(g_panel.superview.bounds);
            if (mmOp < 0.4f) mmOp = 0.4f; if (mmOp > 1.0f) mmOp = 1.0f;
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
        mm_refresh_quickbar();
        mm_refresh_info();
    } @catch (NSException *e) {
        MM_LOG(@"%s set_panel: %@", MM_TAG, e.reason);
    }
}

/* v0.3.5: INFO limpia. El diagnostico tecnico ya no se muestra aqui:
   sigue en Documents/modmenu_status.txt y en el syslog. */
static void mm_refresh_info(void)
{
    /* v0.8.0: pill de estado del encabezado. Puntos de color en vez de
       corchetes, para que se lea como una barra de sistema y no como consola.
       Cero costo si el panel esta cerrado (label oculto con el panel). */
    if (g_status_strip != nil) {
        int sAim  = 1;  /* aim es parche estatico, siempre activo si la IPA se instalo */
        int sEsp  = (g_fp_state == 1) ? 1 : 0;
        int sNojb = (g_nojb_passes > 0) ? 1 : 0;
        int targets = g_track_count;
        UIFont *sf = [UIFont fontWithName:@"Menlo-Bold" size:8.2] ?:
                     [UIFont boldSystemFontOfSize:8.2];
        UIColor *on  = [UIColor colorWithRed:0.20 green:1.0 blue:0.58 alpha:1.0];
        UIColor *off = [UIColor colorWithRed:1.0 green:0.42 blue:0.42 alpha:1.0];
        NSMutableAttributedString *st = [[NSMutableAttributedString alloc] init];
        NSArray *names = @[ @"AIM", @"ESP", @"NOJB" ];
        BOOL states[3] = { (BOOL)sAim, (BOOL)sEsp, (BOOL)sNojb };
        for (int i = 0; i < 3; i++) {
            [st appendAttributedString:[[NSAttributedString alloc]
                initWithString:names[i]
                    attributes:@{ NSFontAttributeName: sf,
                                  NSForegroundColorAttributeName:
                                      [UIColor colorWithWhite:0.70 alpha:1.0] }]];
            [st appendAttributedString:[[NSAttributedString alloc]
                initWithString:@"  ●    "
                    attributes:@{ NSFontAttributeName: sf,
                                  NSForegroundColorAttributeName:
                                      states[i] ? on : off }]];
        }
        [st appendAttributedString:[[NSAttributedString alloc]
            initWithString:[NSString stringWithFormat:@"TGT %02d", targets]
                attributes:@{ NSFontAttributeName: sf,
                              NSForegroundColorAttributeName:
                                  [UIColor colorWithWhite:0.92 alpha:1.0] }]];
        g_status_strip.attributedText = st;
    }
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
            initWithString:[NSString stringWithFormat:@"v%s\n", MODMENU_VERSION]
                attributes:@{ NSFontAttributeName: verFont,
                              NSForegroundColorAttributeName:
                                  [mm_neon_purple() colorWithAlphaComponent:0.95] }]];
        [t appendAttributedString:[[NSAttributedString alloc]
            initWithString:mm_tr(@"Aimbot configurable desde COMBATE.\n\n")
                attributes:@{ NSFontAttributeName: itemFont,
                              NSForegroundColorAttributeName:
                                  [UIColor colorWithWhite:0.95 alpha:1.0],
                              NSParagraphStyleAttributeName: ps }]];
        /* v0.5.0: nota pedida por el operador — seguridad vs rendimiento. */
        [t appendAttributedString:[[NSAttributedString alloc]
            initWithString:mm_tr(@"Activar todas las opciones no da problemas de seguridad;\nel costo es rendimiento (FPS) en el dispositivo.\n\n")
                attributes:@{ NSFontAttributeName: itemFont,
                              NSForegroundColorAttributeName:
                                  [UIColor colorWithWhite:0.95 alpha:1.0],
                              NSParagraphStyleAttributeName: ps }]];
        [t appendAttributedString:[[NSAttributedString alloc]
            initWithString:mm_tr(@"Proyecto desarrollado por\nJose Lopez - Ing. de Sistemas\n\n")
                attributes:@{ NSFontAttributeName: bodyFont,
                              NSForegroundColorAttributeName:
                                  [UIColor colorWithWhite:0.70 alpha:1.0],
                              NSParagraphStyleAttributeName: ps }]];
        [t appendAttributedString:[[NSAttributedString alloc]
            initWithString:@"Contacto:"
                attributes:@{ NSFontAttributeName: bodyFont,
                              NSForegroundColorAttributeName:
                                  [UIColor colorWithWhite:0.55 alpha:1.0] }]];
        [t appendAttributedString:[[NSAttributedString alloc]
            initWithString:@"  Telegram @l0pez9801"
                attributes:@{ NSFontAttributeName: bodyFont,
                              NSForegroundColorAttributeName:
                                  [mm_neon_green() colorWithAlphaComponent:0.92] }]];
        g_info.attributedText = t;

        /* v0.8.0: INFO vive en una tarjeta scrolleable. El alto se calcula del
           texto real (no se recorta) y el scroll recibe el contentSize exacto. */
        CGSize fit = [g_info sizeThatFits:CGSizeMake(338.0, CGFLOAT_MAX)];
        CGFloat ih = MAX(190.0, fit.height + 12.0);
        g_info.frame = CGRectMake(0.0, 0.0, 338.0, ih);
        if (g_info_scroll != nil)
            g_info_scroll.contentSize = CGSizeMake(338.0, ih + 8.0);
    } @catch (NSException *e) {}
}

/* Coloca (o recoloca) la UI DENTRO de la ventana del juego. Devuelve YES si
   quedo enganchada. Se ejecuta en el main queue, una vez por tick.
   v0.2.1: ya NO creamos ventana propia (rompia la rotacion y los toques). */
/* 1.15: elige el contenedor de la UI. Con el guard OFF es la ventana del
   juego; con el guard ON, el canvas del campo seguro (fallback a la ventana). */
static UIView *mm_ui_container(UIWindow *host)
{
    if (host == nil) return nil;
    BOOL guard = mm_def_bool(@"mm_guard_capture", NO);
    if (g_secure_host != nil) g_secure_host.hidden = !guard;
    if (!guard) return host;

    if (g_secure_host == nil) {
        MMSecureHost *f = [[MMSecureHost alloc] initWithFrame:host.bounds];
        f.secureTextEntry = YES;
        f.textColor = [UIColor clearColor];
        f.tintColor = [UIColor clearColor];
        f.backgroundColor = [UIColor clearColor];
        f.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                             UIViewAutoresizingFlexibleHeight;
        g_secure_host = f;
    }
    if (g_secure_host.superview != host) {
        [g_secure_host removeFromSuperview];
        g_secure_host.frame = host.bounds;
        [host addSubview:g_secure_host];
    }
    [g_secure_host layoutIfNeeded];

    if (g_secure_canvas == nil) {
        UIView *best = nil;
        for (UIView *v in g_secure_host.subviews) {
            NSString *cn = NSStringFromClass(v.class);
            if ([cn rangeOfString:@"Canvas"].location != NSNotFound ||
                [cn rangeOfString:@"Content"].location != NSNotFound) { best = v; break; }
        }
        if (best == nil && g_secure_host.subviews.count > 0)
            best = g_secure_host.subviews.firstObject;
        if (best != nil) {
            best.userInteractionEnabled = YES;
            g_secure_canvas = best;
            g_secure_canvas_state = 1;
        } else {
            g_secure_canvas_state = 0;
        }
    }
    if (g_secure_canvas != nil) {
        g_secure_canvas.frame = g_secure_host.bounds;
        return g_secure_canvas;
    }
    return host;
}

static BOOL mm_place_ui(void)
{
    @try {
        UIWindow *host = mm_host_window();
        if (host == nil) return NO;
        UIView *container = mm_ui_container(host);
        if (container == nil) return NO;

        if (g_root == nil) {
            g_root = [[MMPassView alloc] initWithFrame:container.bounds];
            g_root.backgroundColor = [UIColor clearColor];
            g_root.opaque = NO;  /* v0.2.7: capa transparente limpia */
            g_root.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                                      UIViewAutoresizingFlexibleHeight;
        }

        BOOL recolocar = NO;
        if (g_root.superview != container) {
            [g_root removeFromSuperview];
            g_root.frame = container.bounds;
            [container addSubview:g_root];
            recolocar = YES;
            g_via = "ventana_del_juego";
            MM_LOG(@"%s UI enganchada a la ventana del juego (nivel=%.0f clase=%@)",
                  MM_TAG, host.windowLevel, NSStringFromClass(host.class));
        }
        if (container.subviews.lastObject != g_root) [container bringSubviewToFront:g_root];

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
        /* v0.6.4: barra rapida (encima del lienzo, debajo del panel por orden
           de insercion; se oculta sola cuando el panel esta abierto). */
        if (g_quickbar == nil) mm_build_quickbar();
        if (g_quickbar.superview != g_root) {
            [g_quickbar removeFromSuperview];
            [g_root addSubview:g_quickbar];
        }
        mm_refresh_quickbar();

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
            /* C-3: boton AIM flotante (mantener = aim asiste en modo Aim Key) */
            if (g_aimkey_btn == nil) {
                g_aimkey_btn = [UIButton buttonWithType:UIButtonTypeCustom];
                g_aimkey_btn.bounds = CGRectMake(0, 0, 46.0, 46.0);
                g_aimkey_btn.layer.cornerRadius = 23.0;
                g_aimkey_btn.layer.borderWidth = 1.0;
                g_aimkey_btn.layer.borderColor =
                    [mm_neon_green() colorWithAlphaComponent:0.5].CGColor;
                g_aimkey_btn.backgroundColor =
                    [UIColor colorWithRed:0.02 green:0.08 blue:0.05 alpha:0.92];
                [g_aimkey_btn setTitle:@"AIM" forState:UIControlStateNormal];
                g_aimkey_btn.titleLabel.font = [UIFont boldSystemFontOfSize:11.0];
                [g_aimkey_btn setTitleColor:mm_neon_green() forState:UIControlStateNormal];
                [g_aimkey_btn addTarget:[MMTargets shared] action:@selector(onAimKeyDown:)
                     forControlEvents:UIControlEventTouchDown];
                [g_aimkey_btn addTarget:[MMTargets shared] action:@selector(onAimKeyUp:)
                     forControlEvents:(UIControlEventTouchUpInside |
                                     UIControlEventTouchUpOutside |
                                     UIControlEventTouchCancel)];
                [g_root addSubview:g_aimkey_btn];
            }
            g_aimkey_btn.center = CGPointMake(bx + 62.0, by);
            g_aimkey_btn.hidden = !(g_aim_key_mode && g_aim_on);
            MM_LOG(@"%s boton+panel listos via=%s", MM_TAG, g_via);
        }
        mm_layout_quickbar();

        mm_apply_stream();
        /* v0.2.7: NO re-abrir el panel en cada latido. Antes, con el panel
           abierto, cada latido (0.5 s al principio; 5 s despues) volvia a
           llamar a mm_set_panel(YES), que re-disparaba la animacion de
           entrada desde alpha 0: el menu parecia parpadear. Ahora solo se
           asegura de que siga visible, sin animar de nuevo (si el latido
           recoloco la UI, se reposiciona con la memoria de siempre). */
        if (g_panel_open && g_panel != nil) {
            if (recolocar) mm_position_panel();
            /* v0.5.0 FIX: antes el latido forzaba alpha 1.0 cuando quedaba por
               debajo de 0.95 y pisaba la opacidad elegida en el slider
               (0.4-1.0) a los pocos segundos. Ahora se respeta el valor. */
            CGFloat mmOp = mm_def_float(@"mm_menu_opacity", 1.0f);
            if (mmOp < 0.4f) mmOp = 0.4f; if (mmOp > 1.0f) mmOp = 1.0f;
            if (g_panel.hidden || g_panel.alpha < mmOp - 0.05f) {
                g_panel.hidden = NO;
                g_panel.alpha = mmOp;
            }
        }

        /* v0.5.0: si iOS purgo la animacion del emblema (background), se
           reanuda; es una animacion de GPU, sin costo de CPU por frame. */
        mm_btn_spin(g_btn_glyph);

        return YES;
    } @catch (NSException *e) {
        MM_LOG(@"%s excepcion colocando la UI: %@", MM_TAG, e.reason);
        return NO;
    }
}

/* El latido: coloca la UI, la refresca y deja rastro. Rapido (0.5 s) los
   primeros 60 s; despues lento (5 s) pero PARA SIEMPRE. */
static void mm_tick(void)
{
#ifdef MM_USE_IMGUI
    /* 0.15.0: el panel ImGui se crea una sola vez, ya con la ventana lista. */
    {   static int s_ig_done = 0;
        if (!s_ig_done) { s_ig_done = 1; extern void mm_imgui_start(void); mm_imgui_start(); }
    }
#endif
    @try {
        g_tries++;
        if (!g_ui_ok) g_ui_ok = YES;
        BOOL fast = (g_tries <= MM_FAST_TRIES);
        mm_health_update();
        BOOL ok = mm_place_ui();
        if (g_boot_forced && !g_boot_alerted && mm_uptime() > 4.0) {
            g_boot_alerted = 1;
            mm_show_alert(mm_tr(@"Modo seguro forzado"),
                          mm_tr(@"Dos arranques sin cierre limpio seguidos. El overlay quedo apagado; revisa MISC."));
        }
        if (g_probe == nil && mm_uptime() > 2.0) mm_probe_run();
        /* C-25: probe BR DESACTIVADO. Hacia un dump de memoria de ~500 ms cada
           30 s (hitch de medio segundo) y la zona BR esta descartada.
           Tambien se dejo de reconstruir el texto de INFO en cada latido: solo
           con el panel abierto (era un NSAttributedString grande por tick). */
        if (g_panel_open) mm_refresh_info();

        if (fast) {
            if (!ok && (g_tries % MM_FAST_LOG_EVERY) == 0)
                MM_LOG(@"%s esperando escena/ventana... intento %d/%d (escenas=%d ventanas=%d)",
                      MM_TAG, g_tries, MM_FAST_TRIES, mm_scene_count(), mm_window_count());
            if (!ok && g_tries == MM_FAST_TRIES)
                MM_LOG(@"%s fase rapida agotada; sigo intentando cada %d s",
                      MM_TAG, MM_SLOW_SECS);
        } else {
            MM_LOG(@"%s latido vivo_s=%d escenas=%d estado=%@ ventanas=%d boton=%s panel=%s via=%s",
                  MM_TAG, (int)mm_uptime(), mm_scene_count(), mm_scene_state(),
                  mm_window_count(), ok ? "SI" : "NO",
                  g_panel_open ? "abierto" : "cerrado", g_via);
            mm_write_status(ok ? @"latido ok" : @"latido sin ventana");
        }

        double next = fast ? 0.5 : (double)MM_SLOW_SECS;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(next * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{ mm_tick(); });
    } @catch (NSException *e) {
        MM_LOG(@"%s excepcion en el latido: %@", MM_TAG, e.reason);
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

/* Clave publica ES256 del proyecto: definida arriba, junto a la version, para
   que la use tambien el verificador de remote config (4.1).
   PLACEHOLDER solo si el bloque de arriba se deja en 0x04: la verificacion
   fallara (reason="firma invalida"), que es lo correcto hasta pegar la real. */

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

/* 1.19: marca corta y estable para rastrear filtraciones sin exponer el HWID
   completo. Deriva de HWID + build + pack; se muestra solo con opt-in. */
static NSString *mm_build_mark(void)
{
    static NSString *s = nil;
    if (s != nil) return s;
    NSString *seed = [NSString stringWithFormat:@"%@|%s|%s",
                      mm_lic_hwid(), MODMENU_VERSION, FUSION_PACK_VERSION];
    const char *u = seed.UTF8String;
    uint32_t h = 2166136261u;
    while (u != NULL && *u != '\0') {
        h ^= (uint8_t)(*u++);
        h *= 16777619u;
    }
    s = [NSString stringWithFormat:@"%08x", h];
    return s;
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
    if (g_lic_valid && g_cfg_revoked != nil &&
        [g_cfg_revoked containsObject:[mm_lic_hwid() lowercaseString]]) {
        g_lic_valid = NO;
        g_lic_reason = @"revocado (config)";
    }
    if (g_lic_valid && fromFile)                     /* migrar el token de archivo al Keychain */
        mm_lic_kc_set(@"token", [token dataUsingEncoding:NSUTF8StringEncoding]);
    long now = (long)time(NULL);
    NSString *st = [NSString stringWithFormat:@"lic=%@ sku=%@ reason=%@ exp_dias=%ld enforce=%@",
                    g_lic_valid ? @"si" : @"no", g_lic_sku ?: @"-", g_lic_reason ?: @"-",
                    g_lic_exp ? (g_lic_exp - now) / 86400 : 0, g_lic_enforce ? @"si" : @"no"];
    MM_LOG(@"%s licencia: %@ (hwid=%@…)", MM_TAG, st, [mm_lic_hwid() substringToIndex:12]);
    mm_write_status([@"licencia " stringByAppendingString:st]);
    mm_refresh_license_label();
    /* ENFORCE (cuando se valide en equipo): if (g_lic_enforce && !g_lic_valid)
       -> no instalar hooks / apagar feats; por ahora solo observa. */
}

/* v0.7.0 (4.2): cliente in-menu sin red. El token se pega desde el
   portapapeles (lo emite el Studio/servidor), se guarda en el Keychain y se
   valida con la misma ruta que el arranque. */
static void mm_lic_save_token(NSString *token)
{
    if (token.length == 0) return;
    mm_lic_kc_set(@"token", [token dataUsingEncoding:NSUTF8StringEncoding]);
}

static NSString *mm_lic_short_status(void)
{
    NSString *h = mm_lic_hwid();
    NSString *shortH = h.length > 8 ? [h substringToIndex:8] : h;
    return [NSString stringWithFormat:@"HWID %@  ·  %@  ·  SKU %@",
            shortH, g_lic_valid ? @"activa" : (g_lic_reason ?: @"sin token"),
            g_lic_sku ?: @"-"];
}

static BOOL mm_lic_is_valid(void) { return g_lic_valid; }

static void mm_refresh_license_label(void)
{
    if (g_lic_label == nil) return;
    g_lic_label.text = mm_lic_short_status();
}

__attribute__((constructor)) static void modmenu_init(void)
{
    /* v0.8.1 A.1: anti-debug lo PRIMERO. Si llegaron a debuggear, al menos
       que no puedan adjuntar debugger desde este punto en adelante. */
    mm_antidebug();

    g_t0 = [NSDate date].timeIntervalSinceReferenceDate;
    mm_boot_check();      /* 1.11: crash counter ANTES de tocar la UI */
    mm_cfg_load();        /* 4.1: remote config firmado (opt-in por archivo) */
    mm_reset_options();   /* v0.2.7: opciones a fabrica en cada arranque */

    /* Fase C (ADR 0008): fuerza de aim. Lee el valor persistido (el slider lo
       escribe) y lo publica en el slot del relay (cod_base+0xDC639EC). */
    g_aim_strength = mm_def_float(@"mm_x_aim_strength", 28.0f);
    if (g_aim_strength < 0.0f || g_aim_strength > 28.0f) g_aim_strength = 28.0f;
    g_aim_fov = mm_def_float(@"mm_x_aim_fov", 90.0f);
    if (g_aim_fov < 5.0f || g_aim_fov > 180.0f) g_aim_fov = 180.0f;
    g_aim_smooth = mm_def_float(@"mm_x_aim_smooth", 0.0f);
    if (g_aim_smooth < 0.0f || g_aim_smooth > 1.0f) g_aim_smooth = 0.0f;
    g_cam_fov = mm_def_float(@"mm_cam_fov", 0.0f);
    if (g_cam_fov < 0.5f || g_cam_fov > 120.0f) g_cam_fov = 0.0f;
    g_aim_on = mm_def_bool(@"mm_x_aim_on", NO);
    mm_reload_apply();   /* C-18 */
    mm_lock_opts_sync(); /* 0.9.1: aim lock */
    g_aim_key_mode = mm_def_bool(@"mm_x_aim_key", NO);
    {   /* C-4: el relay lleva el estado del suavizado en +0xF8; arranca en 0. */
        const struct mach_header *h0 = _dyld_get_image_header(0);
        if (h0 != NULL) *(float *)((uintptr_t)h0 + (uintptr_t)0x0DC639F8ULL) = 0.0f;
    }
    mm_aim_apply();

    /* v0.8.1 A.2/A.5: observers de captura y background. Se registran una
       sola vez; la UI (g_panel/g_btn) puede no existir todavia, los
       handlers son defensivos y checan nil. */
    mm_register_hardening_observers();
    g_cb_mode = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"mm_color_mode"];
    if (g_cb_mode != 1 && g_cb_mode != 3) g_cb_mode = 0;
    MM_LOG(@"%s dylib cargada v%s  path=%s  pid=%d (opciones reseteadas)",
          MM_TAG, MODMENU_VERSION, mm_my_path(), (int)getpid());
    mm_write_status(@"arranque (opciones a fabrica)");
    mm_lic_check();       /* v0.3.7: licencia (observacion; migra KeyGate) */
    mm_nojb_start();      /* v0.2.8: fase C (antidetect) en segundo plano */
    mm_dobby_init();     /* v0.8.2 Fase B.2/B.3: Dobby si MM_USE_DOBBY */

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{ mm_tick(); });
}

/* ===========================================================================
 *  0.15.0 — API del panel (mm_panel_api.h).
 *
 *  Costura entre el panel (hoy ImGui, ver imgui_app.mm) y el motor. El panel NO
 *  toca las variables internas: entra por aca.
 *
 *  Los setters hacen las TRES cosas que hace el panel UIKit en onSwitch::
 *    1. persisten la preferencia con la misma clave,
 *    2. invalidan el cache de opciones de dibujo (mm_opts_invalidate),
 *    3. actualizan el estado en caliente (g_lock_on, g_aim_*, g_lock_*).
 *  Asi los dos paneles quedan siempre en sincronia.
 *
 *  Todo el bloque esta bajo MM_USE_IMGUI: sin ese define no existe y la build
 *  queda identica a la anterior.
 * ========================================================================= */
#ifdef MM_USE_IMGUI
#include "mm_panel_api.h"

static const char *const MM_ESP_KEYS[] = {
    "mm_esp_master", "mm_esp_box", "mm_esp_players", "mm_esp_bots",
    "mm_esp_name", "mm_esp_dist", "mm_esp_lines", "mm_esp_health",
    "mm_esp_fill", "mm_x_radar", "mm_x_cross", "mm_x_aimring", "mm_x_fps",
    NULL
};

static BOOL mm_api_key_ok(const char *key)
{
    if (!key) return NO;
    for (int i = 0; MM_ESP_KEYS[i] != NULL; i++)
        if (strcmp(MM_ESP_KEYS[i], key) == 0) return YES;
    return NO;
}

static void mm_api_put_bool(const char *key, BOOL on)
{
    if (!mm_api_key_ok(key)) return;
    NSString *k = [NSString stringWithUTF8String:key];
    [[NSUserDefaults standardUserDefaults] setBool:on forKey:k];
    mm_opts_invalidate();
    if ([k isEqualToString:@"mm_esp_master"]) mm_apply_esp_lock();
    if ([k isEqualToString:@"mm_x_radar"] && g_esp != nil) [g_esp setNeedsDisplay];
}

static void mm_lock_kind_put(int kind, BOOL on)
{
    const char *key = (kind == 1) ? "mm_lock_rifle"   :
                      (kind == 2) ? "mm_lock_smg"     :
                      (kind == 3) ? "mm_lock_shotgun" : "mm_lock_sniper";
    if (kind < 1 || kind > 4) return;
    [[NSUserDefaults standardUserDefaults] setBool:on
                                            forKey:[NSString stringWithUTF8String:key]];
    mm_lock_opts_sync();
}

/* ---- aim ---- */
int mm_panel_aimlock(void)          { return g_lock_on ? 1 : 0; }
void mm_panel_set_aimlock(int on)   { g_lock_on = on ? YES : NO;
                                      if (!on) g_lock_active = 0; }
float mm_panel_aim_fov(void)        { return g_aim_fov; }
void mm_panel_set_aim_fov(float v)  { g_aim_fov = v; }
float mm_panel_aim_smooth(void)     { return g_aim_smooth; }
void mm_panel_set_aim_smooth(float v) { g_aim_smooth = v; }
float mm_panel_aim_height(void)     { return g_aim_height; }
void mm_panel_set_aim_height(float v) { g_aim_height = v; }
float mm_panel_aim_strength(void)   { return g_aim_strength; }
void mm_panel_set_aim_strength(float v)
{
    if (v < 0.0f) v = 0.0f;
    if (v > 28.0f) v = 28.0f;
    g_aim_strength = v;
    [[NSUserDefaults standardUserDefaults] setFloat:v forKey:@"mm_x_aim_strength"];
    mm_aim_apply();                     /* reescribe el slot del relay (ADR 0008) */
}

/* ---- filtro por arma ---- */
int mm_panel_lock_kind(int kind)
{
    switch (kind) {
        case 1: return g_lock_rifle ? 1 : 0;
        case 2: return g_lock_smg ? 1 : 0;
        case 3: return g_lock_shotgun ? 1 : 0;
        case 4: return g_lock_sniper ? 1 : 0;
        default: return 0;
    }
}
void mm_panel_set_lock_kind(int kind, int on) { mm_lock_kind_put(kind, on ? YES : NO); }
int  mm_panel_lock_ads(void)        { return g_lock_ads ? 1 : 0; }
void mm_panel_set_lock_ads(int on)  { g_lock_ads = on ? YES : NO;
                                      [[NSUserDefaults standardUserDefaults]
                                          setBool:g_lock_ads forKey:@"mm_lock_ads"]; }

/* ---- ESP ---- */
int mm_panel_esp(const char *key)
{
    if (!mm_api_key_ok(key)) return -1;
    return mm_def_bool([NSString stringWithUTF8String:key], NO) ? 1 : 0;
}
void mm_panel_set_esp(const char *key, int on) { mm_api_put_bool(key, on ? YES : NO); }

/* ---- identidad: el panel pide los acentos en vez de tener colores propios ---- */
void mm_panel_accent(int secondary, float out[3])
{
    if (out == NULL) return;
    UIColor *c = secondary ? mm_neon_purple() : mm_neon_green();
    CGFloat r = 0.20, g = 1.00, b = 0.58;
    if (![c getRed:&r green:&g blue:&b alpha:NULL]) {
        /* color en otro espacio: caemos al tema 0 (FUSION) */
        r = secondary ? 0.63 : 0.20;
        g = secondary ? 0.30 : 1.00;
        b = secondary ? 1.00 : 0.58;
    }
    out[0] = (float)r;
    out[1] = (float)g;
    out[2] = (float)b;
}

/* ---- telemetria ---- */
float mm_panel_fps(void)            { return g_fps; }
int   mm_panel_targets(void)        { return g_box_count; }
int   mm_panel_lock_active(void)    { return g_lock_active ? 1 : 0; }
long  mm_panel_lock_frames(void)    { return (long)g_lock_frames; }
long  mm_panel_lock_stuck(void)     { return g_lock_diag[0]; }
long  mm_panel_lock_pisan(void)     { return g_lock_diag[1]; }
const char *mm_panel_version(void)  { return MODMENU_VERSION; }

/* ---- acciones ---- */
void mm_panel_close(void)           { mm_set_panel(NO); }
int  mm_panel_visible(void)         { return g_panel_open ? 1 : 0; }

#endif /* MM_USE_IMGUI */
