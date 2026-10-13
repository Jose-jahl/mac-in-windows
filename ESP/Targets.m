/*=============================================================================
 *  Targets.m
 *============================================================================*/

#include "Targets.h"
#include "Overlay.h"

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>   /* CACurrentMediaTime */
#import <mach-o/dyld.h>
#import <mach-o/loader.h>
#import <dlfcn.h>
#include <string.h>
#include <math.h>
#include <stdio.h>
#include <mach/mach_time.h>
#include <QuartzCore/QuartzCore.h>

/* --------------------------------------------------------------------- */
/* Estado                                                                 */
/* --------------------------------------------------------------------- */
static esp_target_t g_targets[ESP_MAX_TARGETS];
static int          g_count = 0;

static esp_config_t g_cfg;

/* Estadisticas para el calibrador. */
static uint64_t g_calls_aabb    = 0;
static uint64_t g_calls_name    = 0;
static uint64_t g_calls_dead    = 0;
static uint64_t g_calls_health  = 0;
static float    g_last6[8];       /* lo que devolvio el ultimo AABB */
static int      g_last6_n = 0;
static uint64_t g_distinct_self = 0;

static double now_sec(void)
{
    return (double)CACurrentMediaTime();
}

/* --------------------------------------------------------------------- */
/* Tabla                                                                  */
/* --------------------------------------------------------------------- */
static esp_target_t *find_or_add(uint64_t id, double now)
{
    for (int i = 0; i < g_count; i++)
        if (g_targets[i].id == id && g_targets[i].valid) return &g_targets[i];

    /* Reaprovecha una invalida antes de crecer. */
    for (int i = 0; i < g_count; i++)
        if (!g_targets[i].valid) {
            memset(&g_targets[i], 0, sizeof(g_targets[i]));
            g_targets[i].id = id;
            g_targets[i].valid = true;
            g_targets[i].last_seen = now;
            return &g_targets[i];
        }

    if (g_count < ESP_MAX_TARGETS) {
        esp_target_t *t = &g_targets[g_count++];
        memset(t, 0, sizeof(*t));
        t->id = id;
        t->valid = true;
        t->last_seen = now;
        return t;
    }
    return NULL;
}

void esp_targets_feed(uint64_t self_ptr, const float *floats, int n_floats,
                      double now)
{
    if (!self_ptr || !floats || n_floats < 3) return;

    esp_target_t *t = find_or_add(self_ptr, now);
    if (!t) return;
    t->last_seen = now;
    t->hits++;

    if (t->hits == 1) g_distinct_self++;

    /* Interpreta segun la disposicion configurada. */
    switch (g_cfg.aabb_layout) {
    case AABB_CENTER_SIZE:
        for (int i = 0; i < 3; i++) {
            t->center[i] = floats[i];
            float h = floats[3 + i] * 0.5f;
            t->min[i] = floats[i] - h;
            t->max[i] = floats[i] + h;
        }
        break;
    case AABB_ORIGIN_SIZE:
        for (int i = 0; i < 3; i++) {
            t->center[i] = floats[i];
            float h = floats[3 + i] * 0.5f;
            t->min[i] = floats[i] - h;
            t->max[i] = floats[i] + h;
        }
        break;
    case AABB_MINMAX8:
    case AABB_MINMAX6:
    default:
        for (int i = 0; i < 3; i++) {
            t->min[i] = floats[i];
            t->max[i] = floats[3 + i];
        }
        t->center[0] = (t->min[0] + t->max[0]) * 0.5f;
        t->center[1] = (t->min[1] + t->max[1]) * 0.5f;
        t->center[2] = (t->min[2] + t->max[2]) * 0.5f;
        break;
    }

    /* Guarda la muestra cruda para que el calibrador pueda compararla. */
    int n = n_floats > 8 ? 8 : n_floats;
    for (int i = 0; i < n; i++) g_last6[i] = floats[i];
    g_last6_n = n;
}

int esp_targets_snapshot(esp_target_t *out, int max)
{
    double now = now_sec();
    int n = 0;
    for (int i = 0; i < g_count && n < max; i++) {
        esp_target_t *t = &g_targets[i];
        if (!t->valid) continue;
        if (now - t->last_seen > ESP_AGE_TTL) { t->valid = false; continue; }
        out[n++] = *t;
    }
    return n;
}

