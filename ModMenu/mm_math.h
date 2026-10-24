/* ===========================================================================
 *  mm_math.h — matematica PURA del overlay, sin UIKit/CoreGraphics.
 *
 *  0.13: sale de ModMenu.m para poder testearse en C nativo, sin simulador ni
 *  equipo. Reglas:
 *    - solo C11 + <math.h>, cero tipos Apple (nada de CGFloat/CGPoint);
 *    - funciones `static` (se incluye en un solo .m, no hay simbolos exportados);
 *    - la semantica es EXACTAMENTE la que ya volaba en v0.5.0. Si cambia una
 *      formula, cambia el test: es el contrato de dibujo del ESP.
 *
 *  Test: dylib/tests/mm_math_test.c  (CI: job native-math de tool-ci.yml)
 * ========================================================================= */
#ifndef MM_MATH_H
#define MM_MATH_H

#include <math.h>
#include <string.h>

/* "sin umbral": closest-N desactivado o no aplicable. */
#define MM_MATH_DIST_NONE 1.0e9f

/* --- proyeccion mundo -> pantalla -----------------------------------------
 *  view/proj: 4x4 en column-major (como llegan de IL2CPP).
 *  head:      +0.5 al clip Y antes de dividir (misma correccion de cuello).
 *  w,h:       tamano del lienzo en puntos.
 *  Devuelve 1 si el punto es proyectable; 0 si quedo detras de la camara
 *  (*behind=1) o si el resultado no es finito.
 *  *out_vx / *out_vy reciben la direccion en espacio de camara aunque el punto
 *  este detras: es lo que usa la flecha "enemigo a la espalda".
 * ------------------------------------------------------------------------- */
static int mm_math_w2s(const float view[16], const float proj[16], const float p[3],
                       int head, float w, float h,
                       float *ox, float *oy, int *behind,
                       float *out_vx, float *out_vy)
{
    const float x = p[0], y = p[1], z = p[2];

    const float vx = view[0] * x + view[4] * y + view[8]  * z + view[12];
    const float vy = view[1] * x + view[5] * y + view[9]  * z + view[13];
    const float vz = view[2] * x + view[6] * y + view[10] * z + view[14];
    const float vw = view[3] * x + view[7] * y + view[11] * z + view[15];

    if (behind) *behind = 0;
    if (out_vx) *out_vx = vx;
    if (out_vy) *out_vy = vy;

    float cx = proj[0] * vx + proj[4] * vy + proj[8]  * vz + proj[12] * vw;
    float cy = proj[1] * vx + proj[5] * vy + proj[9]  * vz + proj[13] * vw;
    const float cz = proj[2] * vx + proj[6] * vy + proj[10] * vz + proj[14] * vw;
    const float cw = proj[3] * vx + proj[7] * vy + proj[11] * vz + proj[15] * vw;

    if (!(cz >= 0.01f)) { if (behind) *behind = 1; return 0; }
    if (head) cy += 0.5f;

    float nx = 0.0f, ny = 0.0f;
    if (cw >= 0.001f || cw <= -0.001f) { nx = cx / cw; ny = cy / cw; }
    if (!isfinite(nx) || !isfinite(ny)) return 0;

    if (ox) *ox = nx + w / 2.0f + nx * (w / 2.0f);
    if (oy) *oy = ny + h / 2.0f - ny * (h / 2.0f);
    return 1;
}

/* --- distancia euclidiana entre dos puntos de mundo ------------------------ */
static float mm_math_dist3(const float a[3], const float b[3])
{
    const float dx = a[0] - b[0], dy = a[1] - b[1], dz = a[2] - b[2];
    return sqrtf(dx * dx + dy * dy + dz * dz);
}

/* --- umbral closest-N ------------------------------------------------------
 *  Devuelve la distancia de la N-esima caja mas cercana (0-based: max_n-1).
 *  Si max_n <= 0 o max_n >= n, closest-N no aplica -> MM_MATH_DIST_NONE.
 *  Ordena una copia (insercion): el arreglo de entrada no se toca.
 * ------------------------------------------------------------------------- */
static float mm_math_closest_threshold(const float *d, int n, int max_n)
{
    if (d == NULL || n <= 0 || max_n <= 0 || max_n >= n) return MM_MATH_DIST_NONE;

    float ds[64];
    if (n > (int)(sizeof(ds) / sizeof(ds[0]))) n = (int)(sizeof(ds) / sizeof(ds[0]));
    memcpy(ds, d, sizeof(float) * (size_t)n);

    for (int i = 1; i < n; i++) {
        const float k = ds[i];
        int j = i - 1;
        while (j >= 0 && ds[j] > k) { ds[j + 1] = ds[j]; j--; }
        ds[j + 1] = k;
    }
    return ds[max_n - 1];
}

/* --- caja del cuerpo -------------------------------------------------------
 *  Devuelve:
 *    1  dibujable  (*out_cx centro X, *out_bh alto en puntos)
 *    0  fuera de cuadro (sigue siendo apuntable por la flecha)
 *   -1  alto invalido (muy chica o mas alta que 2 pantallas)
 * ------------------------------------------------------------------------- */
static int mm_math_box(float topx, float topy, float feetx, float feety,
                       float w, float h, float *out_cx, float *out_bh)
{
    if (topx  < -w || topx  > 2.0f * w || topy  < -h || topy  > 2.0f * h ||
        feetx < -w || feetx > 2.0f * w || feety < -h || feety > 2.0f * h)
        return 0;

    const float bh = feety - topy;
    if (bh < 3.0f || bh > 2.0f * h) return -1;

    if (out_cx) *out_cx = (topx + feetx) * 0.5f;
    if (out_bh) *out_bh = bh;
    return 1;
}

#endif /* MM_MATH_H */
