/*=============================================================================
 *  ESP.h  -  contrato comun de ESP.dylib
 *  ----------------------------------------------------------------------
 *  ESP aparte de KeyGate: se empaquetan e inyectan por separado y se activan
 *  por separado. Si el ESP peta, la llave de inicio sigue funcionando.
 *
 *  Como se pasan los offsets: por el Info.plist, igual que la llave de
 *  KeyGate. La tool escribe ESPConfig (JSON plano) en la clave CODMESPConfig
 *  y ESP lo lee al arrancar. Motivo: los VAs cambian en cada update del
 *  juego y no tiene sentido quemarlos en el binario.
 *
 *  Constante de version: si la tool y la dylib no coinciden, se avisa.
 *============================================================================*/

#ifndef ESP_H
#define ESP_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

#define ESP_VERSION 1

/* ------------------------------------------------------------------------ */
/* Claves del Info.plist                                                     */
/* ------------------------------------------------------------------------ */
#define ESP_PLIST_CONFIG "CODMESPConfig"

/* ------------------------------------------------------------------------ */
/* Config                                                                    */
/* ------------------------------------------------------------------------ */

/* Offsets (VA-0x100000000 en la build de referencia). -1 = no resuelto. */
typedef struct {
    int64_t player_aabb;        /* 0x1029F9A4C -> 0x29F9A4C */
    int64_t player_target_point;/* 0x102D56394 -> 0x2D56394 */
    int64_t player_name;        /* 0x104D45824 -> 0x4D45824 */
    int64_t player_state;       /* 0x10200182C -> 0x200182C */
    int64_t is_dead;            /* 0x102D30170 -> 0x2D30170 */
    int64_t health;             /* 0x107E4E258 -> 0x7E4E258 */
    int64_t view_matrix;        /* matriz 4x4 de vista    */
    int64_t proj_matrix;        /* matriz 4x4 de proyeccion */
} esp_offsets_t;

typedef struct {
    bool  enabled;

    /* dibujo */
    bool  draw_box;
    bool  draw_corner_box;
    bool  draw_health;
    bool  draw_name;
    bool  draw_distance;
    bool  draw_snapline;
    bool  draw_fov_circle;
    bool  draw_turret_line;
    bool  through_walls;

    /* filtrado */
    bool  enemies_only;
    float max_distance;         /* metros */
    float fov_degrees;          /* cono de vision */

    /* estilo */
    float box_thickness;
    float corner_ratio;         /* 0..1, parte de la caja que son esquinas */
    float fov_radius_px;
    float snapline_height_px;   /* 0 = hasta el borde inferior */

    /* rendimiento */
    int   max_targets;
    float update_hz;            /* lecturas por segundo */
    bool  smooth;               /* interpolar las cajas entre frames */

    /* Disposicion del AABB que devuelve GetPlayerAABB. El calibrador mide
       cual es la buena: 0=minmax6 1=minmax8 2=center_size 3=origin_size 4=dagor */
    int   aabb_layout;

    /* color: 0xAARRGGBB */
    uint32_t color_box;
    uint32_t color_health;
    uint32_t color_text;
    uint32_t color_enemy;
    uint32_t color_friendly;
    uint32_t color_dead;

    esp_offsets_t off;
} esp_config_t;

/* Valores por defecto: los que funcionan con una ESP de caja + vida + nombre. */
void esp_config_defaults(esp_config_t *c);

/* Lee el JSON plano del plist. Devuelve false si no hay config (se usan los
   defaults). No aborta nunca: sin config la ESP arranca igual. */
bool  esp_config_load(esp_config_t *c, const char *json);

/* Modo diagnostico: vuelca a disco lo que encuentra y no dibuja. Se activa con
   ESP_CALIBRATE=1 en el entorno o con la clave CODMESPCalibrate=1 en el plist. */
extern bool g_calibrate;

/* Lee la camara y se la pasa al overlay. La llama el propio bucle de render
   cada frame, asi que no hay que acordarse de invocarla. */
void esp_pump_matrices(void);

#endif /* ESP_H */