/* --------------------------------------------------------------------- */
/* Base de carga del 'cod'                                                */
/* --------------------------------------------------------------------- */
/* La tabla guarda los offsets como VA - 0x100000000, porque en el binario en
   disco el file offset coincide con VA menos la base de __TEXT. En memoria NO.

   En runtime, _dyld_get_image_vmaddr_slide() da el desplazamiento de la
   imagen, y una funcion del file offset F vive en:

       runtime = slide + vmaddr_de___TEXT + F

   Ojo al signo: con slide 0 (caso normal en iOS sin ASLR de dylibs propias) la
   funcion esta en 0x100000000 + F, no en F. Devolver solo slide + F apuntaba
   4 GB mas abajo, y el hook escribia encima de memoria sin relacion: de ahi
   el crash al arrancar. */
static int64_t g_slide      = 0;
static uint64_t g_text_vm   = 0;     /* vmaddr del segmento __TEXT */
static uint64_t g_text_end  = 0;     /* vmaddr + tamano, para validar */
static bool    g_base_ok    = false;

static bool read_text_segment(const struct mach_header *mh)
{
    uint32_t ncmds = mh->ncmds;
    /* struct, si o si: en <mach-o/loader.h> mach_header_64 es un tag, no un
       typedef, y en C el nombre a pelo no compila. */
    const uint8_t *p = (const uint8_t *)mh + sizeof(struct mach_header_64);
    for (uint32_t i = 0; i < ncmds; i++) {
        const struct load_command *lc = (const struct load_command *)p;
        if (lc->cmd == LC_SEGMENT_64) {
            const struct segment_command_64 *sg = (const struct segment_command_64 *)lc;
            if (strncmp(sg->segname, "__TEXT", 7) == 0) {
                g_text_vm  = sg->vmaddr;
                g_text_end = sg->vmaddr + sg->vmsize;
                return true;
            }
        }
        p += lc->cmdsize;
    }
    return false;
}

static bool resolve_base(void)
{
    uint32_t count = _dyld_image_count();
    const struct mach_header *found = NULL;

    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (!name) continue;
        const char *base = strrchr(name, '/');
        base = base ? base + 1 : name;
        if (strcmp(base, "cod") == 0 || strcmp(base, "cod.debug.dylib") == 0) {
            g_slide = (int64_t)_dyld_get_image_vmaddr_slide(i);
            found   = _dyld_get_image_header(i);
            break;
        }
    }
    if (!found) {
        /* Reserva: la primera MH_EXECUTE. Puede no ser el juego, asi que luego
           se comprueba que su __TEXT tenga un tamano razonable. */
        for (uint32_t i = 0; i < count; i++) {
            const struct mach_header *mh = _dyld_get_image_header(i);
            if (!mh || mh->filetype != MH_EXECUTE) continue;
            g_slide = (int64_t)_dyld_get_image_vmaddr_slide(i);
            found   = mh;
            break;
        }
    }
    if (!found) return false;

    if (!read_text_segment(found)) return false;
    /* El binario del juego tiene del orden de 200 MB de __TEXT. Si sale
       pequeño, no estamos mirando al binario principal y enganchar ahi
       escribiria sobre lo que sea. */
    if (g_text_end - g_text_vm < (16u << 20)) {
        NSLog(@"[ESP] __TEXT de 0x%llx es demasiado pequeno (0x%llx B): no engancho",
              (unsigned long long)g_text_vm, (unsigned long long)(g_text_end - g_text_vm));
        return false;
    }

    g_base_ok = true;
    return true;
}

/* Convierte un offset de la tabla en direccion real. NULL si no resuelve o si
   cae fuera de __TEXT, que es senal de que el offset es de otra build. */
void *esp_resolve(int64_t off)
{
    if (!g_base_ok || off < 0) return NULL;
    uint64_t va = g_text_vm + (uint64_t)off;
    if (va < g_text_vm || va >= g_text_end) return NULL;      /* fuera de __TEXT */
    return (void *)(uint64_t)(g_slide + (int64_t)va);
}

/* --------------------------------------------------------------------- */
/* Detours                                                                */
/* --------------------------------------------------------------------- */
typedef void (*fn_aabb_t)(void *self, float *out, float *out2, float *out3);
typedef float (*fn_f1_t)(void *self);
typedef const char *(*fn_str_t)(void *self);

