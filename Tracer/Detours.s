/*=============================================================================
 *  Detours.s  -  detours "naked" arm64 para el tracer
 *  ----------------------------------------------------------------------
 *  Al gancho se SALTA (BR), no se llama (BL), asi que al entrar x30 todavia
 *  es la direccion de retorno del CALLER de la funcion enganchada = lo que
 *  queremos registrar. Cada detour:
 *    1. guarda x0-x8, x30 y q0-q7 (todo lo que puede traer argumentos)
 *    2. llama a tracer_log(slot, caller)
 *    3. restaura todo
 *    4. salta a la trampolina g_tramp[slot] (prologo original + vuelta)
 *  Asi el juego se comporta igual; solo observamos quien llama.
 *============================================================================*/
    .text
    .align 2

.macro DETOUR n
    .global _tracer_detour_\n
_tracer_detour_\n:
    sub  sp, sp, #0xE0
    stp  x0,  x1,  [sp, #0x00]
    stp  x2,  x3,  [sp, #0x10]
    stp  x4,  x5,  [sp, #0x20]
    stp  x6,  x7,  [sp, #0x30]
    str  x8,       [sp, #0x40]
    str  x30,      [sp, #0x48]
    stp  q0,  q1,  [sp, #0x50]
    stp  q2,  q3,  [sp, #0x70]
    stp  q4,  q5,  [sp, #0x90]
    stp  q6,  q7,  [sp, #0xB0]
    mov  x0, #\n            // slot
    mov  x1, x30           // caller (todavia el original, antes del bl)
    bl   _tracer_log
    ldp  q6,  q7,  [sp, #0xB0]
    ldp  q4,  q5,  [sp, #0x90]
    ldp  q2,  q3,  [sp, #0x70]
    ldp  q0,  q1,  [sp, #0x50]
    ldr  x8,       [sp, #0x40]
    ldr  x30,      [sp, #0x48]
    ldp  x6,  x7,  [sp, #0x30]
    ldp  x4,  x5,  [sp, #0x20]
    ldp  x2,  x3,  [sp, #0x10]
    ldp  x0,  x1,  [sp, #0x00]
    add  sp, sp, #0xE0
    adrp x16, _g_tramp@PAGE
    add  x16, x16, _g_tramp@PAGEOFF
    ldr  x16, [x16, #(\n * 8)]
    br   x16
.endm

    DETOUR 0
    DETOUR 1
    DETOUR 2
    DETOUR 3
    DETOUR 4
