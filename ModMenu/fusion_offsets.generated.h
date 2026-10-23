/* ===========================================================================
 *  fusion_offsets.generated.h  —  GENERADO por `fusion offsets --emit`.
 *  NO EDITAR A MANO: se regenera desde corpus/1.0.57/offsets.json
 *  (y anchors.resolved.json si se uso --from-resolved).
 *
 *  Juego 1.0.57  ·  base 0x100000000  ·  build verificado modmenu-glass-0.3.5  ·  generado 2026-10-23T01:53:31.481Z
 * ========================================================================= */
#ifndef FUSION_OFFSETS_GENERATED_H
#define FUSION_OFFSETS_GENERATED_H

#define FUSION_OFFSETS_VERSION  "1.0.57"
#define FUSION_OFFSETS_BUILD    "modmenu-glass-0.3.5"
#define FUSION_IMAGE_BASE       0x100000000ULL

/* --- funciones del juego (VA absolutas) --- */
#define VA_GAMEPLAY   0x1023DD388ULL  /* GetGameplayInstance */
#define VA_LOCALPAWN  0x1023DE550ULL  /* getLocalPawn */
#define VA_MAINCAM    0x108BDBE98ULL  /* Camera.get_main */
#define VA_W2C_INJ    0x108BDABC0ULL  /* worldToCameraMatrix_Injected */
#define VA_PROJ_INJ   0x108BDACF8ULL  /* projectionMatrix_Injected */
#define VA_TRANSPOS   0x108C63B10ULL  /* Transform.get_position_Injected */
#define VA_HEALTH     0x1018B5524ULL  /* GetHealth */

/* --- offsets de struct (pinned por version; validados en runtime) --- */
#define OFF_GP_LIST         0x178  /* gameplay -> List<Pawn> */
#define OFF_LIST_ITEMS      0x10  /* List -> array IL2CPP */
#define OFF_LIST_SIZE       0x18  /* List -> int size */
#define OFF_ARR_DATA        0x20  /* array -> primer elemento */
#define OFF_PAWN_ALIVE      0x548  /* pawn -> byte vivo */
#define OFF_PAWN_TRANSFORM  0x308  /* pawn -> Transform */
#define OFF_PAWN_ENTITY     0x5C0  /* pawn -> entidad */
#define OFF_ENT_ROBOT       0x298  /* entidad -> byte robot */
#define OFF_PAWN_MODEL      0x78  /* pawn -> objeto de salud */
#define OFF_MODEL_MAXHP     0x38  /* modelo -> float vida maxima */
#define OFF_ENT_NAME        0x160  /* entidad -> string C# nombre */
#define OFF_STR_LEN         0x10  /* string -> int longitud */
#define OFF_STR_CHARS       0x14  /* string -> chars UTF-16 */

#endif /* FUSION_OFFSETS_GENERATED_H */
