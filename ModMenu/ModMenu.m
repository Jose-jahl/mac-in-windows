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

#define MODMENU_VERSION     "0.7.2"
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
const char *modmenu_build_id = "modmenu-glass-0.7.2";

/* --- objetos de UI (globales, creados una sola vez) --- */
static UIView   *g_root  = nil;   /* capa transparente sobre la ventana juego */
static UIButton *g_btn   = nil;   /* boton flotante                           */
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
static UISegmentedControl *g_seg = nil;
static UILabel  *g_marca  = nil;  /* marca de agua v0.2.4 (identidad) */
static UIView   *g_p_esp  = nil;
static UIView   *g_p_vis  = nil;  /* v0.3.0: Stream Mode + pulido ESP */
static UIView   *g_p_misc = nil;
static UIButton *g_dbgbtn = nil;  /* v0.6.1: Debug como boton de fila completa */
static UIView   *g_p_info = nil;
static UIView   *g_p_more = nil;  /* v0.4.0: pagina EXTRA (features nuevas)    */
static UILabel  *g_info   = nil;  /* texto vivo de la pagina INFO             */
static UILabel  *g_range_val = nil;
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

/* --- ESP: lienzo + cajas + sonda --- */
#define MM_MAX_BOXES 32
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
    char    name[64];           /* v0.2.4: nombre UTF-8 del jugador     */
} MMEspBox;
static MMEspBox     g_boxes[MM_MAX_BOXES];
static int          g_box_count = 0;  /* cajas listas para pintar         */
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
    int   proj;         /* 1 = tiene caja dibujable en g_boxes          */
    int   behind;       /* 1 = detras de la camara (no proyectable)     */
    int   has_sx;       /* 1 = la proyeccion dio un punto (aunque fuera)*/
} MMTrack;
static MMTrack      g_tracks[MM_MAX_TRACKS];
static int          g_track_count = 0;

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
static void mm_br_probe_run(void);     /* 0.6.0: dump de los setters de RadiationZone */
static void mm_br_zone_read(void);     /* 0.6.3: lee el manager si hay offsets verificados */
static void mm_layout_count_glass(void);
static void mm_refresh_count_glass(void);
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
    int  boxStyle, theme, crossStyle, maxN;
    float range;
} MMDrawOpts;
static MMDrawOpts g_draw_opts;
static BOOL g_draw_opts_ok = NO;
static void mm_opts_invalidate(void) { g_draw_opts_ok = NO; }
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
    o->declutter = mm_def_bool(@"mm_x_declutter", NO);
    o->radarCam  = mm_def_bool(@"mm_x_radar_cam", YES);
    o->targetList= mm_def_bool(@"mm_x_targetlist", NO);
    o->players   = mm_def_bool(@"mm_esp_players", NO);
    o->bots      = mm_def_bool(@"mm_esp_bots", NO);
    o->boxStyle  = (int)mm_def_float(@"mm_esp_box_style", 0.0f);
    o->theme     = (int)mm_def_float(@"mm_esp_theme", 0.0f);
    o->crossStyle= (int)mm_def_float(@"mm_x_cross_style", 0.0f);
    o->maxN      = (int)mm_def_float(@"mm_x_maxn", 0.0f);
    o->range     = mm_def_float(@"mm_esp_range", 300.0f);
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
static void mm_draw_radar(CGContextRef ctx, CGRect bs, CGFloat cr, CGFloat cg, CGFloat cb)
{
    if (!g_have_local) return;
    CGFloat R = 76.0, cx = bs.size.width - R - 16.0, cy = R + 54.0;
    const MMDrawOpts *o = mm_draw_opts();
    float rng = o->range; if (rng < 40.0f) rng = 40.0f;
    /* El radar es tactico: 200 m de techo. Los contactos mas lejanos quedan
       pegados al borde y atenuados (el ESP sigue mostrando su caja real). */
    float radarRng = (rng > 200.0f) ? 200.0f : rng;
    BOOL camUp = o->radarCam && g_have_view;

    /* fondo: disco oscuro + aro interior tenue del color del tema para marcar
       que es parte del mod y no del HUD del juego. */
    CGContextSetRGBFillColor(ctx, 0.02, 0.05, 0.04, 0.72);
    CGContextFillEllipseInRect(ctx, CGRectMake(cx - R, cy - R, R * 2.0, R * 2.0));
    CGContextSetLineWidth(ctx, 0.8);
    CGContextSetRGBStrokeColor(ctx, cr, cg, cb, 0.14);
    CGContextStrokeEllipseInRect(ctx, CGRectMake(cx - (R - 1.5), cy - (R - 1.5),
                                                  (R - 1.5) * 2.0, (R - 1.5) * 2.0));

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
        if (tk->robot) { colR = 0.63; colG = 0.30; colB = 1.0; }
        else           { colR = 1.0;  colG = 0.25; colB = 0.30; }

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
        @"ESP de esqueleto": @"Skeleton ESP",
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
        @"Aimbot no toggleable para mayor seguridad.\n\n":
            @"Aimbot is not toggleable, for safety.\n\n",
        @"Activar todas las opciones no da problemas de seguridad;\nel costo es rendimiento (FPS) en el dispositivo.\n\n":
            @"Enabling every option is not a security problem;\nthe cost is device performance (FPS).\n\n",
        @"Proyecto desarrollado por\nJose Lopez - Ing. de Sistemas\n\n":
            @"Project developed by\nJose Lopez - Systems Engineer\n\n",
        @"Contacto:": @"Contact:",
        @"Listo": @"Done",
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
        MM_LOG(@"%s onPanelPan: %@", MM_TAG, e.reason);
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
    if (g_panel != nil && !g_panel.hidden)
        g_panel.transform = CGAffineTransformMakeScale(s.value, s.value);
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
    [[NSUserDefaults standardUserDefaults] setFloat:(float)(int)(s.value + 0.5f)
                                             forKey:@"mm_x_maxn"];
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
/* v0.6.2: huella FNV-1a de todo lo que drawRect puede mostrar. Si no cambia,
   el frame se salta entero (no setNeedsDisplay, no CoreGraphics). */
static unsigned long long mm_frame_digest(void)
{
    unsigned long long h = 1469598103934665603ULL;
    const unsigned char *p;
    size_t n;
#define MM_FNV(buf, len) do { \
    p = (const unsigned char *)(buf); n = (size_t)(len); \
    for (size_t _i = 0; _i < n; _i++) { h ^= p[_i]; h *= 1099511628211ULL; } \
} while (0)
    MM_FNV(g_view_mtx, sizeof(g_view_mtx));
    MM_FNV(g_proj_mtx, sizeof(g_proj_mtx));
    MM_FNV(&g_have_view, sizeof(g_have_view));
    MM_FNV(&g_have_local, sizeof(g_have_local));
    MM_FNV(g_local_pos, sizeof(g_local_pos));
    int bc = g_box_count; if (bc < 0) bc = 0; if (bc > MM_MAX_BOXES) bc = MM_MAX_BOXES;
    int tc = g_track_count; if (tc < 0) tc = 0; if (tc > MM_MAX_TRACKS) tc = MM_MAX_TRACKS;
    MM_FNV(&bc, sizeof(bc));
    MM_FNV(&tc, sizeof(tc));
    if (bc > 0) MM_FNV(g_boxes, sizeof(MMEspBox) * (size_t)bc);
    if (tc > 0) MM_FNV(g_tracks, sizeof(MMTrack) * (size_t)tc);
    /* v0.6.3: la zona BR tambien manda (sin el timestamp de lectura). */
    MM_FNV(&g_br_zone.ok, sizeof(g_br_zone.ok));
    MM_FNV(&g_br_zone.x, sizeof(g_br_zone.x));
    MM_FNV(&g_br_zone.y, sizeof(g_br_zone.y));
    MM_FNV(&g_br_zone.z, sizeof(g_br_zone.z));
    MM_FNV(&g_br_zone.r, sizeof(g_br_zone.r));
    const MMDrawOpts *o = mm_draw_opts();
    MM_FNV(o, sizeof(*o));
#undef MM_FNV
    return h;
}