static fn_aabb_t g_orig_aabb;
static fn_f1_t   g_orig_dead;
static fn_f1_t   g_orig_health;
static fn_str_t  g_orig_name;

/* El juego llama a GetPlayerAABB por jugador y por frame. Anotamos el self y
   leemos los flotantes que deja en el segundo argumento. */
static void esp_detour_aabb(void *self, float *out, float *out2, float *out3)
{
    g_calls_aabb++;
    if (out) {
        g_last6_n = 8;
        memcpy(g_last6,     out,  sizeof(float) * 4);
        if (out2) memcpy(g_last6 + 4, out2, sizeof(float) * 4);
    }
    if (g_orig_aabb) g_orig_aabb(self, out, out2, out3);
    esp_targets_feed((uint64_t)self, out, out ? 8 : 0, now_sec());
}

static float esp_detour_health(void *self)
{
    float v = g_orig_health ? g_orig_health(self) : 0.0f;
    g_calls_health++;
    for (int i = 0; i < g_count; i++)
        if (g_targets[i].valid && g_targets[i].id == (uint64_t)self)
            g_targets[i].health = v;
    return v;
}

static float esp_detour_dead(void *self)
{
    float v = g_orig_dead ? g_orig_dead(self) : 0.0f;
    g_calls_dead++;
    for (int i = 0; i < g_count; i++)
        if (g_targets[i].valid && g_targets[i].id == (uint64_t)self)
            g_targets[i].alive = (v < 0.5f);
    return v;
}

static const char *esp_detour_name(void *self)
{
    const char *s = g_orig_name ? g_orig_name(self) : NULL;
    g_calls_name++;
    if (s) {
        for (int i = 0; i < g_count; i++)
            if (g_targets[i].valid && g_targets[i].id == (uint64_t)self) {
                strncpy(g_targets[i].name, s, sizeof(g_targets[i].name) - 1);
                g_targets[i].name[sizeof(g_targets[i].name) - 1] = 0;
            }
    }
    return s;
}

