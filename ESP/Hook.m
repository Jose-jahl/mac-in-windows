/*=============================================================================
 *  Hook.m  -  inline hook arm64 para ESP.dylib
 *  ----------------------------------------------------------------------
 *  Sustituye el prologo de una funcion por un salto absoluto a la funcion
 *  destino y deja una trampolina que ejecuta el prologo original antes de
 *  volver. Es lo que permite enganchar GetPlayerAABB ycompany sin tocar la
 *  logica del juego.
 *
 *  El salto absoluto ocupa 16 bytes:
 *
 *      LDR  X16, #8        0x58000050
 *      BR   X16            0xD61F0200
 *      .quad  destino
 *
 *  La trampolina copia el prologo original instruccion a instruccion. Solo
 *  copia las que se pueden mover tal cual a otra direccion; ADR y ADRP se
 *  reubican (son relativas a PC y si no, el codigo copiado apuntaria al
 *  sitio viejo). Si aparece cualquier otra cosa relativa a PC --una rama
 *  condicional, un LDR literal-- el hook se aborta y se reporta el motivo,
 *  en vez de instalar un gancho que reviente el juego al primer frame.
 *============================================================================*/

#include "ESP.h"
#include "Hook.h"
#include <mach/mach.h>
#include <sys/mman.h>
#include <unistd.h>      /* sysconf, para el tamano de pagina */
#include <string.h>
#include <stdio.h>
#include <libkern/OScacheControl.h>

static esp_hook_t g_hooks[MAX_HOOKS];
static int        g_hook_count = 0;

/* --------------------------------------------------------------------- */
/* Clasificacion de instrucciones arm64                                     */
/* --------------------------------------------------------------------- */

/* Ramas que no se pueden copiar: alteran el flujo de control. */
static inline bool is_branch(uint32_t i)
{
    if ((i & 0xFC000000u) == 0x14000000u) return true;  /* B   */
    if ((i & 0xFC000000u) == 0x94000000u) return true;  /* BL  */
    if ((i & 0xFF000010u) == 0x54000000u) return true;  /* B.cond */
    if ((i & 0x7E000000u) == 0x34000000u) return true;  /* CBZ/CBNZ  */
    if ((i & 0x7E000000u) == 0x36000000u) return true;  /* TBZ/TBNZ  */
    if ((i & 0xFE000000u) == 0xD6000000u) return true;  /* BR/BLR/RET */
    if ((i & 0xFFE0001Fu) == 0xD4000001u) return true;  /* SVC */
    if ((i & 0xFFE0001Fu) == 0xD4200000u) return true;  /* BRK */
    return false;
}

/* ADR  /  ADRP -- relativas a PC, hay que reubicar. */
static inline bool is_adrp(uint32_t i) { return (i & 0x9F000000u) == 0x90000000u; }
static inline bool is_adr (uint32_t i) { return (i & 0x9F000000u) == 0x10000000u; }

/* LDR literal (32 y 64 bits). */
static inline bool is_ldr_lit(uint32_t i) { return (i & 0x3B000000u) == 0x18000000u; }

/* Decodifica el immhi:immlo de ADRP/ADR (21 bits con signo, en unidades de 4
   para ADR y de 4096 para ADRP). */
static inline int32_t pc_rel_imm(uint32_t i)
{
    uint32_t immlo = (i >> 29) & 0x3u;
    uint32_t immhi = (i >> 5)  & 0x7FFFFu;
    return (int32_t)((immhi << 2) | immlo) << 2;      /* immhi:immlo, x4 */
}

static inline uint32_t with_pc_rel_imm(uint32_t i, int32_t imm21_in_4s)
{
    uint32_t imm = ((uint32_t)imm21_in_4s >> 2) & 0x1FFFFFu;
    uint32_t immlo = imm & 0x3u;
    uint32_t immhi = (imm >> 2) & 0x7FFFFu;
    return (i & 0x9F00001Fu) | (immlo << 29) | (immhi << 5);
}

/* --------------------------------------------------------------------- */
/* Escritura del codigo enganchado                                          */
/* --------------------------------------------------------------------- */

/* sysprotect() no esta declarado en el SDK de iOS, asi que se usa mprotect(),
   que es POSIX y si esta. La diferencia es que hay que alinear la pagina
   entera: mprotect no acepta direcciones sueltas.
   Devuelve false si la pagina no se deja poner en RW, que en iOS puede pasar
   con paginas del binario principal. En ese caso NO se escribe nada. */
