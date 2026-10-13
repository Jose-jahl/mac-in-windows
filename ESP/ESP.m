/*=============================================================================
 *  ESP.m  -  arranque, configuracion y bucle
 *  ----------------------------------------------------------------------
 *  Se inyecta en cod.app con su propia LC_LOAD_DYLIB, independiente de
 *  KeyGate. Arranca por constructor (antes que main) y espera a que la app
 *  tenga ventana antes de poner nada en pantalla.
 *
 *  El flujo de arranque tiene que ser conservador. Un constructor corre
 *  antes de que exista la UIApplication, asi que todo lo que toque UIKit
 *  se hace despues, en el hilo principal, y con margen: si se engancha
 *  demasiado pronto el juego todavia no ha cargado la partida y no hay
 *  jugadores ni matrices que leer.
 *
 *  Los offsets llegan por el Info.plist (clave CODMESPConfig, JSON plano).
 *  Asi la misma dylib sirve para cualquier build: lo que cambia entre
 *  actualizaciones se escribe desde la herramienta, no se recompila.
 *============================================================================*/

#include "ESP.h"
#include "Hook.h"
#include "Overlay.h"
#include "Targets.h"

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#include <string.h>
#include <stdlib.h>
#include <stdio.h>

/* --------------------------------------------------------------------- */
/* Defaults                                                               */
/* --------------------------------------------------------------------- */
void esp_config_defaults(esp_config_t *c)
{
    memset(c, 0, sizeof(*c));
    c->enabled = true;

    c->draw_box = true;
    c->draw_corner_box = false;
    c->draw_health = true;
    c->draw_name = true;
    c->draw_distance = true;
    c->draw_snapline = false;
    c->draw_fov_circle = false;
    c->through_walls = true;

    c->enemies_only = true;
    c->max_distance = 0.0f;      /* 0 = sin limite */
    c->fov_degrees = 0.0f;       /* 0 = sin cono */

    c->box_thickness = 1.5f;
    c->corner_ratio = 0.22f;
    c->fov_radius_px = 0.0f;
    c->snapline_height_px = 0.0f;

    c->max_targets = ESP_MAX_TARGETS;
    c->update_hz = 60.0f;
    c->smooth = true;
    c->aabb_layout = 0;          /* AABB_MINMAX6 */

    c->color_box       = 0x00FF88;
    c->color_health    = 0x3CE86A;
    c->color_text      = 0xFFFFFF;
    c->color_enemy     = 0xFF4D5A;
    c->color_friendly  = 0x4C8DFF;
    c->color_dead      = 0x606060;

    /* -1 = sin resolver. Estos son los de la build del 2026-09-07; la
       herramienta los reescribe al generar cada IPA. */
    c->off.player_aabb         = 0x29F9A4C;
    c->off.player_target_point = 0x2D56394;
    c->off.player_name         = 0x4D45824;
    c->off.player_state        = 0x200182C;
    c->off.is_dead             = 0x2D30170;
    c->off.health              = 0x7E4E258;
    c->off.view_matrix         = -1;
    c->off.proj_matrix         = -1;
}

/* --------------------------------------------------------------------- */
/* JSON plano                                                            */
/* --------------------------------------------------------------------- */
/* A proposito no se tira de NSJSONSerialization: aqui solo hay escalares y
   listas de numeros, y hacerlo a mano evita arrastrar la dependencia y los
   errores silenciosos de "clave que no existe" que no distinguen de un
   default mal puesto. */

/* "clave": 1234  -> busca el valor de una clave de primer nivel. */
static bool json_num(const char *j, const char *key, double *out)
{
    char pat[64];
    snprintf(pat, sizeof(pat), "\"%s\"", key);
    const char *p = strstr(j, pat);
    if (!p) return false;
    p += strlen(pat);
    while (*p && (*p == ' ' || *p == ':' || *p == '\t')) p++;
    if (!*p) return false;
    char *end = NULL;
    double v = strtod(p, &end);
    if (end == p) return false;
    *out = v;
    return true;
}

static bool json_bool(const char *j, const char *key, bool *out)
{
    double v;
    if (!json_num(j, key, &v)) return false;
    *out = (v != 0.0);
    return true;
}