static void mm_esp_frame(double t)
{
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
           haya quedado prendido. El boton/panel siguen para poder salir. */
        if (mm_def_bool(@"mm_safe_mode", NO)) {
            if (g_box_count != 0 || g_track_count != 0) {
                g_box_count = 0;
                g_track_count = 0;
                [g_esp setNeedsDisplay];
            }
            if (!g_esp.hidden) g_esp.hidden = YES;
            mm_refresh_count_glass();
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

        static int s_tick = 0;              /* datos ~30 Hz, pintado a 60 fps */
        if ((s_tick++ & 1) == 0) {
            mm_esp_collect_real();
            mm_br_zone_read();              /* v0.6.3: zona BR (2 Hz, si hay offsets) */
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

/* ---------------- BR probe (v0.6.0): decodifica el prologo ARM64 ----------------
   Lee los primeros 16 instrucciones de cada set_RadiationZone* desde la imagen del
   juego y extrae el offset del campo dentro del BRRadiationZoneMgr (y la direccion
   estatica para set_RadiationZoneMgr). Cero llamadas al juego: solo lee bytes del
   segmento __text, mismo tipo de operacion que la sonda de 0.5.

   Patrones ARM64 reconocidos:
     STR Wt, [X0, #imm*4]   -> 0xB9000000 base   (int32)
     STR Xt, [X0, #imm*8]   -> 0xF9000000 base   (int64 / ptr)
     STR St, [X0, #imm*4]   -> 0xBD000000 base   (float32)
     STR Dt, [X0, #imm*8]   -> 0xFD000000 base   (float64)
     ADRP Xd + STR Xt, [Xd, #lo12]              (store a direccion estatica)
   Si no encuentra ninguno en 16 instrucciones, reporta "?". Si el setter copia un
   struct, registra hasta 6 stores consecutivos (set_RadiationZoneShape).

   El resultado va a g_br_probe y de ahi a modmenu_status.txt (solo con mm_debug ON).
--------------------------------------------------------------------------------*/

typedef struct {
    uint32_t off;                  /* offset dentro de [x0] */
    uint32_t size;                 /* 1,2,4,8 */
    char     kind;                 /* 'w','x','s','d' */
    char     src;                  /* 'i' = instance ([x0]), 's' = static */
    uint64_t static_addr_rt;       /* direccion runtime del static (si src=='s') */
    uint32_t extra_off[6];
    uint8_t  extra_sz[6];
    char     extra_kind[6];
    int      extra_n;
    int      found;
} mm_br_decode_t;

static int mm_br_match_str_x0(uint32_t ins, mm_br_decode_t *d, int is_extra)
{
    uint32_t Rn = (ins >> 5) & 0x1F;
    uint32_t Rt = ins & 0x1F;
    uint32_t imm12 = (ins >> 10) & 0xFFF;
    if (Rn != 0) return 0;
    if (!is_extra && Rt != 1) return 0;    /* el primer store es siempre w1/x1/s1/d1 (arg1 del setter) */
    uint32_t base = ins & 0xFFC00000;
    uint32_t off, sz; char kind;
    if      (base == 0xB9000000) { off = imm12 * 4; sz = 4; kind = 'w'; }
    else if (base == 0xF9000000) { off = imm12 * 8; sz = 8; kind = 'x'; }
    else if (base == 0xBD000000) { off = imm12 * 4; sz = 4; kind = 's'; }
    else if (base == 0xFD000000) { off = imm12 * 8; sz = 8; kind = 'd'; }
    else return 0;
    if (!is_extra) {
        d->off = off; d->size = sz; d->kind = kind; d->src = 'i';
    } else {
        int i = d->extra_n;
        if (i < 6) { d->extra_off[i] = off; d->extra_sz[i] = sz; d->extra_kind[i] = kind; d->extra_n++; }
    }
    return 1;
}

static int mm_br_decode_setter(uint64_t va_rt, mm_br_decode_t *d)
{
    memset(d, 0, sizeof(*d));
    const uint32_t *ins = (const uint32_t *)(uintptr_t)va_rt;
    for (int i = 0; i < 16; i++) {
        uint32_t w = ins[i];
        /* RET temprano: fin del cuerpo */
        if (w == 0xD65F03C0) break;

        /* ADRP + STR a direccion estatica */
        if ((w & 0x9F000000) == 0x90000000) {
            uint32_t Rd = w & 0x1F;
            int64_t immlo = (w >> 29) & 3;
            int64_t immhi = (w >> 5) & 0x7FFFF;
            int64_t imm = (immhi << 2) | immlo;
            if (imm & (1LL << 20)) imm |= ~((1LL << 21) - 1);
            imm <<= 12;
            uint64_t pc = va_rt + (uint64_t)i * 4;
            uint64_t target_page = (pc & ~0xFFFULL) + (uint64_t)imm;
            for (int j = i + 1; j < i + 6 && j < 16; j++) {
                uint32_t w2 = ins[j];
                if ((w2 & 0xFFC00000) == 0xF9000000) {
                    uint32_t Rn2 = (w2 >> 5) & 0x1F;
                    uint32_t Rt2 = w2 & 0x1F;
                    uint32_t imm12 = (w2 >> 10) & 0xFFF;
                    if (Rn2 == Rd && Rt2 == 1) {
                        d->size = 8; d->kind = 'x'; d->src = 's';
                        d->static_addr_rt = target_page + (uint64_t)imm12 * 8;
                        d->found = 1;
                        return 1;
                    }
                }
            }
        }

        /* STR primario */
        if (!d->found && mm_br_match_str_x0(w, d, 0)) {
            d->found = 1;
            /* buscar hasta 6 stores adicionales (struct arg) */
            for (int j = i + 1; j < 16; j++) {
                uint32_t w2 = ins[j];
                if (w2 == 0xD65F03C0) break;
                mm_br_match_str_x0(w2, d, 1);
                if (d->extra_n >= 6) break;
            }
            return 1;
        }
    }
    return 0;
}

/* v0.6.1: el resultado del probe BR se escribe SIEMPRE en
   Documents/br_probe.txt, sin depender del toggle Debug. Es el dato que el
   operador necesita extraer: si el toggle no responde, este archivo sigue
   existiendo. Formato compatible con kit/br-probe/leer-status.ps1. */
static void mm_write_br_file(NSString *linea)
{
    @try {
        NSString *docs = mm_docs_dir();
        if (docs.length == 0 || linea.length == 0) return;
        NSString *txt = [NSString stringWithFormat:
            @"build=%s\ndylib=%s\nuptime_s=%d\nbr_probe=%@\n",
            MODMENU_VERSION, mm_my_path(), (int)mm_uptime(), linea];
        [txt writeToFile:[docs stringByAppendingPathComponent:@"br_probe.txt"]
               atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    } @catch (NSException *e) {
        MM_LOG(@"%s no pude escribir br_probe.txt: %@", MM_TAG, e.reason);
    }
}

static void mm_br_probe_run(void)
{
    @try {
        const struct mach_header *hdr = _dyld_get_image_header(0);
        if (hdr == NULL) {
            g_br_probe = @"sin imagen principal";
            mm_write_br_file(g_br_probe);
            return;
        }
        uintptr_t base = (uintptr_t)hdr;

        struct { const char *name; uint64_t va; } setters[] = {
            { "set_Mgr",       0x107528BB8ULL },
            { "set_BRMgr",     0x10747071CULL },
            { "set_Shape",     0x1079D91DCULL },
            { "set_Radius",    0x1079DB518ULL },
            { "set_NextBegin", 0x1079DB584ULL },
            { "set_SpreadEnd", 0x1079DB59CULL },
            { "set_TotalSpr",  0x1079DC8B0ULL },
            { "AddZone",       0x107A0B6ECULL },
            /* IsInBRGame es getter (ldr, no str): no se decodifica, se llama por VA. */
        };
        int N = (int)(sizeof(setters) / sizeof(setters[0]));

        NSMutableString *s = [NSMutableString stringWithFormat:@"base=0x%lX", (unsigned long)base];
        for (int i = 0; i < N; i++) {
            uint64_t rt = base + (uintptr_t)(setters[i].va - FUSION_IMAGE_BASE);
            mm_br_decode_t d;
            if (!mm_br_decode_setter(rt, &d) || !d.found) {
                [s appendFormat:@" | %s=? va=0x%llX",
                     setters[i].name, (unsigned long long)setters[i].va];
                continue;
            }
            if (d.src == 's') {
                uint64_t static_va = (uint64_t)FUSION_IMAGE_BASE + (d.static_addr_rt - (uint64_t)base);
                [s appendFormat:@" | %s=STATIC va=0x%llX static_va=0x%llX",
                     setters[i].name,
                     (unsigned long long)setters[i].va,
                     (unsigned long long)static_va];
            } else {
                [s appendFormat:@" | %s=off=0x%X sz=%u kind=%c",
                     setters[i].name, d.off, d.size, d.kind];
                for (int k = 0; k < d.extra_n; k++) {
                    [s appendFormat:@",+0x%X(%u,%c)",
                         d.extra_off[k], d.extra_sz[k], d.extra_kind[k]];
                }
            }
        }
        g_br_probe = s;
        mm_write_br_file(s);
        mm_write_status(@"br_probe listo");
        MM_LOG(@"%s br_probe: %@", MM_TAG, s);
    } @catch (NSException *e) {
        g_br_probe = [NSString stringWithFormat:@"excepcion: %@", e.reason];
        mm_write_br_file(g_br_probe);
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

static BOOL mm_r64(uintptr_t addr, uint64_t *out)
{
    BOOL ok = NO;
    uint64_t v = mm_safe_read64(addr, &ok);
    if (ok && out != NULL) *out = v;
    return ok;
}

/* v0.6.3: lee la zona de radiacion actual del manager BR.
   Requiere offsets VERIFICADOS en el contrato (el header emite 0 si no hay):
   - BR_STRUCT_MGR_VA   : direccion del slot estatico que guarda el manager
   - BR_STRUCT_SHAPE_OFF: 3 floats (x,y,z) del centro
   - BR_STRUCT_RADIUS_OFF: float del radio
   Si falta cualquiera, la funcion sale sin tocar nada. Lectura a 2 Hz. */
static void mm_br_zone_read(void)
{
    if (BR_STRUCT_MGR_VA == 0ULL || BR_STRUCT_SHAPE_OFF == 0 ||
        BR_STRUCT_RADIUS_OFF == 0) return;
    static double s_last = 0.0;
    double now = CACurrentMediaTime();
    if (s_last > 0.0 && now - s_last < 0.5) return;
    s_last = now;
    @try {
        const struct mach_header *hdr = _dyld_get_image_header(0);
        if (hdr == NULL) return;
        uintptr_t base = (uintptr_t)hdr;
        uintptr_t slot = base + (uintptr_t)(BR_STRUCT_MGR_VA - FUSION_IMAGE_BASE);
        uint64_t mgr = 0;
        if (!mm_r64(slot, &mgr) || mgr == 0) {
            g_br_zone.ok = 0;
            g_br_zone_info = @"sin manager";
            return;
        }
        float shp[3] = { 0.0f, 0.0f, 0.0f };
        if (!mm_vm_read((uintptr_t)mgr + BR_STRUCT_SHAPE_OFF, shp, sizeof(shp))) {
            g_br_zone.ok = 0;
            g_br_zone_info = @"shape ilegible";
            return;
        }
        float rad = 0.0f;
        if (!mm_vm_read((uintptr_t)mgr + BR_STRUCT_RADIUS_OFF, &rad, sizeof(rad))) {
            g_br_zone.ok = 0;
            g_br_zone_info = @"radius ilegible";
            return;
        }
        if (!isfinite(shp[0]) || !isfinite(shp[1]) || !isfinite(shp[2]) ||
            !isfinite(rad) || rad < 1.0f || rad > 50000.0f) {
            g_br_zone.ok = 0;
            g_br_zone_info = @"valores fuera de rango";
            return;
        }
        g_br_zone.x = shp[0];
        g_br_zone.y = shp[1];
        g_br_zone.z = shp[2];
        g_br_zone.r = rad;
        g_br_zone.t = now;
        g_br_zone.ok = 1;
        g_br_zone_info = [NSString stringWithFormat:@"r=%.0f c=(%.0f,%.0f)",
                          rad, shp[0], shp[2]];
    } @catch (NSException *e) {
        g_br_zone.ok = 0;
        g_br_zone_info = @"excepcion";
    }
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

    const MMDrawOpts *opts = mm_draw_opts();
    float rango = opts->range;
    BOOL conSalud  = opts->health;   /* v0.2.4 */
    BOOL conJug    = opts->players;  /* v0.2.7: a fabrica */
    BOOL conBots   = opts->bots;     /* v0.2.7: a fabrica */
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
        if (ent != 0) {
            uint64_t rb = 0;
            if (mm_r64((uintptr_t)ent + OFF_ENT_ROBOT, &rb)) robot = (int)(rb & 0xFF);
        }

        /* v0.2.4: filtros por tipo */
        if (robot && !conBots) continue;
        if (!robot && !conJug) continue;

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
        tk.dist = dist; tk.robot = robot; tk.alive = 1;
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
        if (bstate < 0) continue;   /* v0.2.4: 4 px dejaba fuera a los lejanos */

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
            (int)mm_def_float(@"mm_esp_range", 300.0f),
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
    l.text = mm_tr(titulo);
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
/*---------------------------------------------------------------------------
 * v0.5.0: EMBLEMA DEL BOTON FLOTANTE (reemplaza la "F" de texto blanca).
 * Glifo dibujado con Core Graphics: anillo neon tenue, "F" de trazo redondeado
 * con glow verde y punto de energia morado. Encima, un arco de acento que gira
 * lento con CABasicAnimation: costo GPU, cero CPU por frame.
 *--------------------------------------------------------------------------*/
@interface MMBtnGlyph : UIView
@property (nonatomic, strong) CAShapeLayer *arc;
@end

@implementation MMBtnGlyph
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil) {
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        self.userInteractionEnabled = NO;
        CGFloat w = frame.size.width, h = frame.size.height;
        _arc = [CAShapeLayer layer];
        _arc.frame = self.bounds;
        _arc.path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(w / 2.0, h / 2.0)
                                                   radius:(w / 2.0) - 5.5
                                               startAngle:0.0
                                                 endAngle:(CGFloat)(2.0 * M_PI)
                                                clockwise:YES].CGPath;
        _arc.fillColor = [UIColor clearColor].CGColor;
        _arc.strokeColor = [mm_neon_purple() colorWithAlphaComponent:0.95].CGColor;
        _arc.lineWidth = 2.2;
        _arc.lineCap = kCALineCapRound;
        _arc.strokeStart = 0.0;
        _arc.strokeEnd = 0.30;
        [self.layer addSublayer:_arc];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (ctx == NULL) return;
    CGFloat cx = rect.size.width / 2.0, cy = rect.size.height / 2.0;

    /* anillo base tenue */
    CGContextSetLineWidth(ctx, 1.1);
    CGContextSetRGBStrokeColor(ctx, 0.32, 1.0, 0.62, 0.45);
    CGContextStrokeEllipseInRect(ctx, CGRectMake(cx - 19.5, cy - 19.5, 39.0, 39.0));

    /* "F" de trazo redondeado con glow neon */
    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextSetLineJoin(ctx, kCGLineJoinRound);
    CGContextSetShadowWithColor(ctx, CGSizeZero, 5.0,
        [mm_neon_green() colorWithAlphaComponent:0.85].CGColor);
    CGContextSetRGBStrokeColor(ctx, 0.96, 1.0, 0.97, 1.0);
    CGContextSetLineWidth(ctx, 3.2);
    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, cx - 5.0, cy + 8.0);
    CGContextAddLineToPoint(ctx, cx - 5.0, cy - 8.0);
    CGContextAddLineToPoint(ctx, cx + 6.5, cy - 8.0);
    CGContextStrokePath(ctx);
    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, cx - 5.0, cy + 0.5);
    CGContextAddLineToPoint(ctx, cx + 3.5, cy + 0.5);
    CGContextStrokePath(ctx);

    /* punto de energia */
    CGContextSetShadowWithColor(ctx, CGSizeZero, 4.0,
        [mm_neon_purple() colorWithAlphaComponent:0.9].CGColor);
    CGContextSetRGBFillColor(ctx, 0.78, 0.58, 1.0, 0.95);
    CGContextFillEllipseInRect(ctx, CGRectMake(cx + 11.0, cy - 2.2, 4.4, 4.4));
}
@end

/* Gira el arco de acento del emblema (se reanuda si iOS lo purgo). */
static void mm_btn_spin(MMBtnGlyph *g)
{
    if (g == nil || g.arc == nil) return;
    if ([g.arc animationForKey:@"mm_spin"] != nil) return;
    CABasicAnimation *sp = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    sp.fromValue = @0.0;
    sp.toValue = @(2.0 * M_PI);
    sp.duration = 6.0;
    sp.repeatCount = HUGE_VALF;
    sp.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    [g.arc addAnimation:sp forKey:@"mm_spin"];
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
    /* v0.6.4: doble toque en el encabezado cierra el panel. El swipe de pagina
       vive en el selector (abajo), no aca: el pan del encabezado arrastra el
       panel y no debe competir con un swipe. */
    UITapGestureRecognizer *dtap = [[UITapGestureRecognizer alloc]
        initWithTarget:[MMTargets shared] action:@selector(onHeaderDoubleTap:)];
    dtap.numberOfTapsRequired = 2;
    [dz addGestureRecognizer:dtap];
    [dtap requireGestureRecognizerToFail:dpan];
    /* v0.7.0 (1.10): swipe de DOS dedos en el encabezado -> perfil anterior/siguiente. */
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
    /* v0.6.4: swipe horizontal sobre el selector cambia de pagina. */
    UISwipeGestureRecognizer *swl = [[UISwipeGestureRecognizer alloc]
        initWithTarget:[MMTargets shared] action:@selector(onHeaderSwipe:)];
    swl.direction = UISwipeGestureRecognizerDirectionLeft;
    [g_seg addGestureRecognizer:swl];
    UISwipeGestureRecognizer *swr = [[UISwipeGestureRecognizer alloc]
        initWithTarget:[MMTargets shared] action:@selector(onHeaderSwipe:)];
    swr.direction = UISwipeGestureRecognizerDirectionRight;
    [g_seg addGestureRecognizer:swr];
    [g_panel addSubview:g_seg];

    g_p_esp  = [[UIView alloc] initWithFrame:CGRectMake(8.0, 74.0, 284.0, 348.0)];
    g_p_vis  = [[UIView alloc] initWithFrame:CGRectMake(8.0, 74.0, 284.0, 348.0)];
    g_p_misc = [[UIScrollView alloc] initWithFrame:CGRectMake(8.0, 74.0, 284.0, 348.0)];
    ((UIScrollView *)g_p_misc).showsVerticalScrollIndicator = YES;
    ((UIScrollView *)g_p_misc).indicatorStyle = UIScrollViewIndicatorStyleWhite;
    ((UIScrollView *)g_p_misc).alwaysBounceVertical = YES;
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
    rt.text = mm_tr(@"Rango ESP (m)");
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
    vh.text = mm_tr(@"ESP EN PANTALLA");
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
    vsl.text = mm_tr(@"Estilo de caja");
    vsl.textColor = [UIColor colorWithWhite:0.80 alpha:1.0];
    vsl.font = [UIFont systemFontOfSize:11.0];
    [g_p_vis addSubview:vsl];

    UISegmentedControl *bs = [[UISegmentedControl alloc]
        initWithItems:@[mm_tr(@"Completa"), mm_tr(@"Esquinas")]];
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
    vtl.text = mm_tr(@"Tema de color");
    vtl.textColor = [UIColor colorWithWhite:0.80 alpha:1.0];
    vtl.font = [UIFont systemFontOfSize:11.0];
    [g_p_vis addSubview:vtl];

    UISegmentedControl *ts = [[UISegmentedControl alloc]
        initWithItems:@[mm_tr(@"Clasico"), mm_tr(@"Neon"), mm_tr(@"Blanco")]];
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
    d1.text = mm_tr(@"Cuenta invitado");
    d1.textColor = [UIColor colorWithRed:0.55 green:1.0 blue:0.66 alpha:1.0];
    d1.font = [UIFont boldSystemFontOfSize:12.0];
    [g_p_misc addSubview:d1];

    UIButton *gr = [UIButton buttonWithType:UIButtonTypeCustom];
    gr.frame = CGRectMake(6.0, 28.0, 272.0, 36.0);
    gr.backgroundColor = [UIColor colorWithRed:0.48 green:0.08 blue:0.08 alpha:0.95];
    gr.layer.cornerRadius = 8.0;
    gr.layer.borderWidth = 1.0;
    gr.layer.borderColor = [UIColor colorWithRed:1.0 green:0.45 blue:0.45 alpha:0.7].CGColor;
    [gr setTitle:mm_tr(@"Restablecer invitado") forState:UIControlStateNormal];
    [gr setTitleColor:[UIColor colorWithRed:1.0 green:0.9 blue:0.9 alpha:1.0]
             forState:UIControlStateNormal];
    gr.titleLabel.font = [UIFont boldSystemFontOfSize:13.0];
    [gr addTarget:[MMTargets shared] action:@selector(onGuestReset)
        forControlEvents:UIControlEventTouchUpInside];
    [g_p_misc addSubview:gr];

    /* v0.7.0 (1.8): perfiles de configuracion, 5 slots con nombre y presets. */
    UILabel *pfl = [[UILabel alloc] initWithFrame:CGRectMake(6.0, 78.0, 272.0, 16.0)];
    pfl.text = mm_tr(@"Perfiles (5 slots)");
    pfl.textColor = [UIColor colorWithRed:0.55 green:1.0 blue:0.66 alpha:1.0];
    pfl.font = [UIFont boldSystemFontOfSize:12.0];
    [g_p_misc addSubview:pfl];

    UISegmentedControl *pfseg = [[UISegmentedControl alloc]
        initWithItems:@[@"P1", @"P2", @"P3", @"P4", @"P5"]];
    pfseg.frame = CGRectMake(6.0, 100.0, 272.0, 28.0);
    pfseg.selectedSegmentIndex = 0;
    if ([pfseg respondsToSelector:@selector(setSelectedSegmentTintColor:)])
        pfseg.selectedSegmentTintColor = [mm_neon_purple() colorWithAlphaComponent:0.85];
    [pfseg setTitleTextAttributes:@{ NSForegroundColorAttributeName:[UIColor colorWithWhite:0.88 alpha:1.0],
        NSFontAttributeName:[UIFont boldSystemFontOfSize:11.0] } forState:UIControlStateNormal];
    [pfseg addTarget:[MMTargets shared] action:@selector(onProfileSlot:)
        forControlEvents:UIControlEventValueChanged];
    g_profile_seg = pfseg;
    [g_p_misc addSubview:pfseg];

    g_profile_name_label = [[UILabel alloc] initWithFrame:CGRectMake(6.0, 132.0, 272.0, 14.0)];
    g_profile_name_label.text = mm_profile_name(0);
    g_profile_name_label.textColor = [mm_neon_green() colorWithAlphaComponent:0.95];
    g_profile_name_label.font = [UIFont fontWithName:@"Menlo-Bold" size:10.5] ?:
                                [UIFont boldSystemFontOfSize:10.5];
    g_profile_name_label.textAlignment = NSTextAlignmentCenter;
    [g_p_misc addSubview:g_profile_name_label];

    UIButton *pfsave = [UIButton buttonWithType:UIButtonTypeCustom];
    pfsave.frame = CGRectMake(6.0, 152.0, 132.0, 32.0);
    pfsave.backgroundColor = [UIColor colorWithRed:0.08 green:0.42 blue:0.20 alpha:0.95];
    pfsave.layer.cornerRadius = 7.0;
    [pfsave setTitle:mm_tr(@"Guardar") forState:UIControlStateNormal];
    [pfsave setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    pfsave.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
    [pfsave addTarget:[MMTargets shared] action:@selector(onProfileSave)
        forControlEvents:UIControlEventTouchUpInside];
    [g_p_misc addSubview:pfsave];

    UIButton *pfload = [UIButton buttonWithType:UIButtonTypeCustom];
    pfload.frame = CGRectMake(146.0, 152.0, 132.0, 32.0);
    pfload.backgroundColor = [UIColor colorWithRed:0.10 green:0.28 blue:0.48 alpha:0.95];
    pfload.layer.cornerRadius = 7.0;
    [pfload setTitle:mm_tr(@"Cargar") forState:UIControlStateNormal];
    [pfload setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    pfload.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
    [pfload addTarget:[MMTargets shared] action:@selector(onProfileLoad)
        forControlEvents:UIControlEventTouchUpInside];
    [g_p_misc addSubview:pfload];

    UIButton *pfname = [UIButton buttonWithType:UIButtonTypeCustom];
    pfname.frame = CGRectMake(6.0, 190.0, 88.0, 30.0);
    pfname.backgroundColor = [UIColor colorWithWhite:0.12 alpha:0.95];
    pfname.layer.cornerRadius = 7.0;
    [pfname setTitle:mm_tr(@"Nombre") forState:UIControlStateNormal];
    [pfname setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    pfname.titleLabel.font = [UIFont boldSystemFontOfSize:11.0];
    [pfname addTarget:[MMTargets shared] action:@selector(onProfileName)
        forControlEvents:UIControlEventTouchUpInside];
    [g_p_misc addSubview:pfname];

    UIButton *pfex = [UIButton buttonWithType:UIButtonTypeCustom];
    pfex.frame = CGRectMake(98.0, 190.0, 88.0, 30.0);
    pfex.backgroundColor = [UIColor colorWithWhite:0.12 alpha:0.95];
    pfex.layer.cornerRadius = 7.0;
    [pfex setTitle:mm_tr(@"Exportar") forState:UIControlStateNormal];
    [pfex setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    pfex.titleLabel.font = [UIFont boldSystemFontOfSize:11.0];
    [pfex addTarget:[MMTargets shared] action:@selector(onProfileExport)
        forControlEvents:UIControlEventTouchUpInside];
    [g_p_misc addSubview:pfex];

    UIButton *pfim = [UIButton buttonWithType:UIButtonTypeCustom];
    pfim.frame = CGRectMake(190.0, 190.0, 88.0, 30.0);
    pfim.backgroundColor = [UIColor colorWithWhite:0.12 alpha:0.95];
    pfim.layer.cornerRadius = 7.0;
    [pfim setTitle:mm_tr(@"Importar") forState:UIControlStateNormal];
    [pfim setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    pfim.titleLabel.font = [UIFont boldSystemFontOfSize:11.0];
    [pfim addTarget:[MMTargets shared] action:@selector(onProfileImport)
        forControlEvents:UIControlEventTouchUpInside];
    [g_p_misc addSubview:pfim];

    UILabel *psh = [[UILabel alloc] initWithFrame:CGRectMake(6.0, 228.0, 272.0, 16.0)];
    psh.text = mm_tr(@"Presets contextuales");
    psh.textColor = [UIColor colorWithWhite:0.80 alpha:1.0];
    psh.font = [UIFont systemFontOfSize:11.0];
    [g_p_misc addSubview:psh];

    NSArray *psn = @[@"MP", @"BR", @"Stream", @"Bajo"];
    for (NSUInteger i = 0; i < psn.count; i++) {
        UIButton *pb = [UIButton buttonWithType:UIButtonTypeCustom];
        pb.frame = CGRectMake(6.0 + (CGFloat)i * 69.0, 246.0, 65.0, 30.0);
        pb.tag = (NSInteger)i;
        pb.backgroundColor = [UIColor colorWithRed:0.14 green:0.14 blue:0.30 alpha:0.95];
        pb.layer.cornerRadius = 7.0;
        pb.layer.borderWidth = 0.7;
        pb.layer.borderColor = [mm_neon_purple() colorWithAlphaComponent:0.45].CGColor;
        [pb setTitle:psn[i] forState:UIControlStateNormal];
        [pb setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        pb.titleLabel.font = [UIFont boldSystemFontOfSize:11.0];
        [pb addTarget:[MMTargets shared] action:@selector(onPreset:)
            forControlEvents:UIControlEventTouchUpInside];
        [g_p_misc addSubview:pb];
    }

    /* v0.4.3 (0.8): debug — prende el status file (modmenu_status.txt) para diagnosticar.
       Default OFF: sin esto no se escribe evidencia forense. */
    /* v0.6.1: boton de fila completa en lugar del UISwitch. El switch chico
       junto al borde no recibia el toque en algunos equipos; este boton
       comparte pagina con Guardar/Cargar, que si responden. */
    g_dbgbtn = [UIButton buttonWithType:UIButtonTypeCustom];
    g_dbgbtn.frame = CGRectMake(6.0, 286.0, 272.0, 34.0);
    g_dbgbtn.layer.cornerRadius = 8.0;
    g_dbgbtn.layer.borderWidth = 1.0;
    g_dbgbtn.layer.borderColor =
        [UIColor colorWithRed:0.55 green:0.85 blue:1.0 alpha:0.55].CGColor;
    g_dbgbtn.titleLabel.font = [UIFont boldSystemFontOfSize:12.5];
    [g_dbgbtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [g_dbgbtn addTarget:[MMTargets shared] action:@selector(onDebugToggle:)
        forControlEvents:UIControlEventTouchUpInside];
    [g_p_misc addSubview:g_dbgbtn];
    mm_refresh_debug_button();

    /* v0.6.1: volcado manual del status, sin depender de ningun toggle. */
    UIButton *stb = [UIButton buttonWithType:UIButtonTypeCustom];
    stb.frame = CGRectMake(6.0, 324.0, 272.0, 34.0);
    stb.backgroundColor = [UIColor colorWithRed:0.10 green:0.30 blue:0.52 alpha:0.95];
    stb.layer.cornerRadius = 8.0;
    stb.layer.borderWidth = 1.0;
    stb.layer.borderColor =
        [UIColor colorWithRed:0.55 green:0.85 blue:1.0 alpha:0.55].CGColor;
    [stb setTitle:mm_tr(@"Escribir status TXT ahora") forState:UIControlStateNormal];
    [stb setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    stb.titleLabel.font = [UIFont boldSystemFontOfSize:12.5];
    [stb addTarget:[MMTargets shared] action:@selector(onStatusNow:)
        forControlEvents:UIControlEventTouchUpInside];
    [g_p_misc addSubview:stb];

    /* v0.6.4: MISC paso a scroll (348 pt ya estaban llenos). */
    UIView *smr = mm_switch_row(@"Modo seguro (apaga overlay)", @"mm_safe_mode", NO);
    smr.frame = CGRectMake(0, 362.0, 284.0, 34.0);
    [g_p_misc addSubview:smr];

    UIView *qbr = mm_switch_row(@"Barra rapida (3 toggles)", @"mm_quickbar", NO);
    qbr.frame = CGRectMake(0, 396.0, 284.0, 34.0);
    [g_p_misc addSubview:qbr];

    UIView *hpr = mm_switch_row(@"Vibracion al tocar", @"mm_haptics", YES);
    hpr.frame = CGRectMake(0, 430.0, 284.0, 34.0);
    [g_p_misc addSubview:hpr];

    /* v0.7.0 (1.13/1.15): stream automatico y guard de captura. */
    UIView *asr = mm_switch_row(@"Stream auto al grabar", @"mm_auto_stream", YES);
    asr.frame = CGRectMake(0, 464.0, 284.0, 34.0);
    [g_p_misc addSubview:asr];

    UIView *gcr = mm_switch_row(@"Guard de captura (experimental)", @"mm_guard_capture", NO);
    gcr.frame = CGRectMake(0, 498.0, 284.0, 34.0);
    [g_p_misc addSubview:gcr];

    UILabel *lgl = [[UILabel alloc] initWithFrame:CGRectMake(6.0, 536.0, 272.0, 16.0)];
    lgl.text = mm_tr(@"Idioma (reiniciar)");
    lgl.textColor = [UIColor colorWithWhite:0.80 alpha:1.0];
    lgl.font = [UIFont systemFontOfSize:11.0];
    [g_p_misc addSubview:lgl];

    UISegmentedControl *lgs = [[UISegmentedControl alloc] initWithItems:@[@"ES", @"EN"]];
    lgs.frame = CGRectMake(6.0, 554.0, 272.0, 28.0);
    lgs.selectedSegmentIndex = (mm_lang() == 1) ? 1 : 0;
    if ([lgs respondsToSelector:@selector(setSelectedSegmentTintColor:)])
        lgs.selectedSegmentTintColor = [mm_neon_purple() colorWithAlphaComponent:0.85];
    [lgs setTitleTextAttributes:@{ NSForegroundColorAttributeName:
            [UIColor colorWithWhite:0.88 alpha:1.0],
            NSFontAttributeName: [UIFont systemFontOfSize:11.0] }
                       forState:UIControlStateNormal];
    [lgs setTitleTextAttributes:@{ NSForegroundColorAttributeName: [UIColor whiteColor],
            NSFontAttributeName: [UIFont systemFontOfSize:11.0] }
                       forState:UIControlStateSelected];
    [lgs addTarget:[MMTargets shared] action:@selector(onLang:)
        forControlEvents:UIControlEventValueChanged];
    [g_p_misc addSubview:lgs];

    UIButton *stf = [UIButton buttonWithType:UIButtonTypeCustom];
    stf.frame = CGRectMake(6.0, 592.0, 272.0, 34.0);
    stf.backgroundColor = [UIColor colorWithRed:0.12 green:0.34 blue:0.30 alpha:0.95];
    stf.layer.cornerRadius = 8.0;
    stf.layer.borderWidth = 1.0;
    stf.layer.borderColor =
        [mm_neon_green() colorWithAlphaComponent:0.55].CGColor;
    [stf setTitle:mm_tr(@"Auto-test del overlay") forState:UIControlStateNormal];
    [stf setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    stf.titleLabel.font = [UIFont boldSystemFontOfSize:12.5];
    [stf addTarget:[MMTargets shared] action:@selector(onSelfTest:)
        forControlEvents:UIControlEventTouchUpInside];
    [g_p_misc addSubview:stf];

    /* v0.7.0 (4.2): licencia in-menu sin red. */
    UILabel *licl = [[UILabel alloc] initWithFrame:CGRectMake(6.0, 634.0, 272.0, 16.0)];
    licl.text = mm_tr(@"Licencia (observacion)");
    licl.textColor = [UIColor colorWithRed:0.55 green:1.0 blue:0.66 alpha:1.0];
    licl.font = [UIFont boldSystemFontOfSize:12.0];
    [g_p_misc addSubview:licl];

    g_lic_label = [[UILabel alloc] initWithFrame:CGRectMake(6.0, 652.0, 272.0, 30.0)];
    g_lic_label.numberOfLines = 2;
    g_lic_label.textColor = [UIColor colorWithWhite:0.86 alpha:1.0];
    g_lic_label.font = [UIFont fontWithName:@"Menlo" size:9.0] ?:
                       [UIFont systemFontOfSize:9.0];
    g_lic_label.text = mm_lic_short_status();
    [g_p_misc addSubview:g_lic_label];

    UIButton *licp = [UIButton buttonWithType:UIButtonTypeCustom];
    licp.frame = CGRectMake(6.0, 686.0, 132.0, 30.0);
    licp.backgroundColor = [UIColor colorWithRed:0.10 green:0.28 blue:0.48 alpha:0.95];
    licp.layer.cornerRadius = 7.0;
    [licp setTitle:mm_tr(@"Pegar token") forState:UIControlStateNormal];
    [licp setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    licp.titleLabel.font = [UIFont boldSystemFontOfSize:11.0];
    [licp addTarget:[MMTargets shared] action:@selector(onLicensePaste)
        forControlEvents:UIControlEventTouchUpInside];
    [g_p_misc addSubview:licp];

    UIButton *licr = [UIButton buttonWithType:UIButtonTypeCustom];
    licr.frame = CGRectMake(146.0, 686.0, 132.0, 30.0);
    licr.backgroundColor = [UIColor colorWithWhite:0.12 alpha:0.95];
    licr.layer.cornerRadius = 7.0;
    [licr setTitle:mm_tr(@"Revalidar") forState:UIControlStateNormal];
    [licr setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    licr.titleLabel.font = [UIFont boldSystemFontOfSize:11.0];
    [licr addTarget:[MMTargets shared] action:@selector(onLicenseCheck)
        forControlEvents:UIControlEventTouchUpInside];
    [g_p_misc addSubview:licr];

    /* 4.8: telemetria local, opt-in y sin red. */
    UIView *usr = mm_switch_row(@"Telemetria local (opt-in)", @"mm_usage_optin", NO);
    usr.frame = CGRectMake(0, 722.0, 284.0, 34.0);
    [g_p_misc addSubview:usr];

    /* 1.19: marca de build derivada del HWID (opt-in). */
    UIView *bmr = mm_switch_row(@"Marca HWID en INFO (opt-in)", @"mm_build_mark", NO);
    bmr.frame = CGRectMake(0, 760.0, 284.0, 34.0);
    [g_p_misc addSubview:bmr];

    UIButton *cst = [UIButton buttonWithType:UIButtonTypeCustom];
    cst.frame = CGRectMake(6.0, 798.0, 272.0, 34.0);
    cst.backgroundColor = [UIColor colorWithWhite:0.12 alpha:0.95];
    cst.layer.cornerRadius = 8.0;
    cst.layer.borderWidth = 0.7;
    cst.layer.borderColor =
        [mm_neon_purple() colorWithAlphaComponent:0.45].CGColor;
    [cst setTitle:mm_tr(@"Copiar self-test") forState:UIControlStateNormal];
    [cst setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    cst.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
    [cst addTarget:[MMTargets shared] action:@selector(onSelfTestCopy)
        forControlEvents:UIControlEventTouchUpInside];
    [g_p_misc addSubview:cst];

    ((UIScrollView *)g_p_misc).contentSize = CGSizeMake(284.0, 846.0);

    /* --- pagina EXTRA (v0.4.0: features nuevas de overlay) --- */
    UILabel *xh = [[UILabel alloc] initWithFrame:CGRectMake(6.0, 2.0, 272.0, 18.0)];
    xh.text = @"OVERLAY";
    xh.textColor = [UIColor colorWithRed:0.55 green:1.0 blue:0.66 alpha:1.0];
    xh.font = [UIFont boldSystemFontOfSize:11.0];
    [g_p_more addSubview:xh];

    NSArray *xkeys = @[ @"mm_x_cross", @"mm_x_aimring", @"mm_x_head",
                        @"mm_x_distcol", @"mm_x_lowhp", @"mm_x_fps",
                        @"mm_x_priority", @"mm_x_warn", @"mm_x_arrow",
                        @"mm_x_radar", @"mm_x_height", @"mm_x_telem",
                        @"mm_x_bearings", @"mm_x_trails", @"mm_x_declutter",
                        @"mm_x_radar_cam", @"mm_x_targetlist" ];
    NSArray *xtit  = @[ @"Crosshair (mira)", @"Anillo de aim", @"Punto en la cabeza",
                        @"Color por distancia", @"Resaltar vida baja", @"Medidor de FPS",
                        @"Prioridad (mas cercano)", @"Aviso enemigo cerca",
                        @"Flecha fuera de pantalla (detras)",
                        @"Radar 2D", @"Indicador de altura", @"Telemetria",
                        @"Brujula de bearings", @"Estelas (ultimos 2 s)",
                        @"Anti-solape de etiquetas", @"Radar: arriba = mi vista",
                        @"Lista de objetivos" ];
    for (NSUInteger i = 0; i < xkeys.count; i++) {
        BOOL xdef = [xkeys[i] isEqualToString:@"mm_x_radar_cam"];   /* default ON */
        UIView *xrow = mm_switch_row(xtit[i], xkeys[i], xdef);
        xrow.frame = CGRectMake(0, 24.0 + (CGFloat)i * 31.0, 284.0, 31.0);
        [g_p_more addSubview:xrow];
    }

    CGFloat ry = 24.0 + (CGFloat)xkeys.count * 31.0 + 10.0;   /* bajo los toggles */

    /* v0.4.2: estilo de crosshair */
    UILabel *csl = [[UILabel alloc] initWithFrame:CGRectMake(6.0, ry, 272.0, 16.0)];
    csl.text = mm_tr(@"Estilo de crosshair");
    csl.textColor = [UIColor colorWithWhite:0.80 alpha:1.0];
    csl.font = [UIFont systemFontOfSize:11.0];
    [g_p_more addSubview:csl]; ry += 20.0;
    UISegmentedControl *css = [[UISegmentedControl alloc]
        initWithItems:@[mm_tr(@"Cruz"), mm_tr(@"Punto"), mm_tr(@"Circulo"), mm_tr(@"Todo")]];
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
    mnl.text = mm_tr(@"Limite de objetivos (0 = todos)");
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
    tl.text = mm_tr(@"Tema del menu");
    tl.textColor = [UIColor colorWithWhite:0.80 alpha:1.0];
    tl.font = [UIFont systemFontOfSize:11.0];
    [g_p_more addSubview:tl]; ry += 20.0;
    UISegmentedControl *tac = [[UISegmentedControl alloc]
        initWithItems:@[@"FUSION", mm_tr(@"Hielo"), mm_tr(@"Magenta"),
                        mm_tr(@"Fuego"), mm_tr(@"Aqua")]];
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

    /* v0.7.0 (1.16): paleta para daltonismo. */
    UILabel *cbl = [[UILabel alloc] initWithFrame:CGRectMake(6.0, ry, 272.0, 16.0)];
    cbl.text = mm_tr(@"Paleta daltonismo");
    cbl.textColor = [UIColor colorWithWhite:0.80 alpha:1.0];
    cbl.font = [UIFont systemFontOfSize:11.0];
    [g_p_more addSubview:cbl]; ry += 20.0;
    UISegmentedControl *cbs = [[UISegmentedControl alloc]
        initWithItems:@[mm_tr(@"Normal"), @"Protan/Deutan", @"Tritan"]];
    cbs.frame = CGRectMake(6.0, ry, 272.0, 28.0);
    cbs.selectedSegmentIndex = (g_cb_mode == 1) ? 1 : ((g_cb_mode == 3) ? 2 : 0);
    if ([cbs respondsToSelector:@selector(setSelectedSegmentTintColor:)])
        cbs.selectedSegmentTintColor = [mm_neon_purple() colorWithAlphaComponent:0.85];
    [cbs setTitleTextAttributes:@{ NSForegroundColorAttributeName:
            [UIColor colorWithWhite:0.88 alpha:1.0],
            NSFontAttributeName: [UIFont systemFontOfSize:10.0] }
                        forState:UIControlStateNormal];
    [cbs addTarget:[MMTargets shared] action:@selector(onColorMode:)
        forControlEvents:UIControlEventValueChanged];
    [g_p_more addSubview:cbs]; ry += 38.0;

    /* v0.7.0 (1.16): dos acentos personalizados (UIColorPickerViewController). */
    UIButton *acb = [UIButton buttonWithType:UIButtonTypeCustom];
    acb.frame = CGRectMake(6.0, ry, 132.0, 30.0);
    acb.tag = 0;
    acb.backgroundColor = [UIColor colorWithWhite:0.12 alpha:0.95];
    acb.layer.cornerRadius = 7.0;
    acb.layer.borderWidth = 0.7;
    acb.layer.borderColor = [mm_neon_purple() colorWithAlphaComponent:0.45].CGColor;
    [acb setTitle:mm_tr(@"Acento 1") forState:UIControlStateNormal];
    [acb setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    acb.titleLabel.font = [UIFont boldSystemFontOfSize:11.0];
    [acb addTarget:[MMTargets shared] action:@selector(onAccentPick:)
        forControlEvents:UIControlEventTouchUpInside];
    [g_p_more addSubview:acb];

    UIButton *ac2 = [UIButton buttonWithType:UIButtonTypeCustom];
    ac2.frame = CGRectMake(146.0, ry, 132.0, 30.0);
    ac2.tag = 1;
    ac2.backgroundColor = [UIColor colorWithWhite:0.12 alpha:0.95];
    ac2.layer.cornerRadius = 7.0;
    ac2.layer.borderWidth = 0.7;
    ac2.layer.borderColor = [mm_neon_purple() colorWithAlphaComponent:0.45].CGColor;
    [ac2 setTitle:mm_tr(@"Acento 2") forState:UIControlStateNormal];
    [ac2 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    ac2.titleLabel.font = [UIFont boldSystemFontOfSize:11.0];
    [ac2 addTarget:[MMTargets shared] action:@selector(onAccentPick:)
        forControlEvents:UIControlEventTouchUpInside];
    [g_p_more addSubview:ac2]; ry += 40.0;

    UILabel *thl = [[UILabel alloc] initWithFrame:CGRectMake(6.0, ry, 272.0, 16.0)];
    thl.text = mm_tr(@"Temas guardados");
    thl.textColor = [UIColor colorWithWhite:0.80 alpha:1.0];
    thl.font = [UIFont systemFontOfSize:11.0];
    [g_p_more addSubview:thl]; ry += 20.0;

    UISegmentedControl *ths = [[UISegmentedControl alloc]
        initWithItems:@[@"T1", @"T2", @"T3"]];
    ths.frame = CGRectMake(6.0, ry, 132.0, 28.0);
    ths.selectedSegmentIndex = 0;
    if ([ths respondsToSelector:@selector(setSelectedSegmentTintColor:)])
        ths.selectedSegmentTintColor = [mm_neon_purple() colorWithAlphaComponent:0.85];
    [ths addTarget:[MMTargets shared] action:@selector(onThemeSlot:)
        forControlEvents:UIControlEventValueChanged];
    [g_p_more addSubview:ths];

    UIButton *tsv = [UIButton buttonWithType:UIButtonTypeCustom];
    tsv.frame = CGRectMake(146.0, ry, 64.0, 28.0);
    tsv.backgroundColor = [UIColor colorWithRed:0.08 green:0.42 blue:0.20 alpha:0.95];
    tsv.layer.cornerRadius = 7.0;
    [tsv setTitle:mm_tr(@"Guardar") forState:UIControlStateNormal];
    [tsv setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    tsv.titleLabel.font = [UIFont boldSystemFontOfSize:10.5];
    [tsv addTarget:[MMTargets shared] action:@selector(onThemeSave)
        forControlEvents:UIControlEventTouchUpInside];
    [g_p_more addSubview:tsv];

    UIButton *tld = [UIButton buttonWithType:UIButtonTypeCustom];
    tld.frame = CGRectMake(214.0, ry, 64.0, 28.0);
    tld.backgroundColor = [UIColor colorWithRed:0.10 green:0.28 blue:0.48 alpha:0.95];
    tld.layer.cornerRadius = 7.0;
    [tld setTitle:mm_tr(@"Cargar") forState:UIControlStateNormal];
    [tld setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    tld.titleLabel.font = [UIFont boldSystemFontOfSize:10.5];
    [tld addTarget:[MMTargets shared] action:@selector(onThemeLoad)
        forControlEvents:UIControlEventTouchUpInside];
    [g_p_more addSubview:tld]; ry += 38.0;

    /* #11 opacidad del menu */
    UILabel *ol = [[UILabel alloc] initWithFrame:CGRectMake(6.0, ry, 272.0, 16.0)];
    ol.text = mm_tr(@"Opacidad del menu");
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
    scl.text = mm_tr(@"Escala del menu");
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
    NSArray *t2tit = @[ @"ESP de esqueleto",
                        @"ESP de granadas", @"ESP de loot / vehiculos",
                        @"Prediccion de proxima zona (BR)" ];
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
    mm_apply_safe_mode();   /* v0.6.4: arranca bloqueado si quedo en seguro */
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
        /* v0.7.0 (4.6): chips de self-check por capa. */
        {
            NSString *gv = NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"] ?: @"?";
            int sOff = ([gv isEqualToString:@FUSION_OFFSETS_VERSION] &&
                        VA_GAMEPLAY != 0 && VA_LOCALPAWN != 0 && VA_MAINCAM != 0) ? 1 : -1;
            int sEsp = (g_fp_state == 1) ? 1 : ((g_fp_state == 0) ? -1 : 0);
            int sNojb = (g_nojb_passes > 0) ? 1 : 0;
            int sLic = mm_lic_is_valid() ? 1 : 0;
            UIColor *cg = [UIColor colorWithRed:0.20 green:1.00 blue:0.58 alpha:1.0];
            UIColor *ca = [UIColor colorWithRed:1.00 green:0.72 blue:0.20 alpha:1.0];
            UIColor *cr = [UIColor colorWithRed:1.00 green:0.35 blue:0.35 alpha:1.0];
            UIFont *cf = [UIFont boldSystemFontOfSize:10.0];
#define MM_CHIP(nm, st) do { \
    UIColor *_c = ((st) == 1) ? cg : (((st) == 0) ? ca : cr); \
    [t appendAttributedString:[[NSAttributedString alloc] \
        initWithString:[NSString stringWithFormat:@"● %@  ", (nm)] \
            attributes:@{ NSFontAttributeName: cf, NSForegroundColorAttributeName: _c }]]; \
} while (0)
            MM_CHIP(@"offsets", sOff);
            MM_CHIP(@"ESP", sEsp);
            MM_CHIP(@"NoJB", sNojb);
            MM_CHIP(@"lic", sLic);
#undef MM_CHIP
            [t appendAttributedString:[[NSAttributedString alloc]
                initWithString:[NSString stringWithFormat:@"\npack %s · %s\n",
                                FUSION_PACK_VERSION, FUSION_EXPERIMENT_ID]
                    attributes:@{ NSFontAttributeName: verFont,
                                  NSForegroundColorAttributeName:
                                      [UIColor colorWithWhite:0.62 alpha:1.0] }]];
            if (mm_def_bool(@"mm_build_mark", NO)) {
                [t appendAttributedString:[[NSAttributedString alloc]
                    initWithString:[NSString stringWithFormat:@"marca %@\n", mm_build_mark()]
                        attributes:@{ NSFontAttributeName: verFont,
                                      NSForegroundColorAttributeName:
                                          [UIColor colorWithWhite:0.62 alpha:1.0] }]];
            }
            if (strcmp(FUSION_LATEST_PACK, FUSION_PACK_VERSION) != 0) {
                [t appendAttributedString:[[NSAttributedString alloc]
                    initWithString:[NSString stringWithFormat:@"ACTUALIZACION: pack %s disponible\n",
                                    FUSION_LATEST_PACK]
                        attributes:@{ NSFontAttributeName: cf,
                                      NSForegroundColorAttributeName: ca }]];
            }
            if (g_cfg_latest.length && ![g_cfg_latest isEqualToString:@FUSION_PACK_VERSION]) {
                [t appendAttributedString:[[NSAttributedString alloc]
                    initWithString:[NSString stringWithFormat:@"CONFIG: pack %@ disponible\n", g_cfg_latest]
                        attributes:@{ NSFontAttributeName: cf,
                                      NSForegroundColorAttributeName: ca }]];
            }
            [t appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
        }
        [t appendAttributedString:[[NSAttributedString alloc]
            initWithString:mm_tr(@"Aimbot no toggleable para mayor seguridad.\n\n")
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
        g_info.attributedText = t;
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
        if (g_br_probe == nil && mm_uptime() > 2.0) mm_br_probe_run();
        mm_refresh_info();

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
    g_t0 = [NSDate date].timeIntervalSinceReferenceDate;
    mm_boot_check();      /* 1.11: crash counter ANTES de tocar la UI */
    mm_cfg_load();        /* 4.1: remote config firmado (opt-in por archivo) */
    mm_reset_options();   /* v0.2.7: opciones a fabrica en cada arranque */
    g_cb_mode = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"mm_color_mode"];
    if (g_cb_mode != 1 && g_cb_mode != 3) g_cb_mode = 0;
    MM_LOG(@"%s dylib cargada v%s  path=%s  pid=%d (opciones reseteadas)",
          MM_TAG, MODMENU_VERSION, mm_my_path(), (int)getpid());
    mm_write_status(@"arranque (opciones a fabrica)");
    mm_lic_check();       /* v0.3.7: licencia (observacion; migra KeyGate) */
    mm_nojb_start();      /* v0.2.8: fase C (antidetect) en segundo plano */

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{ mm_tick(); });
}
