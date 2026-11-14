/* ===========================================================================
 *  mm_panel_api.h — costura entre el panel y el motor.
 *
 *  El panel NO toca las variables internas de ModMenu.m: habla solo por estas
 *  funciones. Asi el panel se puede reescribir entero (UIKit, ImGui, lo que sea)
 *  sin tocar la logica del mod, y al reves.
 *
 *  Los setters actualizan el estado EN CALIENTE, persisten la preferencia con la
 *  misma clave que usa el panel UIKit, e invalidan el cache de opciones de
 *  dibujo. Asi los dos paneles quedan siempre en sincronia.
 * ========================================================================= */
#ifndef MM_PANEL_API_H
#define MM_PANEL_API_H

#ifdef __cplusplus
extern "C" {
#endif

/* ---- estado del aim ---- */
int   mm_panel_aimlock(void);
void  mm_panel_set_aimlock(int on);
float mm_panel_aim_fov(void);
void  mm_panel_set_aim_fov(float v);
float mm_panel_aim_smooth(void);
void  mm_panel_set_aim_smooth(float v);
float mm_panel_aim_height(void);
void  mm_panel_set_aim_height(float v);
float mm_panel_aim_strength(void);
void  mm_panel_set_aim_strength(float v);

/* ---- filtro por tipo de arma (1 rifle, 2 smg, 3 shotgun, 4 sniper) ---- */
int   mm_panel_lock_kind(int kind);
void  mm_panel_set_lock_kind(int kind, int on);
int   mm_panel_lock_ads(void);
void  mm_panel_set_lock_ads(int on);

/* ---- ESP (claves mm_esp_* / mm_x_*; -1 si la clave no existe) ---- */
int   mm_panel_esp(const char *key);
void  mm_panel_set_esp(const char *key, int on);

/* ---- telemetria (solo lectura) ---- */
float mm_panel_fps(void);
int   mm_panel_targets(void);
int   mm_panel_lock_active(void);
long  mm_panel_lock_frames(void);
long  mm_panel_lock_stuck(void);
long  mm_panel_lock_pisan(void);
const char *mm_panel_version(void);

/* ---- acciones ---- */
void  mm_panel_close(void);
int   mm_panel_visible(void);

#ifdef __cplusplus
}
#endif

#endif /* MM_PANEL_API_H */