/* --------------------------------------------------------------------- */
/* Arranque                                                               */
/* --------------------------------------------------------------------- */
int esp_targets_start(const esp_config_t *cfg)
{
    /* --------------------------------------------------------------------- */
/* Sondas: mirar sin tocar                                                  */
/* --------------------------------------------------------------------- */
/* Una entrada a funcion arm64 empieza casi siempre por uno de estos grupos.
   Si no encaja en ninguno, esa direccion no es el principio de una funcion y
   parchear ahi es escribir encima de otra cosa. */
bool esp_probe_prologue(const uint8_t *raw, char *why, size_t whyn)
{
    uint32_t i0 = ((uint32_t)raw[0] << 24) | ((uint32_t)raw[1] << 16) |
                  ((uint32_t)raw[2] <<  8) |  (uint32_t)raw[3];

    /* Todos los bytes a cero: memoria sin inicializar, no codigo. */
    if (i0 == 0) { snprintf(why, whyn, "todo ceros, no es codigo"); return false; }

    /* BRK, SVC, udf: si esta aqui, no es un prologo. */
    if ((i0 & 0xFFE0001Fu) == 0xD4000001u || (i0 & 0xFFE0001Fu) == 0xD4200000u) {
        snprintf(why, whyn, "primera instruccion es BRK/SVC"); return false;
    }

    /* Salto incondicional: es una funcion de una instruccion o un tail call,
       no un punto de entrada con prologo conservable. */
    if ((i0 & 0x7C000000u) == 0x14000000u) {
        snprintf(why, whyn, "empieza con un salto"); return false;
    }

    /* Lo que si se acepta como entrada: */
    uint8_t top = (uint8_t)(i0 >> 24);
    if (top == 0xA9 || top == 0xA8 ||   /* STP / LDP 64 */
        top == 0xA5 || top == 0xA4 ||   /* STP / LDP 32 */
        top == 0xD1 || top == 0x91 ||   /* SUB SP / MOV-ADR */
        top == 0xD6 ||                   /* RET de hoja */
        top == 0xF9 || top == 0xB9 ||   /* STR / LD registros */
        top == 0x10 || top == 0x11 ||   /* ADR / ADRP */
        top == 0x12 || top == 0x52 || top == 0xD3)
        return true;

    snprintf(why, whyn, "primera instruccion 0x%08X no parece un prologo", i0);
    return false;
}

const char *esp_probe_one(const char *label, int64_t off, uint8_t *prologue_out)
{
    static char verdict[160];
    uint8_t buf[16];
    char why[96];

    (void)label;
    if (off < 0) {
        snprintf(verdict, sizeof(verdict), "sin resolver");
        return verdict;
    }
    if (!g_base_ok) {
        snprintf(verdict, sizeof(verdict), "sin base de carga");
        return verdict;
    }

    uint64_t va  = g_text_vm + (uint64_t)off;
    void    *at = (void *)(uint64_t)(g_slide + (int64_t)va);

    if (va < g_text_vm || va >= g_text_end) {
        snprintf(verdict, sizeof(verdict), "FUERA de __TEXT (offset de otra build?)");
        return verdict;
    }

    memcpy(buf, at, 16);
    if (prologue_out) memcpy(prologue_out, buf, 16);

    if (!esp_probe_prologue(buf, why, sizeof(why))) {
        snprintf(verdict, sizeof(verdict), "no parece funcion: %s", why);
        return verdict;
    }

    snprintf(verdict, sizeof(verdict), "ok");
    return verdict;
}

/* Las cuatro enganchables, sin escribir nada. */
int esp_probe_all(void)
{
    if (!resolve_base()) return 0;
    int good = 0;
    struct { const char *n; int64_t v; } L[] = {
        { "player_aabb", g_cfg.off.player_aabb },
        { "is_dead",     g_cfg.off.is_dead },
        { "health",      g_cfg.off.health },
        { "name",        g_cfg.off.player_name },
    };
    for (unsigned i = 0; i < sizeof(L)/sizeof(L[0]); i++) {
        const char *v = esp_probe_one(L[i].n, L[i].v, NULL);
        NSLog(@"[ESP-PROBE] %-12s %s", L[i].n, v);
        if (v[0] == 'o' && v[1] == 'k') good++;
    }
    return good;
}

/* --------------------------------------------------------------------- */
/* Arranque                                                               */
/* --------------------------------------------------------------------- */
char msg[220];
    g_cfg = *cfg;
    if (!resolve_base()) {
        NSLog(@"[ESP] no se resolvio la base de carga de 'cod': no se engancha nada.");
        return 0;
    }
    esp_fmt(msg, sizeof(msg),
            "[+] ESP: base slide=0x%llx __TEXT=0x%llx (%llu MB)",
            (unsigned long long)g_slide, (unsigned long long)g_text_vm,
            (unsigned long long)((g_text_end - g_text_vm) >> 20));
    NSLog(@"%s", msg);

    /* ---- aqui esta el cambio de fondo ----------------------------------
       Por defecto NO se parchea nada. Se mira, se apunta que se ha mirado y
       ya. Escribir en la __TEXT del juego al arrancar es lo unico de toda la
       ESP que puede tumbar la app, y no tiene sentido arriesgarlo sin saber
       antes si los offsets son de esta build. */
    if (!cfg->enable_hooks) {
        int good = esp_probe_all();
        esp_fmt(msg, sizeof(msg),
                "[i] ESP: MODO INSPECCION (sin hooks): %d de 4 offsets parecen funciones.",
                good);
        NSLog(@"%s", msg);
        esp_fmt(msg, sizeof(msg),
                "[i] ESP: no se ha escrito nada en el binario del juego.");
        NSLog(@"%s", msg);
        return 0;
    }

    /* Antes de un solo mprotect, se comprueba que los cuatro destinos parecen
       funciones. Si alguno no encaja, no se engancha ninguno: es mas util no
       tener ESP que perderla en un crash. */
    struct { const char *n; int64_t v; } L[] = {
        { "player_aabb", cfg->off.player_aabb },
        { "is_dead",     cfg->off.is_dead },
        { "health",      cfg->off.health },
        { "name",        cfg->off.player_name },
    };
    for (unsigned i = 0; i < sizeof(L)/sizeof(L[0]); i++) {
        const char *v = esp_probe_one(L[i].n, L[i].v, NULL);
        if (v[0] == 'o' && v[1] == 'k') continue;
        esp_fmt(msg, sizeof(msg),
                "[!] ESP: %s no parece una funcion (%s). No se engancha nada.", L[i].n, v);
        NSLog(@"%s", msg);
        return 0;
    }

/* Engancha un offset. Si esp_resolve devuelve NULL es que cae fuera de __TEXT,
   o sea que el offset es de otra build: no se intenta parchear. */
#define HOOK_ONE(label, field, detour, orig) do { \
        void *p_ = esp_resolve(cfg->off.field); \
        if (p_ && esp_hook_install(p_, (void *)detour, (void **)&orig, &why)) { \
            installed++; \
        } else if (cfg->off.field >= 0) { \
            if (!p_) esp_fmt(msg, sizeof(msg), \
                "[!] ESP: %s fuera de __TEXT: el offset 0x%llx no es de esta build.", \
                label, (unsigned long long)cfg->off.field); \
            else     esp_fmt(msg, sizeof(msg), "[!] ESP: hook %s fallo: %s", label, why ? why : "?"); \
            NSLog(@"%s", msg); \
        } \
    } while (0)

    const char *why = NULL;
    int installed = 0;

    HOOK_ONE("AABB",    player_aabb, esp_detour_aabb,    g_orig_aabb);
    HOOK_ONE("is_dead", is_dead,     esp_detour_dead,    g_orig_dead);
    HOOK_ONE("health",  health,      esp_detour_health,  g_orig_health);
    HOOK_ONE("name",    player_name, esp_detour_name,    g_orig_name);

