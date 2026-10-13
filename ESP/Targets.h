/*=============================================================================
 *  Targets.h  -  tabla de jugadores, filtros y entrada de render
 *  ----------------------------------------------------------------------
 *  La ESP no busca una lista de jugadores por simbolo: engancha GetPlayerAABB,
 *  que el juego ya llama por jugador y por frame (hitbox, net-sync, IA).
 *  Eso da el flujo real de jugadores sin depender de los nombres de la
 *  metadata, que en CODM estan wipeados.
 *
 *  Cada llamada al hook refresca la entrada correspondiente a ese jugador. Las
 *  entradas que no se refrescan en aging_ttl segundos se marcan muertas.
 *============================================================================*/

#ifndef TARGETS_H
#define TARGETS_H

#include "ESP.h"
#include "Hook.h"

/* Disposicion del AABB que devuelve GetPlayerAABB. El calibrador mide cual
   es la buena en la build de cada uno; aqui se guardan las candidatas. */
typedef enum {
    AABB_MINMAX6 = 0,   /* [minx,miny,minz, maxx,maxy,maxz]        */
    AABB_MINMAX8,       /* [minx,miny,minz, maxx,maxy,maxz, , ]    */
    AABB_CENTER_SIZE,   /* [cx,cy,cz, sx,sy,sz]                     */
    AABB_ORIGIN_SIZE,   /* [x,y,z, sx,sy,sz]                         */
    AABB_DAGOR,         /* [axX,axY,axZ, axY..., originX,Y,Z]       */
    AABB__COUNT
} esp_aabb_layout_t;

#define ESP_MAX_TARGETS 64
#define ESP_AGE_TTL     1.5f      /* segundos sin refrescar -> muerto */

typedef struct {
    uint64_t  id;            /* direccion del jugador; es la clave */
    float     min[3];
    float     max[3];
    float     center[3];
    float     health;
    char      name[32];
    bool      alive;
    bool      valid;
    double    last_seen;     /* CACurrentMediaTime() */
    uint32_t  hits;          /* veces enganchado */
} esp_target_t;

/* --- alimentacion ------------------------------------------------------ */
/* Convierte un offset de la tabla (VA-0x100000000) en direccion real, sumando
   el slide con el que dyld cargo la imagen del juego. NULL si no resuelve. */
void *esp_resolve(int64_t off);

/* Se llama desde el detour. self_ptr es x0 del gestor enganchado. */
void esp_targets_feed(uint64_t self_ptr, const float *floats, int n_floats,
                      double now);

/* Pasa a esp_target_t[] todo lo que este vivo. Devuelve cuantos. */
int  esp_targets_snapshot(esp_target_t *out, int max);

/* --- arranque ---------------------------------------------------------- */
/* Resuelve la base de carga del 'cod' y engancha loOffsets definidos.
   Devuelve el numero de hooks puestos; los fallos van al log. */
int  esp_targets_start(const esp_config_t *cfg);
void esp_targets_stop(void);

/* --- render ------------------------------------------------------------ */
void esp_render_frame(void *cgctx, float width, float height);

/* --- calibrador -------------------------------------------------------- */
/* Vuelca a /tmp/esp-calib.txt lo que se ha observado. */
void esp_targets_calib_dump(void);
int  esp_targets_calib_aabb_candidates(void);

#endif /* TARGETS_H */