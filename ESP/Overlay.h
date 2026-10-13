/*=============================================================================
 *  Overlay.h  -  ventana, bucle de render y primitivas de dibujo
 *  ----------------------------------------------------------------------
 *  Una UIWindow propia por encima de la del juego, con un CADisplayLink a la
 *  tasa del refresco. No toca la ventana del juego ni su bucle de render.
 *
 *  Todo el dibujo va por CoreGraphics en drawRect: es mas lento que Metal pero
 *  aguanta de sobra unas pocas decenas de cajas por frame y a cambio se puede
 *  compilar con el mismo clang de un solo comando.
 *============================================================================*/

#ifndef OVERLAY_H
#define OVERLAY_H

#include "ESP.h"

/* --- ciclo de vida ----------------------------------------------------- */
bool esp_overlay_start(void);          /* ventana + display link */
void esp_overlay_stop(void);
bool esp_overlay_running(void);

/* Tamano del area de dibujo en pixeles. */
void esp_overlay_size(float *w, float *h);

/* --- matrices ---------------------------------------------------------- */
/* Matrices 4x4 en orden row-major, tal y como las entrega el motor.
   Se pasan por puntero a float de 16 elementos. Si no estan resueltas,
   la ESP dibuja el log pero no las cajas. */
void esp_overlay_set_matrices(const float *view, const float *proj);

/* Lectura de las matrices, para el informe del calibrador. */
void esp_overlay_get_matrices(float *view_out, float *proj_out);

/* Proyecta un punto del mundo. Devuelve false si esta detras de la camara. */
bool esp_project(float wx, float wy, float wz, float *sx, float *sy);

/* --- dibujo ------------------------------------------------------------ */
/* Todo en coordenadas de pantalla en pixeles. El contexto ya esta
   preparado; estas funciones solo pintan. */
void esp_draw_box(float x, float y, float w, float h, uint32_t argb, float thickness);
void esp_draw_corners(float x, float y, float w, float h, uint32_t argb,
                      float thickness, float ratio);
void esp_draw_line(float x0, float y0, float x1, float y1, uint32_t argb, float thickness);
void esp_draw_filled(float x, float y, float w, float h, uint32_t argb);
void esp_draw_circle(float cx, float cy, float r, uint32_t argb, float thickness);
void esp_draw_text(float x, float y, float size, uint32_t argb, bool centered,
                   const char *text);
void esp_draw_text_shadow(float x, float y, float size, uint32_t argb,
                          bool centered, const char *text);

/* --- utilidades -------------------------------------------------------- */
uint32_t esp_argb(uint32_t rgb, float alpha);
void     esp_fmt(char *dst, size_t n, const char *fmt, ...);

/* Numero de fotogramas pintados. Lo usa el calibrador. */
uint64_t esp_overlay_frames(void);

#endif /* OVERLAY_H */