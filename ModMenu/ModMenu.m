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

#define MODMENU_VERSION     "0.8.2"
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
const char *modmenu_build_id = "modmenu-glass-0.8.2";

/* Fase C (ADR 0008): aim configurable via relay en cod.__DATA.
   El pack reemplaza el parche fijo del aim (0x1026FEC24) por un relay:
     adrp x8,#0x10dc63000 ; ldr s0,[x8,#0x9ec] ; ret
   es decir, GetAssitAimSpeed devuelve el float que vive en cod_base+0xDC639EC.
   Aca escribimos ese float (fuerza de aim, 0..28). Si la dylib no lo escribio
   todavia, el slot vale 0 -> aim apagado (fail-safe, nunca maximo). */
static float g_aim_strength = 28.0f;
static float g_aim_fov = 180.0f;
static float g_aim_smooth = 0.0f;   /* C-4: 0 = snap, 1 = suave */
static BOOL  g_aim_on = YES;
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
        (g_aim_key_mode && !g_aim_key_held) ? 0 : 1;
    *(float *)((uintptr_t)h + (uintptr_t)0x0DC639FCULL) = 1.0f - g_aim_smooth * 0.98f;
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
#define MM_SK_N 21   /* C-5: huesos del biped que se proyectan por caja */
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
    char    name[64];           /* v0.2.4: nombre UTF-8 del jugador     */
    CGPoint sk[MM_SK_N];        /* C-5: huesos proyectados (skeleton)   */
    uint32_t skMask;            /* bit i = hueso i proyectado           */
} MMEspBox;
static MMEspBox     g_boxes[MM_MAX_BOXES];
static int          g_box_count = 0;  /* cajas listas para pintar         */

/* --- C-5: skeleton ESP. Huesos del biped 3ds Max (Bip001*) que usa CODM.
   Se resuelven una vez por pawn con Transform.Find y se cachean; cada frame
   solo se pide la posicion mundial de cada Transform cacheado. --- */
static const char *mm_sk_path[MM_SK_N] = {
    "Bip001 Pelvis", "Bip001 Spine", "Bip001 Spine1", "Bip001 Spine2", "Bip001 Spine3",
    "Bip001 Neck", "Bip001 Head",
    "Bip001 L Clavicle", "Bip001 L UpperArm", "Bip001 L Forearm", "Bip001 L Hand",
    "Bip001 R Clavicle", "Bip001 R UpperArm", "Bip001 R Forearm", "Bip001 R Hand",
    "Bip001 L Thigh", "Bip001 L Calf", "Bip001 L Foot",
    "Bip001 R Thigh", "Bip001 R Calf", "Bip001 R Foot"
};
static const char *mm_sk_suffix[MM_SK_N] = {
    " Pelvis", " Spine", " Spine1", " Spine2", " Spine3",
    " Neck", " Head",
    " L Clavicle", " L UpperArm", " L Forearm", " L Hand",
    " R Clavicle", " R UpperArm", " R Forearm", " R Hand",
    " L Thigh", " L Calf", " L Foot",
    " R Thigh", " R Calf", " R Foot"
};
static const int mm_sk_link[][2] = {
    {0,1},{1,2},{2,3},{3,4},{4,5},{5,6},        /* pelvis -> spine -> cabeza */
    {4,7},{7,8},{8,9},{9,10},                   /* pecho -> brazo izq        */
    {4,11},{11,12},{12,13},{13,14},             /* pecho -> brazo der        */
    {0,15},{15,16},{16,17},                     /* pelvis -> pierna izq      */
    {0,18},{18,19},{19,20}                      /* pelvis -> pierna der      */
};
#define MM_SK_LINKS ((int)(sizeof(mm_sk_link) / sizeof(mm_sk_link[0])))
typedef struct {
    uint64_t pawn;
    uint64_t root;
    void    *bn[MM_SK_N];
    CGPoint  pts[MM_SK_N];   /* C-5c: puntos cacheados (throttle ~10 Hz) */
    uint32_t mask;
    double   lastTry;    /* C-5d: throttle de reintento     */
    int      ok;
} MMSkelCache;
static MMSkelCache  g_skel_cache[MM_MAX_BOXES];
static int          g_skel_budget = 1;   /* C-15: resoluciones por pasada */
typedef void *(*MMFindFn)(void *transform, void *nsstring);
typedef void  (*MMPosFn)(void *transform, float out[3]);
static MMFindFn     g_fp_find  = NULL;
static MMPosFn      g_fp_trpos = NULL;
typedef void (*MMSetFovFn)(void *cam, float v);
static MMSetFovFn   g_fp_cam_setfov = NULL;
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
static void       *(*g_br_pawn_fn)(void) = NULL;

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
static void mm_bones_dump(void);       /* C-16: dump de jerarquia de huesos */
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
    BOOL master, safe_mode;             /* perf: snapshot de los gates por-frame */
    BOOL skeleton;                      /* C-5: esqueleto del biped */
    BOOL fovCircle;                     /* C-11: circulo del FOV de aim */
    BOOL ignoreDown;                    /* C-17: no asistir a enemigos caidos */
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
    o->skeleton  = mm_def_bool(@"mm_x_skel", NO);
    o->fovCircle = mm_def_bool(@"mm_x_fov_circle", NO);
    o->ignoreDown = mm_def_bool(@"mm_x_ignore_down", NO);
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
        if (tk->robot) { colR = 0.63; colG = 0.30; colB = 1.0; }
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

        /* C-15: huesos REALES si el walk los encontro. */
        if (o->skeleton && b->skMask != 0) {
            CGContextSaveGState(ctx);
            CGContextSetShadowWithColor(ctx, CGSizeZero, 3.0,
                [UIColor colorWithRed:cr green:cg blue:cb alpha:0.55].CGColor);
            CGContextSetLineWidth(ctx, 1.3);
            CGContextSetLineCap(ctx, kCGLineCapRound);
            CGContextSetRGBStrokeColor(ctx, cr, cg, cb, 0.90);
            CGContextBeginPath(ctx);
            for (int l = 0; l < MM_SK_LINKS; l++) {
                int i0 = mm_sk_link[l][0], i1 = mm_sk_link[l][1];
                if (!(b->skMask & (1u << i0)) || !(b->skMask & (1u << i1))) continue;
                CGContextMoveToPoint(ctx, b->sk[i0].x, b->sk[i0].y);
                CGContextAddLineToPoint(ctx, b->sk[i1].x, b->sk[i1].y);
            }
            CGContextStrokePath(ctx);
            if (b->skMask & (1u << 6)) {
                CGFloat hr = MAX(1.6, r.size.height * 0.018);
                CGContextStrokeEllipseInRect(ctx,
                    CGRectMake(b->sk[6].x - hr, b->sk[6].y - hr, hr * 2.0, hr * 2.0));
            }
            CGContextRestoreGState(ctx);
        } else if (o->skeleton && r.size.height > 8.0 && r.size.width > 2.0) {
        /* C-12: esqueleto PROCEDURAL (fallback). SP3CTERIOS no resuelve la cadena de
           huesos (usa PickAimPoint + BoneCandidate con offsets del pawn);
           replicamos esa idea: figura de palos proporcional a la caja. Cero
           lecturas nuevas, cero riesgo de freeze. */
        if (o->skeleton && r.size.height > 8.0 && r.size.width > 2.0) {
            CGFloat fx = CGRectGetMidX(r);
            CGFloat ty = r.origin.y, hh = r.size.height, ww = r.size.width;
            CGFloat sh = ww * 0.34;                 /* media apertura de hombros */
            CGPoint pHead = CGPointMake(fx, ty + hh * 0.07);
            CGPoint pNeck = CGPointMake(fx, ty + hh * 0.14);
            CGPoint pChest = CGPointMake(fx, ty + hh * 0.31);
            CGPoint pHip = CGPointMake(fx, ty + hh * 0.52);
            CGPoint pLSh = CGPointMake(fx - sh, ty + hh * 0.20);
            CGPoint pRSh = CGPointMake(fx + sh, ty + hh * 0.20);
            CGPoint pLEl = CGPointMake(fx - sh * 1.18, ty + hh * 0.41);
            CGPoint pREl = CGPointMake(fx + sh * 1.18, ty + hh * 0.41);
            CGPoint pLHa = CGPointMake(fx - sh * 1.10, ty + hh * 0.60);
            CGPoint pRHa = CGPointMake(fx + sh * 1.10, ty + hh * 0.60);
            CGPoint pLKn = CGPointMake(fx - sh * 0.62, ty + hh * 0.76);
            CGPoint pRKn = CGPointMake(fx + sh * 0.62, ty + hh * 0.76);
            CGPoint pLFe = CGPointMake(fx - sh * 0.62, ty + hh * 0.99);
            CGPoint pRFe = CGPointMake(fx + sh * 0.62, ty + hh * 0.99);
            CGPoint seg[][4] = {
                { pNeck, pChest, pChest, pHip },     /* tronco */
                { pChest, pLSh, pChest, pRSh },      /* hombros */
                { pLSh, pLEl, pLEl, pLHa },          /* brazo izq */
                { pRSh, pREl, pREl, pRHa },          /* brazo der */
                { pHip, pLKn, pLKn, pLFe },          /* pierna izq */
                { pHip, pRKn, pRKn, pRFe },          /* pierna der */
                { pNeck, pHead, pHead, pHead }       /* cuello */
            };
            CGContextSaveGState(ctx);
            CGContextSetShadowWithColor(ctx, CGSizeZero, 3.0,
                [UIColor colorWithRed:cr green:cg blue:cb alpha:0.55].CGColor);
            CGContextSetLineWidth(ctx, 1.2);
            CGContextSetLineCap(ctx, kCGLineCapRound);
            CGContextSetRGBStrokeColor(ctx, cr, cg, cb, 0.85);
            CGContextBeginPath(ctx);
            for (int k = 0; k < (int)(sizeof(seg) / sizeof(seg[0])); k++) {
                CGContextMoveToPoint(ctx, seg[k][0].x, seg[k][0].y);
                CGContextAddLineToPoint(ctx, seg[k][1].x, seg[k][1].y);
                CGContextMoveToPoint(ctx, seg[k][2].x, seg[k][2].y);
                CGContextAddLineToPoint(ctx, seg[k][3].x, seg[k][3].y);
            }
            CGContextStrokePath(ctx);
            /* cabeza: circulo */
            CGFloat hr = MAX(2.0, hh * 0.045);
            CGContextStrokeEllipseInRect(ctx, CGRectMake(pHead.x - hr, pHead.y - hr,
                                                         hr * 2.0, hr * 2.0));
            CGContextRestoreGState(ctx);
        }
        }   /* cierra el else-if del skeleton (C-15) */

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
    if (g_p_vis   != nil) g_p_vis.hidden   = (i != 1);
    if (g_p_misc  != nil) g_p_misc.hidden  = (i != 2);
    if (g_p_info  != nil) g_p_info.hidden  = (i != 3);
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
    if ([k isEqualToString:@"mm_x_skel"] && s.on) mm_bones_dump();   /* C-16 */
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
    /* v0.7.5: fuerza una pasada fresca del probe BR antes de escribir
       status. Asi si el operador toca el boton durante el shrink, el
       status.txt y el br_probe.txt reflejan el BRMgr vivo (la instancia
       resuelta). Si el singleton sigue en 0, el intento es barato (lee
       bytes del binario, nunca llama al juego). */
    mm_br_probe_run();
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