#undef HOOK_ONE

    esp_fmt(msg, sizeof(msg), "[+] ESP: %d hooks puestos de 4", installed);
    NSLog(@"%s", msg);
    return installed;
}

void esp_targets_stop(void)
{
    for (int i = 0; i < esp_hook_count(); i++) esp_hook_remove(i);
    g_count = 0;
}

/* --------------------------------------------------------------------- */
/* Render                                                                 */
/* --------------------------------------------------------------------- */
void esp_render_frame(void *cgctx, float width, float height)
{
    /* La camara se lee aqui, una vez por frame. Si los offsets de matriz no
       estan resueltos esto no hace nada y las cajas simplemente no salen. */
    esp_pump_matrices();

    esp_target_t snap[ESP_MAX_TARGETS];
    int n = esp_targets_snapshot(snap, ESP_MAX_TARGETS);
    if (n <= 0) return;

    for (int i = 0; i < n; i++) {
        esp_target_t *t = &snap[i];

        /* Proyecta las 8 esquinas y se queda con el AABB en pantalla. */
        float lx = 1e9f, ly = 1e9f, hx = -1e9f, hy = -1e9f;
        bool behind = true;
        for (int c = 0; c < 8; c++) {
            float wx = (c & 1) ? t->max[0] : t->min[0];
            float wy = (c & 2) ? t->max[1] : t->min[1];
            float wz = (c & 4) ? t->max[2] : t->min[2];
            float sx, sy;
            if (!esp_project(wx, wy, wz, &sx, &sy)) continue;
            behind = false;
            if (sx < lx) lx = sx;  if (sx > hx) hx = sx;
            if (sy < ly) ly = sy;  if (sy > hy) hy = sy;
        }
        if (behind) continue;      /* detras de la camara: no se dibuja */

        float bw = hx - lx, bh = hy - ly;
        if (bw < 1 || bh < 1) continue;

        /* Cono de vision, si esta puesto. */
        if (g_cfg.fov_degrees > 0.5f) {
            float fcx, fcy;
            if (esp_project(t->center[0], t->center[1], t->center[2], &fcx, &fcy)) {
                float dx = fcx - width  * 0.5f, dy = fcy - height * 0.5f;
                float ang = atan2f(dy, dx) * 57.2957795f;
                if (ang < 0) ang += 360.0f;
                if (ang < g_cfg.fov_degrees * 0.5f || ang > 360.0f - g_cfg.fov_degrees * 0.5f)
                    continue;
            }
        }

        /* Distancia y rango maximo. */
        char buf[64];
        float dx = t->center[0], dy = t->center[1], dz = t->center[2];
        float dist = sqrtf(dx * dx + dy * dy + dz * dz);
        if (g_cfg.max_distance > 0.5f && dist > g_cfg.max_distance) continue;

        uint32_t col = t->alive ? g_cfg.color_enemy : g_cfg.color_dead;

        if (g_cfg.draw_snapline) {
            float ty = g_cfg.snapline_height_px > 0 ? height : hy;
            esp_draw_line(width * 0.5f, ty, (lx + hx) * 0.5f, hy,
                          esp_argb(col, 0.35f), 1.0f);
        }
        if (g_cfg.draw_box)
            esp_draw_box(lx, ly, bw, bh, col, g_cfg.box_thickness);
        if (g_cfg.draw_corner_box)
            esp_draw_corners(lx, ly, bw, bh, col, g_cfg.box_thickness,
                             g_cfg.corner_ratio);

        /* Barra de vida vertical a la izquierda de la caja. */
        if (g_cfg.draw_health) {
            float hp = t->health;
            if (hp < 0) hp = 0;
            if (hp > 100) hp = 100;
            float bh2 = bh * (hp / 100.0f);
            esp_draw_filled(lx - 4.0f, ly, 2.5f, bh, esp_argb(0x202020, 0.55f));
            esp_draw_filled(lx - 4.0f, ly + bh - bh2, 2.5f, bh2,
                            esp_argb(g_cfg.color_health, 0.95f));
        }

        float ty = ly - 12.0f;
        if (g_cfg.draw_name && t->name[0]) {
            esp_draw_text_shadow((lx + hx) * 0.5f, ty, 11.0f,
                                 g_cfg.color_text, true, t->name);
            ty -= 13.0f;
        }
        if (g_cfg.draw_distance) {
            esp_fmt(buf, sizeof(buf), "%.0fm", dist);
            esp_draw_text_shadow((lx + hx) * 0.5f, ty, 10.0f,
                                 esp_argb(g_cfg.color_text, 0.85f), true, buf);
        }
    }

    if (g_cfg.draw_fov_circle && g_cfg.fov_radius_px > 0)
        esp_draw_circle(width * 0.5f, height * 0.5f, g_cfg.fov_radius_px,
                        esp_argb(g_cfg.color_text, 0.12f), 1.0f);
}

