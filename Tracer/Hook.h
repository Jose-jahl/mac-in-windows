/*=============================================================================
 *  Hook.h  -  inline hook arm64 (copia del ESP; incluye Tracer.h en vez de ESP.h)
 *  Ver Hook.m para el detalle del trampolin.
 *============================================================================*/
#ifndef HOOK_H
#define HOOK_H

#include "Tracer.h"

#define MAX_HOOKS 16

typedef struct {
    void    *target;        /* direccion real de la funcion enganchada */
    void    *detour;
    void    *trampoline;    /* prologo original, en pagina RX */
    void    *page;          /* pagina mmap de la trampolina */
    size_t   page_size;
    uint32_t patch[4];      /* los 16 bytes que se sobrescribieron */
    size_t   patched_size;
    bool     installed;
    char     error[96];
} esp_hook_t;

bool esp_hook_install(void *target, void *detour, void **out_orig, const char **why);
void        esp_hook_remove(int slot);
int          esp_hook_count(void);
esp_hook_t  *esp_hook_at(int slot);
uint64_t     esp_hook_target(int slot);

#endif /* HOOK_H */