/* v0.7.3 (br probe v2): ventana 16 -> 32 instrucciones. il2cpp a menudo
   inserta antes del store real una comprobacion de init de metadata que
   puede ocupar 4-8 ins (adrp + ldr + cbnz/tbnz + bl _il2cpp_init). El
   escaneo lineal sigue siendo seguro: solo recoge STR [X0,#imm] cuando
   Rt es w1/x1/s1/d1 (arg1 del setter); cualquier otra ins se ignora. Si
   no se encuentra nada, el probe vuelca los 32 words en hex (ver abajo). */
#define MM_BR_DECODE_WINDOW 32
static int mm_br_decode_setter(uint64_t va_rt, mm_br_decode_t *d)
{
    memset(d, 0, sizeof(*d));
    const uint32_t *ins = (const uint32_t *)(uintptr_t)va_rt;
    for (int i = 0; i < MM_BR_DECODE_WINDOW; i++) {
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
            for (int j = i + 1; j < i + 8 && j < MM_BR_DECODE_WINDOW; j++) {
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
            for (int j = i + 1; j < MM_BR_DECODE_WINDOW; j++) {
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

/* v0.7.3 (br probe v2): fallback hex dump de 32 instrucciones (128 B) desde
   el VA del setter. Se usa cuando el decoder lineal NO reconoce el patron,
   para parsear a mano el prologo real (ej. il2cpp con init de metadata).
   Devuelve "hex=aabbccdd,..." con 32 words little-endian. Sin saltos de
   linea: todo cabe en la misma linea del setter en br_probe.txt. */
static NSString *mm_br_hex_dump32(uint64_t va_rt)
{
    const uint32_t *ins = (const uint32_t *)(uintptr_t)va_rt;
    NSMutableString *h = [NSMutableString stringWithCapacity:32 * 9 + 8];
    [h appendString:@"hex="];
    for (int i = 0; i < 32; i++) {
        if (i > 0) [h appendString:@","];
        [h appendFormat:@"%08x", (unsigned)ins[i]];
    }
    return h;
}

/* v0.7.4 (br probe v3): decodifica `b imm26` (branch unconditional, sin
   link) y devuelve el target absoluto en el espacio runtime. Retorna 1 si
   la instruccion es un b imm26, 0 si no. */
static int mm_br_decode_b_imm26(uint32_t ins, uint64_t pc, uint64_t *target)
{
    if ((ins & 0xFC000000u) != 0x14000000u) return 0;
    int64_t imm26 = (int64_t)(ins & 0x03FFFFFFu);
    if (imm26 & (1LL << 25)) imm26 |= ~((1LL << 26) - 1);
    *target = pc + imm26 * 4;
    return 1;
}

/* v0.7.4 (br probe v3): busca el ULTIMO `b imm26` dentro de la ventana del
   setter (tail-call de forwarders tipo set_Radius / set_TotalSpr). Retorna
   1 si lo encontro, con *target_rt listo para dumpear 32 words mas. */
static int mm_br_find_tail_target(uint64_t va_rt, uint64_t *target_rt)
{
    const uint32_t *ins = (const uint32_t *)(uintptr_t)va_rt;
    int found = 0; uint64_t last_tgt = 0;
    for (int i = 0; i < MM_BR_DECODE_WINDOW; i++) {
        uint64_t pc = va_rt + (uint64_t)i * 4;
        uint64_t t;
        if (mm_br_decode_b_imm26(ins[i], pc, &t)) { found = 1; last_tgt = t; }
        if (ins[i] == 0xD65F03C0) break; /* RET corta el escaneo */
    }
    if (!found) return 0;
    *target_rt = last_tgt;
    return 1;
}

/* v0.7.4 (br probe v3): busca el PRIMER slot estatico 64-bit cargado por un
   patron `adrp Rd,page [; add Rd,Rd,#imm12] ; ldr Xt,[Rd,#imm12*8]` dentro
   de la ventana. Deref: devuelve el VALOR almacenado en ese slot (puntero a
   la instancia singleton del game-mode). 0 si no hay match o la deref falla.
   v0.7.7: ademas devuelve en *slot_rt la direccion runtime del slot (para
   que el probe emita la file-space VA que fusion br promote necesita como
   mgr_va). Pasa NULL si no te interesa. */
static uint64_t mm_br_resolve_singleton_ex(uint64_t va_rt, uint64_t *slot_rt_out)
{
    const uint32_t *ins = (const uint32_t *)(uintptr_t)va_rt;
    for (int i = 0; i < MM_BR_DECODE_WINDOW; i++) {
        uint32_t w = ins[i];
        if ((w & 0x9F000000u) != 0x90000000u) continue;    /* ADRP */
        uint32_t Rd = w & 0x1F;
        int64_t immlo = (w >> 29) & 3;
        int64_t immhi = (w >> 5) & 0x7FFFF;
        int64_t imm = (immhi << 2) | immlo;
        if (imm & (1LL << 20)) imm |= ~((1LL << 21) - 1);
        imm <<= 12;
        uint64_t pc = va_rt + (uint64_t)i * 4;
        uint64_t page = (pc & ~0xFFFULL) + (uint64_t)imm;
        uint64_t base = page; int has_add = 0;
        for (int j = i + 1; j < i + 5 && j < MM_BR_DECODE_WINDOW; j++) {
            uint32_t w2 = ins[j];
            /* ADD Xd, Xn, #imm12 (64-bit, con sh opcional) */
            if ((w2 & 0xFF800000u) == 0x91000000u) {
                uint32_t Rn2 = (w2 >> 5) & 0x1F;
                uint32_t Rd2 = w2 & 0x1F;
                uint32_t imm12 = (w2 >> 10) & 0xFFF;
                uint32_t sh = (w2 >> 22) & 1;
                if (Rn2 == Rd && Rd2 == Rd) {
                    base = page + ((uint64_t)imm12 << (sh ? 12 : 0));
                    has_add = 1;
                }
                continue;
            }
            /* LDR Xt, [Xn, #imm12*8] 64-bit unsigned offset */
            if ((w2 & 0xFFC00000u) == 0xF9400000u) {
                uint32_t Rn2 = (w2 >> 5) & 0x1F;
                uint32_t imm12 = (w2 >> 10) & 0xFFF;
                if (Rn2 == Rd) {
                    uint64_t slot = (has_add ? base : page) + (uint64_t)imm12 * 8;
                    if (slot_rt_out) *slot_rt_out = slot;
                    BOOL ok = NO;
                    uint64_t ptr = mm_safe_read64((uintptr_t)slot, &ok);
                    if (ok && ptr != 0) return ptr;
                    return 0;
                }
            }
        }
    }
    if (slot_rt_out) *slot_rt_out = 0;
    return 0;
}

/* v0.7.4: wrapper original (sin slot_rt) para que compile el camino viejo. */
static uint64_t mm_br_resolve_singleton(uint64_t va_rt)
{
    return mm_br_resolve_singleton_ex(va_rt, NULL);
}

/* v0.7.8 (br probe v5) + v0.7.9 + v0.7.11: scan Vec3 estricto.
   v0.7.10 trajo muchos falsos positivos (metadata il2cpp con bytes que
   interpretan a floats: "mDOC"=207.3, strings de nombres de clase).
   v0.7.11 endurece: (a) al menos DOS ejes con mag >= 1 (filtra float
   aislado con dos ceros alrededor como el "mDOC"), (b) radio candidato
   finito, positivo, en [10, 5000] (BR radii tipicos 50-2500m): eso
   descarta "r=nan", "r=huge", "r=0" que delataban falsos. */
static int mm_br_scan_vec3(NSMutableString *s, const char *tag,
                           const uint32_t *buf, int nwords, uintptr_t src)
{
    int hits = 0;
    for (int i = 0; i <= nwords - 4; i++) {   /* -4: tambien leemos radio */
        float x, y, z, r;
        memcpy(&x, buf + i,     sizeof(float));
        memcpy(&y, buf + i + 1, sizeof(float));
        memcpy(&z, buf + i + 2, sizeof(float));
        memcpy(&r, buf + i + 3, sizeof(float));
        if (!isfinite(x) || !isfinite(y) || !isfinite(z) || !isfinite(r)) continue;
        float ax = fabsf(x), ay = fabsf(y), az = fabsf(z);
        if (ax > 10000.f || ay > 10000.f || az > 10000.f) continue;
        /* al menos DOS ejes con magnitud >= 1 (filtra float aislado) */
        int nz = (ax >= 1.0f) + (ay >= 1.0f) + (az >= 1.0f);
        if (nz < 2) continue;
        /* radio: finito, positivo, 10..5000 (BR map scale) */
        if (r < 10.0f || r > 5000.0f) continue;
        [s appendFormat:@" | vec3@%s+0x%X=(%.1f,%.1f,%.1f) r=%.1f src=0x%llX",
             tag, i * 4, (double)x, (double)y, (double)z, (double)r,
             (unsigned long long)src];
        hits++;
        if (hits >= 4) break;    /* capeo por region para no inflar la linea */
    }
    return hits;
}

/* v0.7.10: estado de la app al momento del probe. Si durante el usleep
   de 500 ms la app pasa a background, iOS pausa las writes de memoria
   del juego y el snapshot B queda IDENTICO al A -> diff=none falso.
   Retorna: 0=Active, 1=Inactive, 2=Background, -1=na, -2=error. */
static int mm_br_app_state(void)
{
    @try {
        UIApplication *app = [UIApplication sharedApplication];
        if (!app) return -1;
        return (int)app.applicationState;
    } @catch (NSException *e) {
        return -2;
    }
}

/* v0.7.7 (br probe v4) + v0.7.8 + v0.7.10: dos snapshots de 128 words
   (512 B), espaciados por 500 ms. Emite:
     inst=0xADDR app=A>B hex=<128 words> diff=+0xOFF:oldval->newval,...
   v0.7.10: `app=A>B` = applicationState de iOS antes/despues del
   snapshot (0=Active, 1=Inactive, 2=Background, -1=na). Si cualquiera
   no es Active, el diff se marca `skip_bg` (iOS paus las writes del
   juego -> diff falso) y g_br_probe_saw_diff NO se setea (seguimos
   reintentando hasta capturar una pasada con la app en foreground). */
static NSString *mm_br_dump_dynamic(NSMutableString *vec3_out,
                                    const char *tag, uintptr_t inst)
{
    if (inst == 0) return @"inst=0x0";
    int app_a = mm_br_app_state();
    uint32_t snap_a[128], snap_b[128];
    vm_size_t got = 0;
    g_vm_reads++;
    if (vm_read_overwrite(mach_task_self(), (vm_address_t)inst,
                          sizeof(snap_a), (vm_address_t)snap_a,
                          &got) != KERN_SUCCESS ||
        got != sizeof(snap_a)) {
        return [NSString stringWithFormat:@"inst=0x%llX unreadable",
                (unsigned long long)inst];
    }
    usleep(500000);   /* 0.5 s: tiempo tipico para ver cambio durante shrink */
    int app_b = mm_br_app_state();
    g_vm_reads++;
    if (vm_read_overwrite(mach_task_self(), (vm_address_t)inst,
                          sizeof(snap_b), (vm_address_t)snap_b,
                          &got) != KERN_SUCCESS ||
        got != sizeof(snap_b)) {
        return [NSString stringWithFormat:@"inst=0x%llX unreadable2",
                (unsigned long long)inst];
    }
    int bg = (app_a != 0 || app_b != 0);
    NSMutableString *h = [NSMutableString stringWithCapacity:128 * 10 + 512];
    [h appendFormat:@"inst=0x%llX app=%d>%d hex=",
         (unsigned long long)inst, app_a, app_b];
    for (int i = 0; i < 128; i++) {
        if (i > 0) [h appendString:@","];
        [h appendFormat:@"%08x", (unsigned)snap_b[i]];
    }
    [h appendString:@" diff="];
    int ndiff = 0;
    for (int i = 0; i < 128; i++) {
        if (snap_a[i] != snap_b[i]) {
            if (ndiff > 0) [h appendString:@","];
            [h appendFormat:@"+0x%X:%08x>%08x", i * 4,
                 (unsigned)snap_a[i], (unsigned)snap_b[i]];
            ndiff++;
            if (ndiff >= 24) { [h appendString:@",..."]; break; }
        }
    }
    if (ndiff == 0) {
        [h appendString:bg ? @"none(skip_bg)" : @"none"];
    } else {
        if (!bg) g_br_probe_saw_diff = 1;
        else     [h appendString:@" (skip_bg)"];
    }
    /* v0.7.8: scan Vec3 sobre snap B (ya reflejado en inst) */
    if (vec3_out)
        g_br_probe_found_vec3 += mm_br_scan_vec3(vec3_out, tag, snap_b, 128, inst);
    return h;
}

/* v0.7.10: walk de 32 pointer-slots en [0..0xF8] de la instancia.
   - Hijos: 16 (como v0.7.9). Dump 128 words (512 B) por hijo (antes 64,
     256 B) - alcanza mas profundo donde pueda estar el Vec3.
   - Alineacion: 2-byte (`p & 0x1`). Mono/il2cpp usa a veces low-bit tags;
     v0.7.8 (8-byte) y v0.7.9 (4-byte) rechazaban 0x123C90E4E (low 0x4E).
   - Deref: si el deref del ptr exacto falla, retry con bits 2-0 limpios
     (0x123C90E4E -> 0x123C90E48) por si es tagged pointer. Emito
     `tag=0xN` cuando la deref untagged tuvo exito. */
static void mm_br_walk_pointers(NSMutableString *s, NSMutableString *vec3_out,
                                const char *tag, uintptr_t inst)
{
    if (inst == 0) return;
    uint64_t ptrs[32];
    vm_size_t got = 0;
    g_vm_reads++;
    if (vm_read_overwrite(mach_task_self(), (vm_address_t)inst, sizeof(ptrs),
                          (vm_address_t)ptrs, &got) != KERN_SUCCESS ||
        got != sizeof(ptrs))
        return;
    int n = 0;
    for (int i = 0; i < 32 && n < 16; i++) {
        uint64_t p = ptrs[i];
        if (p < 0x100000000ULL || p > 0x300000000ULL) continue; /* heuristico */
        if (p & 0x1ULL) continue;                               /* alineado 2 */
        if (p == (uint64_t)inst) continue;                      /* auto-ptr */
        uint32_t sub[128];
        g_vm_reads++;
        uint64_t deref_at = p;
        int tag_bits = 0;
        kern_return_t kr = vm_read_overwrite(mach_task_self(),
                                             (vm_address_t)p, sizeof(sub),
                                             (vm_address_t)sub, &got);
        if ((kr != KERN_SUCCESS || got != sizeof(sub)) && (p & 0x7ULL)) {
            /* Retry con low 3 bits limpios: posible tagged pointer. */
            deref_at = p & ~0x7ULL;
            tag_bits = (int)(p & 0x7ULL);
            g_vm_reads++;
            kr = vm_read_overwrite(mach_task_self(), (vm_address_t)deref_at,
                                   sizeof(sub), (vm_address_t)sub, &got);
        }
        if (kr != KERN_SUCCESS || got != sizeof(sub)) continue;
        [s appendFormat:@" | %s_child_%d@+0x%X=0x%llX",
             tag, n, i * 8, (unsigned long long)p];
        if (tag_bits) [s appendFormat:@" tag=0x%x", tag_bits];
        [s appendString:@" hex="];
        for (int j = 0; j < 128; j++) {
            if (j > 0) [s appendString:@","];
            [s appendFormat:@"%08x", (unsigned)sub[j]];
        }
        /* v0.7.8: scan Vec3 sobre el hijo. v0.7.10: 128 words (512 B). */
        if (vec3_out) {
            char subtag[32];
            snprintf(subtag, sizeof(subtag), "%s_c%d", tag, n);
            g_br_probe_found_vec3 += mm_br_scan_vec3(vec3_out, subtag, sub, 128, (uintptr_t)deref_at);
        }
        n++;
    }
}

/* v0.7.11: dump del pawn local y walk de sus punteros. Los dumps v0.7.5-10
   revelaron que `R:slot_file_va=0x10D91A0C0` apunta a TYPE METADATA
   (`Il2CppClass*` o similar) y no a la SafeZone. La SafeZone real pasa
   como `x0` al set_Radius desde codigo del juego, nunca por un static.
   Pero el pawn SI es alcanzable via `g_br_pawn_fn` (ya se llama desde
   el colector ESP, sin ACE adicional); el pawn tiene referencias a su
   match/gamemode -> SafeZone list. Dumpeamos 128 words del pawn + walk
   de 32 slots (16 hijos) con scan Vec3. */
static void mm_br_dump_pawn(NSMutableString *s, NSMutableString *vec3_out)
{
    if (!g_br_pawn_fn) {
        [s appendString:@" | pawn=unresolved"];
        return;
    }
    void *p = NULL;
    @try { p = g_br_pawn_fn(); } @catch (NSException *e) { p = NULL; }
    if (!p) {
        [s appendString:@" | pawn=null"];
        return;
    }
    uint32_t pbuf[128];
    vm_size_t got = 0;
    g_vm_reads++;
    if (vm_read_overwrite(mach_task_self(), (vm_address_t)(uintptr_t)p,
                          sizeof(pbuf), (vm_address_t)pbuf, &got) != KERN_SUCCESS ||
        got != sizeof(pbuf)) {
        [s appendFormat:@" | pawn=0x%llX unreadable", (unsigned long long)(uintptr_t)p];
        return;
    }
    [s appendFormat:@" | pawn=0x%llX hex=", (unsigned long long)(uintptr_t)p];
    for (int i = 0; i < 128; i++) {
        if (i > 0) [s appendString:@","];
        [s appendFormat:@"%08x", (unsigned)pbuf[i]];
    }
    if (vec3_out)
        g_br_probe_found_vec3 += mm_br_scan_vec3(vec3_out, "P", pbuf, 128, (uintptr_t)p);
    mm_br_walk_pointers(s, vec3_out, "P", (uintptr_t)p);
}

/* v0.7.4 (br probe v3): dump de N palabras de 32 bits desde una direccion
   arbitraria usando vm_read_overwrite. Si la pagina no es legible devuelve
   "hex=unreadable" en vez de crashear. N <= 64 (256 B). */
static NSString *mm_br_hex_dump_at(uintptr_t addr, int words)
{
    if (words > 64) words = 64;
    if (words <= 0) return @"hex=empty";
    uint32_t buf[64];
    vm_size_t got = 0;
    g_vm_reads++;
    kern_return_t kr = vm_read_overwrite(mach_task_self(),
                                         (vm_address_t)addr,
                                         (vm_size_t)(words * 4),
                                         (vm_address_t)buf,
                                         &got);
    if (kr != KERN_SUCCESS || got != (vm_size_t)(words * 4)) {
        return @"hex=unreadable";
    }
    NSMutableString *h = [NSMutableString stringWithCapacity:(NSUInteger)words * 9 + 8];
    [h appendString:@"hex="];
    for (int i = 0; i < words; i++) {
        if (i > 0) [h appendString:@","];
        [h appendFormat:@"%08x", (unsigned)buf[i]];
    }
    return h;
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

        /* v0.7.9: estado de match embebido en la primera palabra - al leer
           br_probe.txt veo al toque si la pasada se hizo en menu/lobby
           (trk=0 have_local=0) o en gameplay con enemigos cerca. Si todo
           esta en 0 la geometria del zone no va a aparecer: hay que entrar
           a BR y repetir. */
        NSMutableString *s = [NSMutableString stringWithFormat:
            @"base=0x%lX trk=%d have_local=%d",
            (unsigned long)base, g_track_count, g_have_local];
        /* v0.7.7 (br probe v4): los prologos de los 8 setters ya los tengo del
           volcado de v0.7.4; aqui solo listo nombre+VA para que la linea
           quede autodescriptiva. El decoder de v0.7.3 queda vivo solo por si
           alguno llegara a matchear como setter directo (set_X=off=...). */
        uint64_t rt_radius = 0, rt_shape = 0;
        for (int i = 0; i < N; i++) {
            uint64_t rt = base + (uintptr_t)(setters[i].va - FUSION_IMAGE_BASE);
            if (strcmp(setters[i].name, "set_Radius") == 0) rt_radius = rt;
            if (strcmp(setters[i].name, "set_Shape")  == 0) rt_shape  = rt;
            mm_br_decode_t d;
            if (!mm_br_decode_setter(rt, &d) || !d.found) {
                /* Solo nombre+VA, sin los 32 words de hex (ya los tenemos del
                   dump v0.7.4; ahorramos ~2 KB de linea por iteracion). */
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
        /* v0.7.7 (br probe v4): captura exhaustiva. Para cada setter con
           singleton:
             (1) resolve_singleton_ex: puntero a la instancia + runtime slot;
             (2) emite slot_file_va (lo que mgr_va del contrato espera);
             (3) dump dinamico 128 words + diff de las palabras que cambiaron
                 entre dos snapshots a 500 ms (deberia revelar los floats del
                 centro + radio durante shrink activo);
             (4) walk de 16 pointer-slots en [0..0x80], deref + 32 words por
                 hijo (hasta 8 hijos) -> encuentra la SafeZone hija donde
                 vive el Vec3 (chase de set_Radius escribe `stur q0,[x19,+0xB8]`,
                 x19 = SafeZone pasado por el llamador, no por el static). */
        /* v0.7.8: acumulador de candidatos Vec3; se adjunta al final para
           que todos los `vec3@...` queden juntos y faciles de leer. */
        NSMutableString *vec3_out = [NSMutableString stringWithCapacity:1024];
        int got_inst = 0;
        if (rt_radius) {
            uint64_t slot_rt = 0;
            uint64_t inst = mm_br_resolve_singleton_ex(rt_radius, &slot_rt);
            uint64_t slot_file_va = (slot_rt && slot_rt >= (uint64_t)base)
                ? ((uint64_t)FUSION_IMAGE_BASE + (slot_rt - (uint64_t)base)) : 0;
            [s appendFormat:@" | R:slot_file_va=0x%llX slot_rt=0x%llX %@",
                 (unsigned long long)slot_file_va,
                 (unsigned long long)slot_rt,
                 mm_br_dump_dynamic(vec3_out, "R", (uintptr_t)inst)];
            if (inst) {
                got_inst = 1;
                mm_br_walk_pointers(s, vec3_out, "R", (uintptr_t)inst);
            }
        }
        if (rt_shape) {
            uint64_t slot_rt = 0;
            uint64_t inst = mm_br_resolve_singleton_ex(rt_shape, &slot_rt);
            uint64_t slot_file_va = (slot_rt && slot_rt >= (uint64_t)base)
                ? ((uint64_t)FUSION_IMAGE_BASE + (slot_rt - (uint64_t)base)) : 0;
            [s appendFormat:@" | S:slot_file_va=0x%llX slot_rt=0x%llX %@",
                 (unsigned long long)slot_file_va,
                 (unsigned long long)slot_rt,
                 mm_br_dump_dynamic(vec3_out, "S", (uintptr_t)inst)];
            if (inst) {
                got_inst = 1;
                mm_br_walk_pointers(s, vec3_out, "S", (uintptr_t)inst);
            }
        }
        /* v0.7.11: ademas del R/S que resuelven a metadata, dumpea el
           pawn local (via g_br_pawn_fn) y walk sus punteros. El pawn
           tiene referencias a su gamemode/match -> SafeZone list, que
           ningun static expone. */
        mm_br_dump_pawn(s, vec3_out);
        /* v0.7.8: pego los candidatos Vec3 al final de la linea. */
        if (vec3_out.length > 0) [s appendString:vec3_out];
        g_br_probe_got_inst = got_inst;
        g_br_probe_last_run = mm_uptime();
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
#define BR_DMZ_SHAPE   0x3F4
#define BR_DMZ_CENTER  0x3F8
#define BR_DMZ_RADIUS  0x404
#define BR_DMZ_NEXT    0x40C
#define BR_DMZ_END     0x414
#define BR_DMZ_CUR     0x418
#define BR_DMZ_TOTAL   0x41C
#define BR_DMZ_PROG    0x420

static uint64_t g_br_info = 0;

/* C-6: busca la instancia de DMZGameInfo escaneando los punteros del Gameplay
   y validando la firma del struct (radio 30..30000, centro en el mundo,
   total de cierres 0..30, shape -1..4). Se cachea hasta que falle la lectura. */
static uint64_t mm_br_dmz_probe(uint64_t q)
{
    if (q == 0 || (q & 7) != 0) return 0;
    float rad = 0.0f, c[3] = { 0.0f, 0.0f, 0.0f };
    int total = 0, shape = 0;
    if (!mm_vm_read(q + BR_DMZ_RADIUS, &rad, sizeof(rad))) return 0;
    if (!isfinite(rad) || rad < 30.0f || rad > 30000.0f) return 0;
    if (!mm_vm_read(q + BR_DMZ_CENTER, c, sizeof(c))) return 0;
    if (!isfinite(c[0]) || !isfinite(c[2])) return 0;
    if (fabsf(c[0]) > 20000.0f || fabsf(c[2]) > 20000.0f) return 0;
    if (!mm_vm_read(q + BR_DMZ_TOTAL, &total, sizeof(total))) return 0;
    if (total < 0 || total > 30) return 0;
    if (!mm_vm_read(q + BR_DMZ_SHAPE, &shape, sizeof(shape))) return 0;
    if (shape < -1 || shape > 4) return 0;
    return q;
}

static uint64_t mm_br_dmz_find(void)
{
    if (g_br_info != 0) return g_br_info;
    /* PERF: escaneo caro. Un fallo se reintenta cada 5 s (antes era cada
       0.5 s y congelaba la pantalla a ratos). */
    static double s_scan = 0.0;
    double now = CACurrentMediaTime();
    if (s_scan > 0.0 && now - s_scan < 5.0) return 0;
    s_scan = now;
    if (g_fp_gameplay == NULL) return 0;
    void *gp = g_fp_gameplay();
    if (gp == NULL) return 0;
    /* Nivel 1: punteros directos del Gameplay. Nivel 2: un salto mas (el
       GameInfo suele colgar del Game/GameMode, no del Gameplay). */
    for (uintptr_t off = 0x100; off < 0x600; off += 8) {
        uint64_t q = 0;
        if (!mm_r64((uintptr_t)gp + off, &q) || q == 0) continue;
        uint64_t hit = mm_br_dmz_probe(q);
        if (hit != 0) { g_br_info = hit; return hit; }
        for (uintptr_t o2 = 0; o2 < 0x80; o2 += 8) {
            uint64_t r = 0;
            if (!mm_r64(q + o2, &r) || r == 0) continue;
            hit = mm_br_dmz_probe(r);
            if (hit != 0) { g_br_info = hit; return hit; }
        }
    }
    return 0;
}

static void mm_br_zone_read(void)
{
    /* C-8: DESCARTADO. La instancia de DMZGameInfo no es alcanzable desde el
       Gameplay (ni a 2 niveles) y el escaneo costaba caro. Se deja inerte. */
    g_br_zone.ok = 0;
    g_br_zone_info = nil;
    return;
    /* codigo viejo (no se ejecuta) */
    static double s_last = 0.0;
    double now = CACurrentMediaTime();
    if (s_last > 0.0 && now - s_last < 0.5) return;
    s_last = now;
    @try {
        uint64_t info = mm_br_dmz_find();
        if (info == 0) {
            g_br_zone.ok = 0;
            g_br_zone_info = @"sin DMZGameInfo";
            return;
        }
        float c[3] = { 0.0f, 0.0f, 0.0f }, rad = 0.0f;
        if (!mm_vm_read(info + BR_DMZ_CENTER, c, sizeof(c)) ||
            !mm_vm_read(info + BR_DMZ_RADIUS, &rad, sizeof(rad))) {
            g_br_zone.ok = 0;
            g_br_zone_info = @"zona ilegible";
            g_br_info = 0;
            return;
        }
        if (!isfinite(rad) || rad < 1.0f || rad > 50000.0f) {
            g_br_zone.ok = 0;
            g_br_zone_info = @"radio fuera de rango";
            return;
        }
        float nextT = 0.0f, prog = 0.0f;
        int cur = 0, total = 0;
        mm_vm_read(info + BR_DMZ_NEXT,  &nextT, sizeof(nextT));
        mm_vm_read(info + BR_DMZ_PROG,  &prog,  sizeof(prog));
        mm_vm_read(info + BR_DMZ_CUR,   &cur,   sizeof(cur));
        mm_vm_read(info + BR_DMZ_TOTAL, &total, sizeof(total));
        g_br_zone.nextS = 0.0f;
        if (isfinite(nextT) && nextT > 1.0e9f) {
            float nowT = (float)[[NSDate date] timeIntervalSince1970];
            float d = nextT - nowT;
            if (d > 0.0f && d < 3600.0f) g_br_zone.nextS = d;
        }
        g_br_zone.progress = isfinite(prog) ? prog : 0.0f;
        g_br_zone.cur = cur;
        g_br_zone.total = total;
        BOOL changed = (g_br_zone.ok == 0) ||
                       (g_br_zone.x != c[0]) || (g_br_zone.z != c[2]) ||
                       (g_br_zone.r != rad);
        g_br_zone.x = c[0]; g_br_zone.y = c[1]; g_br_zone.z = c[2];
        g_br_zone.r = rad;
        g_br_zone.t = now;
        g_br_zone.ok = 1;
        if (g_br_zone.nextS > 0.0f) {
            int s = (int)(g_br_zone.nextS + 0.5f);
            g_br_zone_info = [NSString stringWithFormat:@"r=%.0f  cierre %d/%d  %d:%02d",
                              rad, cur, total, s / 60, s % 60];
        } else {
            g_br_zone_info = [NSString stringWithFormat:@"r=%.0f  cierre %d/%d",
                              rad, cur, total];
        }
        if (changed) mm_scene_bump();
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
            g_br_pawn_fn   = (void *(*)(void))fp1;   /* v0.7.11: espejo para el probe BR */
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
/* C-5: proyecta el esqueleto del pawn en su caja. Los Transform se resuelven
   UNA vez por pawn con Transform.Find y se cachean; si el model root cambia
   (pawn reciclado) se vuelven a resolver. Todo falla en silencio. */
/* C-15: lee un string IL2CPP (len en +0x10, chars UTF-16 en +0x14). */
static void mm_cs_str(void *str, char *out, size_t cap)
{
    if (out == NULL || cap == 0) return;
    out[0] = '\0';
    if (str == NULL) return;
    int len = 0;
    if (!mm_vm_read((uintptr_t)str + 0x10, &len, sizeof(len))) return;
    if (len <= 0 || len > 120) return;
    size_t n = (size_t)len;
    if (n > cap - 1) n = cap - 1;
    uint16_t buf[121];
    if (!mm_vm_read((uintptr_t)str + 0x14, buf, n * 2)) return;
    for (size_t i = 0; i < n; i++) out[i] = (buf[i] < 128) ? (char)buf[i] : '?';
    out[n] = '\0';
}

/* C-15: indice de hueso por sufijo exacto ("Bip001 Head" -> " Head"). */
static int mm_bone_index(const char *name)
{
    if (name == NULL || name[0] == 0) return -1;
    size_t ln = strlen(name);
    for (int i = 0; i < MM_SK_N; i++) {
        size_t sl = strlen(mm_sk_suffix[i]);
        if (ln < sl) continue;
        if (strcmp(name + ln - sl, mm_sk_suffix[i]) == 0) return i;
    }
    return -1;
}

/* C-15: recorre la jerarquia (profundidad y nodos acotados) buscando huesos. */
static void mm_skel_walk(void *t, int depth, MMSkelCache *c, int *found, int *budget)
{
    if (t == NULL || depth > 7 || *found >= MM_SK_N || *budget <= 0) return;
    (*budget)--;
    void *nm = g_fp_getname ? g_fp_getname(t) : NULL;
    char name[122];
    mm_cs_str(nm, name, sizeof(name));
    int idx = mm_bone_index(name);
    if (idx >= 0 && c->bn[idx] == NULL) { c->bn[idx] = t; (*found)++; }
    if (g_fp_childcount == NULL || g_fp_getchild == NULL) return;
    int n = g_fp_childcount(t);
    if (n <= 0) return;
    if (n > 48) n = 48;
    for (int i = 0; i < n; i++) {
        if (*found >= MM_SK_N || *budget <= 0) return;
        void *ch = g_fp_getchild(t, i);
        mm_skel_walk(ch, depth + 1, c, found, budget);
    }
}

/* C-16: volcado de la jerarquia de huesos a Documents/fusion_bones.txt para
   diagnosticar por que el walk no encuentra los huesos. */
static void mm_bones_dump_walk(void *t, int depth, NSMutableString *out, int *budget)
{
    if (t == NULL || depth > 8 || *budget <= 0) return;
    (*budget)--;
    void *nm = g_fp_getname ? g_fp_getname(t) : NULL;
    char name[122];
    mm_cs_str(nm, name, sizeof(name));
    NSMutableString *ind = [NSMutableString string];
    for (int i = 0; i < depth; i++) [ind appendString:@"  "];
    [out appendFormat:@"%@%s\n", ind, name];
    if (g_fp_childcount == NULL || g_fp_getchild == NULL) return;
    int n = g_fp_childcount(t);
    if (n > 64) n = 64;
    for (int i = 0; i < n && *budget > 0; i++)
        mm_bones_dump_walk(g_fp_getchild(t, i), depth + 1, out, budget);
}

static void mm_bones_dump(void)
{
    @try {
        NSString *docs = mm_docs_dir();
        if (docs.length == 0) return;
        NSMutableString *out = [NSMutableString string];
        [out appendString:@"# FUSION bones dump\n"];
        if (g_box_count <= 0) {
            [out appendString:@"sin cajas (activa el ESP y espera a ver enemigos)\n"];
        } else {
            uint64_t pawn = g_boxes[0].pawn;
            uint64_t root = 0;
            if (!mm_r64((uintptr_t)pawn + OFF_PAWN_MODELROOT, &root) || root == 0)
                mm_r64((uintptr_t)pawn + OFF_PAWN_MESH, &root);
            [out appendFormat:@"pawn=0x%llX root=0x%llX\n",
                              (unsigned long long)pawn, (unsigned long long)root];
            if (root != 0) {
                int budget = 400;
                mm_bones_dump_walk((void *)(uintptr_t)root, 0, out, &budget);
            }
        }
        [out writeToFile:[docs stringByAppendingPathComponent:@"fusion_bones.txt"]
              atomically:YES encoding:NSUTF8StringEncoding error:nil];
    } @catch (NSException *e) { }
}

static void *mm_skel_find(void *root, const char *name)
{
    if (root == NULL || g_fp_find == NULL) return NULL;
    NSString *p = [NSString stringWithUTF8String:name];
    if (p == nil) return NULL;
    return g_fp_find(root, (__bridge void *)p);
}

/* C-5b: resuelve los 21 huesos probando las raices y las formas de ruta que
   usa CODM (root = Bip001, root encima de Bip001, o ruta con prefijo). */
static NSString *s_sk_bare[MM_SK_N];
static NSString *s_sk_pref[MM_SK_N];
static void mm_skel_strings(void)
{
    static BOOL once = NO;
    if (once) return;
    once = YES;
    for (int i = 0; i < MM_SK_N; i++) {
        NSString *b = [NSString stringWithUTF8String:mm_sk_path[i]];
        s_sk_bare[i] = b;
        NSString *sub = (b.length > 7) ? [b substringFromIndex:7] : b;
        s_sk_pref[i] = [NSString stringWithFormat:@"Bip001/%@", sub];
    }
}

static int mm_skel_resolve(uint64_t root, MMSkelCache *c)
{
    if (g_fp_find == NULL) return 0;
    mm_skel_strings();
    void *r = (void *)(uintptr_t)root;
    void *bip = g_fp_find(r, (__bridge void *)s_sk_bare[0]);
    /* s_sk_bare[0] es "Bip001 Pelvis"; probamos el nodo Bip001 aparte */
    NSString *bipName = [NSString stringWithUTF8String:"Bip001"];
    if (bipName != nil) {
        void *b = g_fp_find(r, (__bridge void *)bipName);
        if (b != NULL) bip = b;
    }
    int found = 0;
    for (int i = 0; i < MM_SK_N; i++) {
        void *t = g_fp_find(r, (__bridge void *)s_sk_bare[i]);
        if (t == NULL && bip != NULL) t = g_fp_find(bip, (__bridge void *)s_sk_bare[i]);
        if (t == NULL) t = g_fp_find(r, (__bridge void *)s_sk_pref[i]);
        if (t != NULL) { c->bn[i] = t; found++; }
    }
    return found;
}

static void mm_skel_fill(MMEspBox *nb, const float *view, const float *proj,
                         CGFloat W, CGFloat H)
{
    nb->skMask = 0;
    if (!g_fp_trpos || !g_fp_getname) return;
    uint64_t pawn = nb->pawn;
    uint64_t root = 0;
    /* C-5b: dos candidatos de raiz (model root / mesh). */
    if (!mm_r64((uintptr_t)pawn + OFF_PAWN_MODELROOT, &root) || root == 0)
        mm_r64((uintptr_t)pawn + OFF_PAWN_MESH, &root);
    if (root == 0) return;

    MMSkelCache *c = NULL;
    for (int i = 0; i < MM_MAX_BOXES; i++)
        if (g_skel_cache[i].pawn == pawn) { c = &g_skel_cache[i]; break; }
    if (c == NULL) {
        c = &g_skel_cache[0];
        for (int i = 0; i < MM_MAX_BOXES; i++)
            if (g_skel_cache[i].pawn == 0) { c = &g_skel_cache[i]; break; }
    }
    /* C-5d: sin el "|| !c->ok" esto reintentaba Find 63 veces POR PAWN Y POR
       FRAME cuando no encontraba huesos (de ahi el congelamiento). Ahora un
       fallo se reintenta como mucho cada 5 s. */
    BOOL need = (c->pawn != pawn) || (c->root != root) || (!c->ok);
    if (need) {
        double tnow = CACurrentMediaTime();
        if (!c->ok && c->pawn == pawn && c->root == root &&
            c->lastTry > 0.0 && tnow - c->lastTry < 5.0) return;
        memset(c, 0, sizeof(*c));
        c->pawn = pawn;
        c->root = root;
        c->lastTry = tnow;
        /* C-15: UNA resolucion por pasada del colector. Antes se resolvian
           todos los pawns de golpe y eso congelaba el juego. */
        if (g_skel_budget <= 0) { memset(c, 0, sizeof(*c)); return; }
        g_skel_budget--;
        int found = 0, budget = 240;
        mm_skel_walk((void *)(uintptr_t)root, 0, c, &found, &budget);
        c->ok = (found >= 6) ? 1 : 0;
        if (!c->ok) return;
    }
    /* C-5c: los 21 huesos se proyectan cada 3 pasadas (~10 Hz) y se reusan;
       proyectar 21 huesos x N pawns a 30-60 Hz era parte del peso. */
    static unsigned s_tick = 0;
    if (c->mask == 0 || (s_tick++ % 3) == 0) {
        c->mask = 0;
        for (int i = 0; i < MM_SK_N; i++) {
            if (c->bn[i] == NULL) continue;
            float bp[3] = { 0.0f, 0.0f, 0.0f };
            g_fp_trpos(c->bn[i], bp);
            if (!isfinite(bp[0]) || !isfinite(bp[1]) || !isfinite(bp[2])) continue;
            CGPoint p;
            int det = 0;
            float vx = 0.0f, vy = 0.0f;
            if (mm_w2s(view, proj, bp, NO, W, H, &p, &det, &vx, &vy)) {
                c->pts[i] = p;
                c->mask |= (1u << i);
            }
        }
    }
    memcpy(nb->sk, c->pts, sizeof(nb->sk));
    nb->skMask = c->mask;
}

static void mm_esp_collect_real(void)
{
    g_skel_budget = 1;   /* C-15: una resolucion de huesos por pasada */
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
        if (opts->skeleton) mm_skel_fill(&nb, view, proj, W, H);   /* C-15 */

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

    UIView *a = mm_cloud_card(@"OBJETIVOS", 0.0, MM_CLOUD_CARD_W, MM_CLOUD_BODY_H);
    NSArray *keys = @[ @"mm_esp_master", @"mm_esp_box", @"mm_esp_players",
                       @"mm_esp_bots", @"mm_esp_name", @"mm_esp_dist" ];
    NSArray *titles = @[ @"ESP maestro", @"Cajas", @"Jugadores", @"Bots",
                         @"Nombres", @"Distancia" ];
    for (NSUInteger i = 0; i < keys.count; i++)
        mm_cloud_row(a, titles[i], keys[i], NO,
                     38.0 + (CGFloat)i * MM_CLOUD_ROW_H, (i != 0));
    [page addSubview:a];

    UIView *b = mm_cloud_card(@"LECTURA", MM_CLOUD_CARD_W + MM_CLOUD_CARD_GAP,
                              MM_CLOUD_CARD_W, MM_CLOUD_BODY_H);
    NSArray *rkeys = @[ @"mm_esp_health", @"mm_esp_lines", @"mm_esp_lines_top",
                        @"mm_esp_fill" ];
    NSArray *rtit = @[ @"Salud", @"Lineas", @"Lineas desde arriba", @"Relleno" ];
    for (NSUInteger i = 0; i < rkeys.count; i++)
        mm_cloud_row(b, rtit[i], rkeys[i], NO,
                     38.0 + (CGFloat)i * MM_CLOUD_ROW_H, YES);
    mm_cloud_row(b, @"Aimbot", @"mm_x_aim_on", NO, 150.0, NO);
    UILabel *anote = mm_cloud_caption(@"Fuerza de aim", 178.0);
    anote.frame = CGRectMake(MM_CLOUD_CARD_INNER, 178.0, iw, 12.0);
    [b addSubview:anote];
    UISlider *as = mm_cloud_slider(0.0f, 28.0f, g_aim_strength, @"mm_x_aim_strength",
                                   @selector(onAimStrength:), iw);
    as.frame = CGRectMake(MM_CLOUD_CARD_INNER, 190.0, iw, 24.0);
    [b addSubview:as];    [page addSubview:b];

    UIView *c = mm_cloud_card(@"CONTROL", (MM_CLOUD_CARD_W + MM_CLOUD_CARD_GAP) * 2.0,
                              MM_CLOUD_CARD_W, MM_CLOUD_BODY_H);
    float rng = mm_def_float(@"mm_esp_range", 500.0f);
    UILabel *rl = mm_cloud_caption(@"Rango ESP", 108.0);
    rl.frame = CGRectMake(MM_CLOUD_CARD_INNER, 38.0, 108.0, 14.0);
    [c addSubview:rl];
    g_range_val = mm_cloud_label([NSString stringWithFormat:@"%d m", (int)(rng + 0.5f)],
                                 10.2, UIFontWeightSemibold, mm_neon_green());
    g_range_val.textAlignment = NSTextAlignmentRight;
    g_range_val.frame = CGRectMake(MM_CLOUD_CARD_INNER + 112.0, 38.0, iw - 112.0, 14.0);
    [c addSubview:g_range_val];
    UISlider *rs = mm_cloud_slider(20.0f, 500.0f, rng, @"mm_esp_range",
                                   @selector(onSlider:), iw);
    rs.frame = CGRectMake(MM_CLOUD_CARD_INNER, 54.0, iw, 24.0);
    [c addSubview:rs];

    float maxn = mm_def_float(@"mm_x_maxn", 0.0f);
    UILabel *ml = mm_cloud_caption(@"Limite cercano", 108.0);
    ml.frame = CGRectMake(MM_CLOUD_CARD_INNER, 88.0, 108.0, 14.0);
    [c addSubview:ml];
    g_maxn_val = mm_cloud_label((maxn < 0.5f) ? mm_tr(@"Todos")
                                              : [NSString stringWithFormat:@"%d", (int)(maxn + 0.5f)],
                                10.2, UIFontWeightSemibold, mm_neon_green());
    g_maxn_val.textAlignment = NSTextAlignmentRight;
    g_maxn_val.frame = CGRectMake(MM_CLOUD_CARD_INNER + 112.0, 88.0, iw - 112.0, 14.0);
    [c addSubview:g_maxn_val];
    UISlider *ms = mm_cloud_slider(0.0f, (float)MM_MAX_BOXES, maxn, @"mm_x_maxn",
                                   @selector(onMaxN:), iw);
    ms.frame = CGRectMake(MM_CLOUD_CARD_INNER, 104.0, iw, 24.0);
    [c addSubview:ms];

    mm_cloud_static_row(c, @"No recoil", @"ACTIVO", 150.0);
    mm_cloud_static_row(c, @"No spread", @"ACTIVO", 178.0);
    [page addSubview:c];
}

static void mm_cloud_build_visual(UIView *page)
{
    CGFloat iw = MM_CLOUD_CARD_W - (MM_CLOUD_CARD_INNER * 2.0);

    UIView *a = mm_cloud_card(@"CAJA", 0.0, MM_CLOUD_CARD_W, MM_CLOUD_BODY_H);
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
    mm_cloud_card_caption(a, @"Perfiles (tema + config)", 138.0);
    g_profile_seg = mm_cloud_seg(@[ @"P1", @"P2", @"P3", @"P4", @"P5" ], iw);
    g_profile_seg.frame = CGRectMake(MM_CLOUD_CARD_INNER, 152.0, iw, 26.0);
    g_profile_seg.selectedSegmentIndex = g_profile_slot;
    [g_profile_seg addTarget:[MMTargets shared] action:@selector(onProfileSlot:)
            forControlEvents:UIControlEventValueChanged];
    [a addSubview:g_profile_seg];
    CGFloat halfW = (iw - 8.0) / 2.0;
    UIButton *psv = mm_cloud_action(@"Guardar",
        [UIColor colorWithRed:0.08 green:0.38 blue:0.20 alpha:0.96], halfW, 28.0);
    psv.frame = CGRectMake(MM_CLOUD_CARD_INNER, 182.0, halfW, 28.0);
    [psv addTarget:[MMTargets shared] action:@selector(onProfileSave)
        forControlEvents:UIControlEventTouchUpInside];
    [a addSubview:psv];
    UIButton *pld = mm_cloud_action(@"Cargar",
        [UIColor colorWithRed:0.08 green:0.24 blue:0.42 alpha:0.96], halfW, 28.0);
    pld.frame = CGRectMake(MM_CLOUD_CARD_INNER + halfW + 8.0, 182.0, halfW, 28.0);
    [pld addTarget:[MMTargets shared] action:@selector(onProfileLoad)
        forControlEvents:UIControlEventTouchUpInside];
    [a addSubview:pld];

    [page addSubview:a];

    UIView *b = mm_cloud_card(@"MIRA", MM_CLOUD_CARD_W + MM_CLOUD_CARD_GAP,
                              MM_CLOUD_CARD_W, MM_CLOUD_BODY_H);
    mm_cloud_row(b, @"Crosshair (mira)", @"mm_x_cross", NO, 38.0, YES);
    mm_cloud_row(b, @"Anillo de aim", @"mm_x_aimring", NO, 66.0, YES);
    mm_cloud_row(b, @"Circulo de FOV", @"mm_x_fov_circle", NO, 94.0, YES);
    mm_cloud_card_caption(b, @"Estilo de crosshair", 96.0);
    int cstyle = (int)mm_def_float(@"mm_x_cross_style", 0.0f);
    if (cstyle < 0 || cstyle > 3) cstyle = 0;
    UISegmentedControl *cs = mm_cloud_seg(@[ mm_tr(@"Cruz"), mm_tr(@"Punto"),
                                              mm_tr(@"Circulo"), mm_tr(@"Todo") ], iw);
    cs.frame = CGRectMake(MM_CLOUD_CARD_INNER, 112.0, iw, 24.0);
    cs.selectedSegmentIndex = cstyle;
    [cs addTarget:[MMTargets shared] action:@selector(onCrossStyle:)
        forControlEvents:UIControlEventValueChanged];
    [b addSubview:cs];

    /* Fase C-2: FOV del aim (grados). Fuera del cono, el aim no asiste. */
    mm_cloud_card_caption(b, @"FOV de aim", 138.0);
    UISlider *af = mm_cloud_slider(5.0f, 180.0f, g_aim_fov, @"mm_x_aim_fov",
                                   @selector(onAimFov:), iw);
    af.frame = CGRectMake(MM_CLOUD_CARD_INNER, 152.0, iw, 22.0);
    [b addSubview:af];

    /* Fase C-4: suavizado del aim (0 = snap, 1 = lento). */
    mm_cloud_card_caption(b, @"Suavizado de aim", 178.0);
    UISlider *as2 = mm_cloud_slider(0.0f, 1.0f, g_aim_smooth, @"mm_x_aim_smooth",
                                    @selector(onAimSmooth:), iw);
    as2.frame = CGRectMake(MM_CLOUD_CARD_INNER, 192.0, iw, 22.0);
    [b addSubview:as2];
    [page addSubview:b];

    UIView *c = mm_cloud_card(@"MUNDO", (MM_CLOUD_CARD_W + MM_CLOUD_CARD_GAP) * 2.0,
                              MM_CLOUD_CARD_W, MM_CLOUD_BODY_H);
    mm_cloud_row(c, @"Estelas (ultimos 2 s)", @"mm_x_trails", NO, 38.0, YES);
    mm_cloud_row(c, @"Brujula de bearings", @"mm_x_bearings", NO, 66.0, YES);
    mm_cloud_row(c, @"Esqueleto", @"mm_x_skel", NO, 94.0, YES);
    mm_cloud_row(c, @"Ignorar caidos (aim)", @"mm_x_ignore_down", NO, 122.0, NO);
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
    UILabel *sub = mm_cloud_label([NSString stringWithFormat:@"FUSION  ·  v%s", MODMENU_VERSION],
                                  8.0, UIFontWeightSemibold,
                                  [UIColor colorWithWhite:0.52 alpha:1.0]);
    sub.frame = CGRectMake(65.0, 34.0, 210.0, 13.0);
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
    NSArray *navTitles = @[ @"COMBATE", @"VISUAL", @"RADAR", @"INFO" ];
    CGFloat navW = (MM_PANEL_W - 36.0 - 32.0) / 4.0;
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
        UIView *nb = [[UIView alloc] initWithFrame:CGRectMake(9.0, 38.0 - 3.2,
                                                              navW - 18.0, 2.4)];
        nb.tag = 99;
        nb.backgroundColor = mm_neon_green();
        nb.layer.cornerRadius = 1.2;
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
    g_p_vis  = [[UIView alloc] initWithFrame:body];
    g_p_misc = [[UIView alloc] initWithFrame:body];
    g_p_info = [[UIView alloc] initWithFrame:body];
    g_p_vis.hidden = YES;
    g_p_misc.hidden = YES;
    g_p_info.hidden = YES;
    [g_panel addSubview:g_p_esp];
    [g_panel addSubview:g_p_vis];
    [g_panel addSubview:g_p_misc];
    [g_panel addSubview:g_p_info];

    g_sub_switches = [NSMutableArray array];
    mm_cloud_build_combat(g_p_esp);
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
        /* v0.7.5: el probe BR corre a los 2 s (menu/splash) para capturar
           los prologos y chases; pero si en ese momento el singleton del
           BRMgr aun no esta instanciado (slot estatico = 0), reintentabamos.
           v0.7.8: cambio la gate de "got_inst" a "saw_diff"
           (shrink activo capturado) para seguir reintentando hasta
           enganchar el shrink. Cadencia 30 s (antes 15) para bajar el
           hitch de 500 ms del dump dinamico; en gameplay el usuario entra
           a BR, cae, llega al shrink en 3-5 min: con 30 s hay ventana
           suficiente. Despues del primer shrink, saw_diff=1 y stop. */
        {
            double now = mm_uptime();
            if (now > 2.0) {
                int should_run = 0;
                if (g_br_probe == nil) should_run = 1;
                else if (!g_br_probe_saw_diff && (now - g_br_probe_last_run) >= 30.0)
                    should_run = 1;
                if (should_run) mm_br_probe_run();
            }
        }
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
    g_aim_fov = mm_def_float(@"mm_x_aim_fov", 180.0f);
    if (g_aim_fov < 5.0f || g_aim_fov > 180.0f) g_aim_fov = 180.0f;
    g_aim_smooth = mm_def_float(@"mm_x_aim_smooth", 0.0f);
    if (g_aim_smooth < 0.0f || g_aim_smooth > 1.0f) g_aim_smooth = 0.0f;
    g_cam_fov = mm_def_float(@"mm_cam_fov", 0.0f);
    if (g_cam_fov < 0.5f || g_cam_fov > 120.0f) g_cam_fov = 0.0f;
    g_aim_on = mm_def_bool(@"mm_x_aim_on", NO);
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
