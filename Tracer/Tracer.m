/*=============================================================================
 *  Tracer.m  -  dylib de diagnostico: traza quien llama a las funciones de
 *  recoil mientras se juega, para encontrar el aplicador real del kick.
 *
 *  Al cargar: calcula el slide del ejecutable principal, resuelve las VAs de
 *  las funciones de recoil (VA estatica + slide) y les instala un gancho. El
 *  detour (en Detours.s) loguea la direccion de retorno del que la llamo y
 *  pasa de largo a la trampolina, asi el juego funciona igual.
 *
 *  Salida: Documents/recoil-trace.txt  (sacalo por Archivos > En mi iPhone >
 *  CODMOBILE). Cada linea = un caller NUEVO, como VA estatica (ya sin slide),
 *  lista para mapear en Ghidra.
 *============================================================================*/

#include "Tracer.h"
#include "Hook.h"
#include <mach-o/dyld.h>
#include <mach-o/loader.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* ---- globales que usa el asm (Detours.s) ---- */
void *g_tramp[5];                 /* trampolinas por slot */
extern void tracer_detour_0(void);
extern void tracer_detour_1(void);
extern void tracer_detour_2(void);
extern void tracer_detour_3(void);
extern void tracer_detour_4(void);

/* ---- estado ---- */
static intptr_t      g_slide = 0;
static pthread_mutex_t g_mtx = PTHREAD_MUTEX_INITIALIZER;
static char          g_path[1024];

/* dedup de callers por slot: hasta 64 por slot */
#define MAX_SEEN 64
static uint64_t g_seen[5][MAX_SEEN];
static int      g_seen_n[5];
static uint64_t g_hits[5][MAX_SEEN];

/* VAs estaticas (base __TEXT = 0x100000000) de las funciones de recoil 1.0.57 */
static const struct { uint64_t va; const char *name; } g_targets[5] = {
    { 0x102892F90ULL, "GetRecoilUpModifier" },
    { 0x100E95C44ULL, "GetRecoilLateralMax" },
    { 0x10740A608ULL, "RecoilUpMax" },
    { 0x10740DA5CULL, "RecoilScaleStanding" },
    { 0x10740DC08ULL, "RecoilScaleCrouch" },
};

static void trace_path(void)
{
    const char *home = getenv("HOME");
    if (!home) home = "/tmp";
    snprintf(g_path, sizeof(g_path), "%s/Documents/recoil-trace.txt", home);
}

static void trace_append(const char *line)
{
    FILE *f = fopen(g_path, "a");
    if (!f) return;
    fputs(line, f);
    fputc('\n', f);
    fclose(f);
}

/* llamada desde el detour (Detours.s). slot = indice, caller = x30 original. */
void tracer_log(int slot, void *caller)
{
    if (slot < 0 || slot >= 5) return;
    uint64_t cva = (uint64_t)((uintptr_t)caller - g_slide); /* a VA estatica */
    pthread_mutex_lock(&g_mtx);
    int n = g_seen_n[slot];
    for (int i = 0; i < n; i++) {
        if (g_seen[slot][i] == cva) { g_hits[slot][i]++; pthread_mutex_unlock(&g_mtx); return; }
    }
    if (n < MAX_SEEN) {
        g_seen[slot][n] = cva;
        g_hits[slot][n] = 1;
        g_seen_n[slot] = n + 1;
        char line[160];
        snprintf(line, sizeof(line),
                 "[%s] caller VA 0x%llX  (slot %d) <-- NUEVO",
                 g_targets[slot].name, (unsigned long long)cva, slot);
        trace_append(line);
    }
    pthread_mutex_unlock(&g_mtx);
}

static intptr_t main_slide(void)
{
    uint32_t c = _dyld_image_count();
    for (uint32_t i = 0; i < c; i++) {
        const struct mach_header *h = _dyld_get_image_header(i);
        if (h && h->filetype == MH_EXECUTE) return _dyld_get_image_vmaddr_slide(i);
    }
    return _dyld_get_image_vmaddr_slide(0);
}

__attribute__((constructor))
static void tracer_init(void)
{
    trace_path();
    g_slide = main_slide();

    void (*detours[5])(void) = {
        tracer_detour_0, tracer_detour_1, tracer_detour_2, tracer_detour_3, tracer_detour_4
    };

    char hdr[256];
    snprintf(hdr, sizeof(hdr),
             "==== recoil-trace  slide=0x%lX  base_runtime=0x%lX ====",
             (long)g_slide, (long)(0x100000000L + g_slide));
    trace_append(hdr);

    for (int i = 0; i < 5; i++) {
        void *target = (void *)((uintptr_t)g_targets[i].va + (uintptr_t)g_slide);
        const char *why = NULL;
        bool ok = esp_hook_install(target, (void *)detours[i], &g_tramp[i], &why);
        char line[200];
        snprintf(line, sizeof(line), "hook %d %s @0x%llX runtime=0x%lX : %s%s",
                 i, g_targets[i].name, (unsigned long long)g_targets[i].va,
                 (long)(uintptr_t)target, ok ? "OK" : "FALLO ",
                 ok ? "" : (why ? why : "?"));
        trace_append(line);
    }
    trace_append("---- jugá un rato disparando; cada caller NUEVO se anota arriba ----");
}