bool esp_config_load(esp_config_t *c, const char *json)
{
    esp_config_defaults(c);
    if (!json || !*json) return false;

    double n;
    bool   b;

#define NUM(k, field)  if (json_num(json, k, &n)) c->field = (int32_t)n
#define FLT(k, field)  if (json_num(json, k, &n)) c->field = (float)n
#define BOOL(k, field) if (json_bool(json, k, &b)) c->field = b

    BOOL("enabled",         enabled);
    BOOL("drawBox",         draw_box);
    BOOL("drawCornerBox",   draw_corner_box);
    BOOL("drawHealth",      draw_health);
    BOOL("drawName",        draw_name);
    BOOL("drawDistance",    draw_distance);
    BOOL("drawSnapline",    draw_snapline);
    BOOL("drawFovCircle",   draw_fov_circle);
    BOOL("enemiesOnly",     enemies_only);
    BOOL("smooth",          smooth);
    FLT("maxDistance",      max_distance);
    FLT("fovDegrees",       fov_degrees);
    FLT("boxThickness",     box_thickness);
    FLT("cornerRatio",      corner_ratio);
    FLT("fovRadiusPx",      fov_radius_px);
    FLT("snaplineHeightPx", snapline_height_px);
    FLT("updateHz",         update_hz);
    NUM("aabbLayout",       aabb_layout);
    NUM("maxTargets",       max_targets);

    NUM("colorBox",      color_box);
    NUM("colorHealth",   color_health);
    NUM("colorText",     color_text);
    NUM("colorEnemy",    color_enemy);
    NUM("colorFriendly", color_friendly);
    NUM("colorDead",     color_dead);

    /* Offsets: si vienen como negativos (-1) se dejan sin resolver. */
    int64_t o;
#define OFF(k, field) do { \
        double v; \
        if (json_num(json, k, &v)) { o = (int64_t)v; c->off.field = (o == -1) ? -1 : o; } \
    } while (0)

    OFF("offPlayerAABB",         player_aabb);
    OFF("offPlayerTargetPoint",  player_target_point);
    OFF("offPlayerName",         player_name);
    OFF("offPlayerState",        player_state);
    OFF("offIsDead",             is_dead);
    OFF("offHealth",             health);
    OFF("offViewMatrix",         view_matrix);
    OFF("offProjMatrix",         proj_matrix);

#undef OFF
#undef BOOL
#undef FLT
#undef NUM
    return true;
}

/* --------------------------------------------------------------------- */
/* Arranque                                                               */
/* --------------------------------------------------------------------- */
static esp_config_t g_cfg;

static void esp_boot(void);

__attribute__((constructor))
static void ESP_init(void)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        /* 2,5 s: margen para que la app cree su ventana y arranque la escena.
           Antes de esto no hay ni matriz de camara ni jugadores. */
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{ esp_boot(); });
    });
}

static void esp_boot(void)
{
    NSString *json = [[NSBundle mainBundle] objectForInfoDictionaryKey:ESP_PLIST_CONFIG];

    /* Sin config en el plist: esta build no lleva ESP. Se sale callado, que es
       lo correcto: el usuario no pidio ESP en esta IPA. */
    if (![json isKindOfClass:[NSString class]] || json.length == 0) {
        NSLog(@"[ESP] sin CODMESPConfig en el Info.plist: no se activa nada.");
        return;
    }

    esp_config_load(&g_cfg, [json UTF8String]);
    if (!g_cfg.enabled) {
        NSLog(@"[ESP] presente pero desactivado por configuracion.");
        return;
    }

    /* Modo calibracion: no dibuja, solo mide y vuelca. */
    id cal = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CODMESPCalibrate"];
    g_calibrate = [cal isKindOfClass:[NSString class]] && [cal isEqualToString:@"1"];

    int n = esp_targets_start(&g_cfg);
    if (n <= 0) {
        NSLog(@"[ESP] no se pudo enganchar nada: revisa los offsets.");
        return;
    }

    esp_overlay_start();
    NSLog(@"[ESP] activo (%d hooks, calibracion=%@)", n, g_calibrate ? @"si" : @"no");

    if (g_calibrate) {
        /* Escribe el informe cada 2 s durante 60 s, y luego cada vez que se
          Ipale. Sirve para ver si el hook recibe llamadassteady-state. */
        __block int ticks = 0;
        NSTimer *t = [NSTimer scheduledTimerWithTimeInterval:2.0 repeats:YES block:^(NSTimer *tm) {
            esp_targets_calib_dump();
            if (++ticks >= 30) {
                [tm invalidate];
                NSLog(@"[ESP] calibracion terminada -> /tmp/esp-calib.txt");
            }
        }];
        (void)t;
    }
}

/* --------------------------------------------------------------------- */
/* Matrices                                                               */
/* --------------------------------------------------------------------- */
/* Aqui se engancha la lectura de la camara. Esta es la parte que todavia no
   tiene fuente confirmado: lo que hace falta es un offset en el plist que
   apunte a la matriz de vista del renderer.

   Si view_matrix y proj_matrix vienen a -1, la ESP arranca y se engancha, pero
   no proyecta nada. El calibrador escribe en /tmp/esp-calib.txt que es lo que
   falta. No es un fallo silencioso a proposito. */
void esp_pump_matrices(void)
{
    if (g_cfg.off.view_matrix < 0 || g_cfg.off.proj_matrix < 0) return;
    float v[16], p[16];
    void *vp = esp_resolve(g_cfg.off.view_matrix);
    void *pp = esp_resolve(g_cfg.off.proj_matrix);
    if (!vp || !pp) return;
    memcpy(v, vp, sizeof(v));
    memcpy(p, pp, sizeof(p));
    esp_overlay_set_matrices(v, p);
}