static bool make_writable(void *addr, size_t len)
{
    long ps = sysconf(_SC_PAGESIZE);
    if (ps <= 0) ps = 4096;
    uintptr_t start = ((uintptr_t)addr) & ~((uintptr_t)ps - 1);
    uintptr_t end   = ((uintptr_t)addr + len + (uintptr_t)ps - 1) & ~((uintptr_t)ps - 1);
    if (mprotect((void *)start, (size_t)(end - start), PROT_READ | PROT_WRITE) != 0)
        return false;
    return true;
}

static void make_executable(void *addr, size_t len)
{
    long ps = sysconf(_SC_PAGESIZE);
    if (ps <= 0) ps = 4096;
    uintptr_t start = ((uintptr_t)addr) & ~((uintptr_t)ps - 1);
    uintptr_t end   = ((uintptr_t)addr + len + (uintptr_t)ps - 1) & ~((uintptr_t)ps - 1);
    mprotect((void *)start, (size_t)(end - start), PROT_READ | PROT_EXEC);
}

static bool patch_code(void *addr, size_t len, const void *bytes)
{
    if (!make_writable(addr, len)) return false;
    memcpy(addr, bytes, len);
    __builtin___clear_cache((char *)addr, (char *)addr + len);
    make_executable(addr, len);
    return true;
}

/* --------------------------------------------------------------------- */
/* Trampolina                                                               */
/* --------------------------------------------------------------------- */

/* Emite LDR X16,#8 ; BR X16 ; .quad dest en el buffer. Devuelve bytes escritos. */
static size_t emit_abs_jump(uint8_t *p, uint64_t dest)
{
    uint32_t ldr = 0x58000050u;   /* LDR X16, #8  -> lee el .quad de abajo */
    uint32_t br  = 0xD61F0200u;   /* BR  X16 */
    memcpy(p + 0, &ldr, 4);
    memcpy(p + 4, &br,  4);
    memcpy(p + 8, &dest, 8);
    return 16;
}

/* --------------------------------------------------------------------- */
/* API                                                                     */
/* --------------------------------------------------------------------- */

/*
 * Instala un gancho en target. detour es la funcion sustituta; desde ahi se
 * llama a *out_orig (la trampolina) para conservar el comportamiento.
 *
 * Devuelve true si quedo puesto. Si devuelve false, *why recibe el motivo.
 */
bool esp_hook_install(void *target, void *detour, void **out_orig, const char **why);

static bool copy_prologue(uint8_t *dst, uint8_t *src, size_t max_bytes,
                          size_t *out_bytes, const char **why)
{
    size_t n = 0;
    /* Como mucho 8 instrucciones: los prologos de C que nos interesan
       (SUB SP / STP / MOV) caben de sobra, y menos trampolina es menos
       superficie de fallo. */
    const size_t kMaxInstr = 8;

    while (n < kMaxInstr && n + 4 <= max_bytes) {
        uint32_t insn;
        memcpy(&insn, src + n, 4);

        if (is_branch(insn)) {
            if (n == 0) { *why = "el prologo empieza con una rama"; return false; }
            break;                       /* prologo copiado hasta aqui, sirve */
        }
        if (is_ldr_lit(insn)) {
            *why = "el prologo tiene una carga literal de PC (no se puede mover)";
            return false;
        }

        uint32_t out = insn;
        if (is_adrp(insn) || is_adr(insn)) {
            /* El desplazamiento esta en unidades de 4 respecto a la pagina
               actual. Hay que recalcularlo hacia la pagina destino. */
            int32_t imm21 = pc_rel_imm(insn);          /* en multiplos de 4 */
            uint64_t from_pc, to_pc;
            if (is_adrp(insn)) {
                from_pc = (uint64_t)(src + n) & ~0xFFFull;
                to_pc   = (uint64_t)(dst + n) & ~0xFFFull;
                /* imm21 esta en unidades de 4, pero el objetivo son paginas
                   de 4096: 1 pagina = 1024 unidades de 4. */
                int64_t delta_pages = (int64_t)((from_pc >> 12) - (to_pc >> 12));
                out = with_pc_rel_imm(insn, (int32_t)(imm21 - (delta_pages * 1024)));
            } else {
                from_pc = (uint64_t)(src + n);
                to_pc   = (uint64_t)(dst + n);
                out = with_pc_rel_imm(insn, (int32_t)(imm21 + (int32_t)((to_pc - from_pc) / 4)));
            }
        }

        memcpy(dst + n, &out, 4);
        n += 4;

        /* Una ADRP suelta sin el ADD de continuacion no sirve de nada y el
           registro apuntaria a la pagina equivocada. Si lo siguiente no es un
           ADD del mismo registro, se descarta. */
        if (is_adrp(insn)) {
            uint32_t next;
            memcpy(&next, src + n, 4);
            uint32_t rd = insn & 0x1Fu;
            if ((next & 0xFF800000u) != 0x91000000u || (next & 0x1Fu) != rd) {
                *why = "ADRP sin el ADD siguiente en el mismo registro";
                return false;
            }
        }
    }

    if (n == 0) { *why = "no se copio ninguna instruccion"; return false; }
    *out_bytes = n;
    return true;
}

