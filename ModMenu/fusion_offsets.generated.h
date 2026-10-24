/* ===========================================================================
 *  fusion_offsets.generated.h  —  GENERADO por `fusion offsets --emit`.
 *  NO EDITAR A MANO: se regenera desde corpus/1.0.57/offsets.json
 *  (y anchors.resolved.json si se uso --from-resolved).
 *
 *  Juego 1.0.57  ·  base 0x100000000  ·  build verificado modmenu-glass-0.3.5  ·  generado 2026-10-24T22:40:57.560Z
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

/* --- BR / zona de radiacion (CANDIDATOS; requiere confirmar en device) --- */
/* ver corpus/1.0.57/br_dump.md para contexto. Gated: #ifdef FUSION_BR_ENABLED */
#ifdef FUSION_BR_ENABLED
#define BR_IS_IN_BRGAME           0x108380C44ULL  /* get_IsInBRGame */
#define BR_IS_BRGAME_MODE         0x10155EE2CULL  /* IsBRGameMode */
#define BR_SET_MGR                0x107528BB8ULL  /* set_RadiationZoneMgr */
#define BR_SET_BRMGR              0x10747071CULL  /* set_BRRadiationZoneMgr */
#define BR_CREATE_MGR             0x1074717D8ULL  /* CreateRadiationZoneMgr */
#define BR_SET_RADIUS             0x1079DB518ULL  /* set_RadiationZoneRadius */
#define BR_SET_NEXT_SPREAD_BEGIN  0x1079DB584ULL  /* set_RadiationZoneNextSpreadBeginTimestamp */
#define BR_SET_SPREAD_END         0x1079DB59CULL  /* set_RadiationZoneSpreadEndTimeStamp */
#define BR_SET_TOTAL_SPREADS      0x1079DC8B0ULL  /* set_TotalRadiationZoneSpreadTimes */
#define BR_SET_SHAPE              0x1079D91DCULL  /* set_RadiationZoneShape */
#define BR_ADD_ZONE               0x107A0B6ECULL  /* AddRadiationZone */
#endif /* FUSION_BR_ENABLED */

/* --- sonda de code registration (0.5: datos, no codigo) --- */
#define VA_PROBE_TABLE      0x10C33BFA8ULL
#define MM_PROBE_SLOT_SIZE  8
/* { indice de puntero, nombre } — usado por mm_probe_run() */
#define MM_PROBE_SLOTS \
    { 0, "slot0" }, \
    { 11130, "fieldOfView" }, \
    { 11250, "WorldToScreen" }, \
    { 47790, "get_LocalPawn" }, \
    { 54477, "get_Health" }, \
    { 142662, "WorldToScreen2" }, \
    { 236771, "aim(parche)" } \
    /* fin de slots */

#endif /* FUSION_OFFSETS_GENERATED_H */
