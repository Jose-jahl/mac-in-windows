/*=============================================================================
 *  Hook.m  -  inline hook arm64 (copia del ESP; incluye Tracer.h en vez de ESP.h)
 *  Sustituye el prologo de una funcion por un salto absoluto (16 B):
 *      LDR X16,#8 ; BR X16 ; .quad destino
 *  y deja una trampolina con el prologo original + salto de vuelta.
 *============================================================================*/

#include "Tracer.h"
#include "Hook.h"
#include <mach/mach.h>
#include <mach/vm_map.h>
#include <sys/mman.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>

/* Exportada por libSystem; no se incluye OSCacheControl.h a proposito para no
   arrastrar __builtin___clear_cache (que clang resuelve a un simbolo que iOS
   no exporta y rompe el enlazado). */
extern void sys_icache_invalidate(void *start, size_t len);

static esp_hook_t g_hooks[MAX_HOOKS];
static int        g_hook_count = 0;

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

static inline bool is_adrp(uint32_t i) { return (i & 0x9F000000u) == 0x90000000u; }
static inline bool is_adr (uint32_t i) { return (i & 0x9F000000u) == 0x10000000u; }
static inline bool is_ldr_lit(uint32_t i) { return (i & 0x3B000000u) == 0x18000000u; }

static inline int32_t pc_rel_imm(uint32_t i)
{
    uint32_t immlo = (i >> 29) & 0x3u;
    uint32_t immhi = (i >> 5)  & 0x7FFFFu;
    return (int32_t)((immhi << 2) | immlo) << 2;
}
static inline uint32_t with_pc_rel_imm(uint32_t i, int32_t imm21_in_4s)
{
    uint32_t imm = ((uint32_t)imm21_in_4s >> 2) & 0x1FFFFFu;
    uint32_t immlo = imm & 0x3u;
    uint32_t immhi = (imm >> 2) & 0x7FFFFu;
    return (i & 0x9F00001Fu) | (immlo << 29) | (immhi << 5);
}