/* --------------------------------------------------------------------- */
/* Calibrador                                                             */
/* --------------------------------------------------------------------- */
/* El informe va a Documents/, no a /tmp/.
   /tmp esta dentro del sandbox y en un telefono sin jailbreak no hay manera de
   sacarlo. Documents/ si se ve desde la app Archivos si el Info.plist lleva
   UIFileSharingEnabled, que es lo que pone la herramienta cuando marca
   calibrar. */
static const char *calib_path(void)
{
    static char buf[512];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *dir = paths.firstObject ?: NSTemporaryDirectory();
    snprintf(buf, sizeof(buf), "%s/esp-calib.txt", [dir UTF8String]);
    return buf;
}

void esp_targets_calib_dump(void)
{
    const char *path = calib_path();
    FILE *f = fopen(path, "w");
    if (!f) {
        NSLog(@"[ESP] no se pudo escribir el informe en %s", path);
        return;
    }

    fprintf(f, "# ESP calibracion\n");
    fprintf(f, "slide_base      = 0x%llx\n", (unsigned long long)g_slide);
    fprintf(f, "text_vmaddr     = 0x%llx\n", (unsigned long long)g_text_vm);
    fprintf(f, "text_vmsize     = 0x%llx (%llu MB)\n",
            (unsigned long long)(g_text_end - g_text_vm),
            (unsigned long long)((g_text_end - g_text_vm) >> 20));
    fprintf(f, "base_resuelta   = %s\n", g_base_ok ? "si" : "no");

    /* Cada offset: resuelto, dentro de __TEXT, y los primeros 16 bytes para
       poder reconocerlos. NO se escribe nada en el juego. */
    fprintf(f, "\n#Sondas (solo lectura: no se escribe nada en el cod)\n");
    {
        struct { const char *n; int64_t v; } offs[] = {
            { "player_aabb",      g_cfg.off.player_aabb },
            { "player_target",    g_cfg.off.player_target_point },
            { "player_name",      g_cfg.off.player_name },
            { "player_state",     g_cfg.off.player_state },
            { "is_dead",          g_cfg.off.is_dead },
            { "health",           g_cfg.off.health },
            { "view_matrix",      g_cfg.off.view_matrix },
            { "proj_matrix",      g_cfg.off.proj_matrix },
        };
        for (unsigned i = 0; i < sizeof(offs)/sizeof(offs[0]); i++) {
            uint8_t pro[16];
            memset(pro, 0, sizeof(pro));
            const char *v = esp_probe_one(offs[i].n, offs[i].v, pro);
            fprintf(f, "  %-16s off=0x%-9llx  %s\n", offs[i].n,
                    (unsigned long long)offs[i].v, v);
            fprintf(f, "      bytes:");
            for (int k = 0; k < 16; k++) fprintf(f, " %02X", pro[k]);
            fprintf(f, "\n");
        }
    }
    fprintf(f, "hooks_puestos   = %d\n", esp_hook_count());
    fprintf(f, "llamadas AABB   = %llu\n", (unsigned long long)g_calls_aabb);
    fprintf(f, "llamadas name   = %llu\n", (unsigned long long)g_calls_name);
    fprintf(f, "llamadas dead   = %llu\n", (unsigned long long)g_calls_dead);
    fprintf(f, "llamadas health = %llu\n", (unsigned long long)g_calls_health);
    fprintf(f, "jugadores_distintos = %llu\n", (unsigned long long)g_distinct_self);
    fprintf(f, "objetos_vivos   = %d\n", g_count);
    fprintf(f, "disposicion     = %d (0=minmax6 1=minmax8 2=center_size 3=origin_size 4=dagor)\n",
            (int)g_cfg.aabb_layout);
    fprintf(f, "\n#Ultimo AABB crudo (%d flotantes)\n", g_last6_n);
    for (int i = 0; i < g_last6_n; i++) fprintf(f, "  aabb[%d] = %f\n", i, g_last6[i]);

    fprintf(f, "\n#Objetos\n");
    esp_target_t snap[ESP_MAX_TARGETS];
    int n = esp_targets_snapshot(snap, ESP_MAX_TARGETS);
    for (int i = 0; i < n; i++) {
        fprintf(f, "  0x%llx  hits=%u  hp=%.1f  alive=%d  name='%s'\n",
                (unsigned long long)snap[i].id, snap[i].hits, snap[i].health,
                snap[i].alive ? 1 : 0, snap[i].name);
        fprintf(f, "      min(%.2f %.2f %.2f)  max(%.2f %.2f %.2f)\n",
                snap[i].min[0], snap[i].min[1], snap[i].min[2],
                snap[i].max[0], snap[i].max[1], snap[i].max[2]);
    }

    /* Las matrices: si no estan resueltas esto sale vacio y es la pista de
       que falta el offset. */
    float v[16], p[16];
    esp_overlay_get_matrices(v, p);
    fprintf(f, "\n#Matrices\n  view = ");
    for (int i = 0; i < 16; i++) fprintf(f, "%s%f", i ? "," : "", v[i]);
    fprintf(f, "\n  proj = ");
    for (int i = 0; i < 16; i++) fprintf(f, "%s%f", i ? "," : "", p[i]);
    fprintf(f, "\n");

    fclose(f);

    /* Lo mismo, pero por NSLog. Es la unica via si instalas idevicesyslog, y
       de paso deja las cuatro cifras clave en el log del sistema sin tener que
       abrir ningun fichero. */
    NSLog(@"[ESP-CALIB] slide=0x%llx base=%d hooks=%d",
          (unsigned long long)g_slide, g_base_ok ? 1 : 0, esp_hook_count());
    NSLog(@"[ESP-CALIB] llamadas_AABB=%llu distintos=%llu objetos_vivos=%d",
          (unsigned long long)g_calls_aabb, (unsigned long long)g_distinct_self, g_count);
    NSLog(@"[ESP-CALIB] nombre=%llu muerto=%llu vida=%llu",
          (unsigned long long)g_calls_name, (unsigned long long)g_calls_dead,
          (unsigned long long)g_calls_health);
    NSLog(@"[ESP-CALIB] disposicion=%d floats=%d  informe en %s",
          (int)g_cfg.aabb_layout, g_last6_n, path);
}

int esp_targets_calib_aabb_candidates(void) { return (int)AABB__COUNT; }