bool esp_hook_install(void *target, void *detour, void **out_orig, const char **why)
{
    static const char *kFail = "motivo desconocido";
    if (why) *why = kFail;
    if (g_hook_count >= MAX_HOOKS) { if (why) *why = "tabla de hooks llena"; return false; }

    esp_hook_t *h = &g_hooks[g_hook_count];
    memset(h, 0, sizeof(*h));
    h->target = target;
    h->detour = detour;

    /* Pagina para la trampolina. Se pide escribible y luego se marca de
       ejecucion: escribir y ejecutar a la vez choca con W^X en iOS. */
    h->page_size = 0x4000;
    h->page = mmap(NULL, h->page_size, PROT_READ | PROT_WRITE,
                   MAP_ANON | MAP_PRIVATE, -1, 0);
    if (h->page == MAP_FAILED) {
        h->page = NULL;
        if (why) *why = "mmap fallo";
        return false;
    }
    h->trampoline = h->page;

    size_t copied = 0;
    if (!copy_prologue((uint8_t *)h->trampoline, (uint8_t *)target, 32, &copied, why)) {
        munmap(h->page, h->page_size);
        h->page = NULL;
        return false;
    }

    /* Al final de la trampolina, un salto absoluto de vuelta al resto del
       prologo original. */
    emit_abs_jump((uint8_t *)h->trampoline + copied,
                  (uint64_t)target + copied);

    if (mprotect(h->page, h->page_size, PROT_READ | PROT_EXEC) != 0) {
        if (why) *why = "mprotect a PROT_EXEC fallo";
        munmap(h->page, h->page_size);
        h->page = NULL;
        return false;
    }

    /* Pista del salto en el objetivo: 16 bytes, pero como el prologo copiado
       puede ser mas corto, rellenamos la diferencia con NOP. */
    uint8_t patch[16];
    memset(patch, 0xD503201Fu, 16);           /* NOP */
    emit_abs_jump(patch, (uint64_t)detour);
    h->patched_size = 16;

    memcpy(h->patch, target, 16);

    if (!patch_code(target, 16, patch)) {
        if (why) *why = "mprotect no dejo la pagina del cod en escritura";
        h->installed = false;
        return false;
    }

    if (out_orig) *out_orig = h->trampoline;
    h->installed = true;
    g_hook_count++;
    if (why) *why = NULL;
    return true;
}

/* Lo deja como estaba. No es estrictamente necesario (la dylib vive lo que
   vive el proceso) pero sirve para el calibrador, que engancha y desengancha. */
void esp_hook_remove(int slot)
{
    if (slot < 0 || slot >= g_hook_count) return;
    esp_hook_t *h = &g_hooks[slot];
    if (!h->installed) return;

    patch_code(h->target, h->patched_size, h->patch);
    h->installed = false;
}

int  esp_hook_count(void)             { return g_hook_count; }
esp_hook_t *esp_hook_at(int slot)     { return (slot >= 0 && slot < g_hook_count) ? &g_hooks[slot] : NULL; }

/* Devuelve la VA original que se le dio, para el informe del calibrador. */
uint64_t esp_hook_target(int slot)
{
    esp_hook_t *h = esp_hook_at(slot);
    return h ? (uint64_t)h->target : 0;
}