static bool make_writable(void *addr, size_t len)
{
    long ps = sysconf(_SC_PAGESIZE);
    if (ps <= 0) ps = 0x4000;
    uintptr_t start = ((uintptr_t)addr) & ~((uintptr_t)ps - 1);
    uintptr_t end   = ((uintptr_t)addr + len + (uintptr_t)ps - 1) & ~((uintptr_t)ps - 1);
    // En iOS el __TEXT del binario principal esta firmado y mprotect(RW) lo
    // rechaza. VM_PROT_COPY fuerza copy-on-write: una copia privada escribible
    // de la pagina, que es como se parchea codigo firmado sin jailbreak
    // (Frida/Dobby). Requiere get-task-allow, que traen las apps dev-signed.
    kern_return_t kr = vm_protect(mach_task_self(), (vm_address_t)start,
                                  (vm_size_t)(end - start), FALSE,
                                  VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    return kr == KERN_SUCCESS;
}
static void make_executable(void *addr, size_t len)
{
    long ps = sysconf(_SC_PAGESIZE);
    if (ps <= 0) ps = 0x4000;
    uintptr_t start = ((uintptr_t)addr) & ~((uintptr_t)ps - 1);
    uintptr_t end   = ((uintptr_t)addr + len + (uintptr_t)ps - 1) & ~((uintptr_t)ps - 1);
    vm_protect(mach_task_self(), (vm_address_t)start, (vm_size_t)(end - start),
               FALSE, VM_PROT_READ | VM_PROT_EXEC);
    sys_icache_invalidate(addr, len);   // coherencia I-cache tras escribir codigo
}
static bool patch_code(void *addr, size_t len, const void *bytes)
{
    if (!make_writable(addr, len)) return false;
    memcpy(addr, bytes, len);
    make_executable(addr, len);
    return true;
}

static size_t emit_abs_jump(uint8_t *p, uint64_t dest)
{
    uint32_t ldr = 0x58000050u;   /* LDR X16, #8 */
    uint32_t br  = 0xD61F0200u;   /* BR  X16 */
    memcpy(p + 0, &ldr, 4);
    memcpy(p + 4, &br,  4);
    memcpy(p + 8, &dest, 8);
    return 16;
}

static bool copy_prologue(uint8_t *dst, uint8_t *src, size_t max_bytes,
                          size_t *out_bytes, const char **why)
{
    size_t n = 0;
    // Copiar hasta tener al menos 16 bytes (4 instrucciones), que es lo que
    // ocupa el salto parcheado. OJO: el bug original comparaba n (BYTES) contra
    // un contador de 8 INSTRUCCIONES, asi que copiaba solo 8 B (2 instr) y el
    // salto de 16 B pisaba codigo sin reubicar -> el hook quedaba inerte/crash.
    while (n < 16 && n + 4 <= max_bytes) {
        uint32_t insn;
        memcpy(&insn, src + n, 4);
        if (is_branch(insn)) {
            if (n == 0) { *why = "el prologo empieza con una rama"; return false; }
            break;
        }
        if (is_ldr_lit(insn)) {
            *why = "el prologo tiene una carga literal de PC (no se puede mover)";
            return false;
        }
        uint32_t out = insn;
        if (is_adrp(insn) || is_adr(insn)) {
            int32_t imm21 = pc_rel_imm(insn);
            uint64_t from_pc, to_pc;
            if (is_adrp(insn)) {
                from_pc = (uint64_t)(src + n) & ~0xFFFull;
                to_pc   = (uint64_t)(dst + n) & ~0xFFFull;
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

    h->page_size = 0x4000;
    h->page = mmap(NULL, h->page_size, PROT_READ | PROT_WRITE,
                   MAP_ANON | MAP_PRIVATE, -1, 0);
    if (h->page == MAP_FAILED) { h->page = NULL; if (why) *why = "mmap fallo"; return false; }
    h->trampoline = h->page;

    size_t copied = 0;
    if (!copy_prologue((uint8_t *)h->trampoline, (uint8_t *)target, 32, &copied, why)) {
        munmap(h->page, h->page_size); h->page = NULL; return false;
    }
    /* Seguridad: el salto parcheado ocupa 16 B. Si se copiaron menos de 16,
       volver a target+copied caeria dentro del salto. Abortar. */
    if (copied < 16) {
        munmap(h->page, h->page_size); h->page = NULL;
        if (why) *why = "prologo copiado < 16 B (rama temprana); hook abortado";
        return false;
    }
    emit_abs_jump((uint8_t *)h->trampoline + copied, (uint64_t)target + copied);

    if (mprotect(h->page, h->page_size, PROT_READ | PROT_EXEC) != 0) {
        if (why) *why = "mprotect a PROT_EXEC fallo";
        munmap(h->page, h->page_size); h->page = NULL; return false;
    }

    uint8_t patch[16];
    memset(patch, 0, 16);
    emit_abs_jump(patch, (uint64_t)detour);
    h->patched_size = 16;
    memcpy(h->patch, target, 16);

    if (!patch_code(target, 16, patch)) {
        if (why) *why = "mprotect no dejo la pagina del cod en escritura";
        h->installed = false; return false;
    }
    if (out_orig) *out_orig = h->trampoline;
    h->installed = true;
    g_hook_count++;
    if (why) *why = NULL;
    return true;
}

void esp_hook_remove(int slot)
{
    if (slot < 0 || slot >= g_hook_count) return;
    esp_hook_t *h = &g_hooks[slot];
    if (!h->installed) return;
    patch_code(h->target, h->patched_size, h->patch);
    h->installed = false;
}
int  esp_hook_count(void)         { return g_hook_count; }
esp_hook_t *esp_hook_at(int slot) { return (slot >= 0 && slot < g_hook_count) ? &g_hooks[slot] : NULL; }
uint64_t esp_hook_target(int slot){ esp_hook_t *h = esp_hook_at(slot); return h ? (uint64_t)h->target : 0; }
