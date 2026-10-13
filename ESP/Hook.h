/*=============================================================================
 *  Hook.h  -  inline hook arm64
 *  ----------------------------------------------------------------------
 *  Sustituye el prologo de una funcion por un salto absoluto y deja una
 *  trampolina con el prologo original. Ver Hook.m para el detalle de como
 *  decide que instrucciones se pueden copiar.
 *
 *  Dos reglas del contrato, porque rompen si no se respetan:
 *
 *   1. El destino (detour) recibe los mismos argumentos. Si necesita el
 *      comportamiento original, llama a *out_orig, que es la trampolina.
 *   2. No se instala si el prologo no se puede reubicar entero. En ese caso
 *      devuelve false y explica por que. Es preferible no enganchar a
 *      enganchar mal: un gancho a medias revienta el juego al primer frame.
 *============================================================================*/

#ifndef HOOK_H
#define HOOK_H

#include "ESP.h"

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

/*
 * Instala un gancho. Devuelve true si quedo puesto.
 * Si devuelve false, *why apunta al motivo (cadena estatica, no liberar).
 * out_orig, si no es NULL, recibe la trampolina.
 */
bool esp_hook_install(void *target, void *detour, void **out_orig, const char **why);

/* Lo deja como estaba. Por indice de esp_hook_at(). */
void        esp_hook_remove(int slot);

int          esp_hook_count(void);
esp_hook_t  *esp_hook_at(int slot);
uint64_t     esp_hook_target(int slot);

#endif /* HOOK_H */