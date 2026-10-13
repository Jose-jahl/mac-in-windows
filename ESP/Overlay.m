/*=============================================================================
 *  Overlay.m
 *============================================================================*/

#include "Overlay.h"
#include "Targets.h"

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#include <math.h>
#include <string.h>
#include <stdarg.h>
#include <stdio.h>

bool g_calibrate = false;

/* --------------------------------------------------------------------- */
/* Estado                                                                 */
/* --------------------------------------------------------------------- */
static UIWindow           *g_win      = nil;
static ESPOverlayView    *g_view     = nil;
static CADisplayLink     *g_link     = nil;
static float              g_m_view[16];
static float              g_m_proj[16];
static bool               g_mats_ok   = false;
static uint64_t           g_frames    = 0;

void esp_overlay_set_matrices(const float *view, const float *proj)
{
    if (view) memcpy(g_m_view, view, sizeof(g_m_view));
    if (proj) memcpy(g_m_proj, proj, sizeof(g_m_proj));
    g_mats_ok = (view != NULL || proj != NULL);
}

bool esp_overlay_running(void) { return g_win != nil; }
uint64_t esp_overlay_frames(void) { return g_frames; }

/* --------------------------------------------------------------------- */
/* Vista                                                                  */
/* --------------------------------------------------------------------- */
@interface ESPOverlayView : UIView
- (void)onTick:(CADisplayLink *)link;
@end

@implementation ESPOverlayView

- (instancetype)initWithFrame:(CGRect)f
{
    self = [super initWithFrame:f];
    if (self) {
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;   /* deja pasar los toques al juego */
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        /* Los juegos con Metal pueden tener la capa en un formato raro; forzamos
           el nuestro para que el CGContext sea utilizable. */
        self.layer.opaque = NO;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) return;
    g_frames++;

    CGContextSaveGState(ctx);
    CGContextSetShouldAntialias(ctx, true);
    CGContextSetAllowsAntialiasing(ctx, true);
    /* origen arriba-izquierda, como el resto de la ESP */
    CGContextTranslateCTM(ctx, 0, rect.size.height);
    CGContextScaleCTM(ctx, 1, -1);

    esp_render_frame(ctx, rect.size.width, rect.size.height);

    CGContextRestoreGState(ctx);
}

@end

/* Controlador vacio: la ventana del overlay necesita un rootViewController y
   la vista se le anade encima. */
@interface ESPOverlayController : UIViewController
@end
@implementation ESPOverlayController
@end

/* --------------------------------------------------------------------- */
/* Arranque                                                               */
/* --------------------------------------------------------------------- */
bool esp_overlay_start(void)
{
    if (g_win) return true;

    dispatch_async(dispatch_get_main_queue(), ^{
        CGRect bounds = [UIScreen mainScreen].bounds;

        g_win = [[UIWindow alloc] initWithFrame:bounds];
        g_win.windowLevel = UIWindowLevelAlert + 100.0;
        g_win.backgroundColor = [UIColor clearColor];
        g_win.userInteractionEnabled = NO;
        g_win.hidden = NO;
        /* La ventana del juego va a ser la key cuando el usuario toque algo.
           Sin esto el overlay se lleva los toques; con esto, no. */
        g_win.rootViewController = [[ESPOverlayController alloc] init];

        g_view = [[ESPOverlayView alloc] initWithFrame:bounds];
        [g_win.rootViewController.view addSubview:g_view];

        g_link = [CADisplayLink displayLinkWithTarget:g_view selector:@selector(onTick:)];
        [g_link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];

        [g_win makeKeyAndVisible];
    });
    return true;
}

void esp_overlay_stop(void)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [g_link invalidate]; g_link = nil;
        g_win.hidden = YES;
        g_win = nil; g_view = nil;
    });
}

void esp_overlay_size(float *w, float *h)
{
    CGRect b = [UIScreen mainScreen].bounds;
    if (w) *w = (float)b.size.width;
    if (h) *h = (float)b.size.height;
}

/* --------------------------------------------------------------------- */
/* Proyeccion                                                             */
/* --------------------------------------------------------------------- */
/* Las matrices llegan row-major. El punto se transforma con view y luego
   con proj; el resultado se divide por w. Sin w>0 el punto esta detras. */
static inline void mat4_mul_vec(const float *m, float x, float y, float z,
                                float *ox, float *oy, float *oz, float *ow)
{
    *ox = m[0] * x + m[1] * y + m[2]  * z + m[3];
    *oy = m[4] * x + m[5] * y + m[6]  * z + m[7];
    *oz = m[8] * x + m[9] * y + m[10] * z + m[11];
    *ow = m[12]* x + m[13]* y + m[14]* z + m[15];
}

void esp_overlay_get_matrices(float *view_out, float *proj_out)
{
    if (view_out) memcpy(view_out, g_m_view, sizeof(g_m_view));
    if (proj_out) memcpy(proj_out, g_m_proj, sizeof(g_m_proj));
}

bool esp_project(float wx, float wy, float wz, float *sx, float *sy)
{
    if (!g_mats_ok) return false;

    float cx, cy, cz, cw, px, py, pz, pw;
    mat4_mul_vec(g_m_view, wx, wy, wz, &cx, &cy, &cz, &cw);
    mat4_mul_vec(g_m_proj, cx, cy, cz, &px, &py, &pz, &pw);
    if (pw <= 0.0001f) return false;

    float ndx = px / pw, ndy = py / pw;
    float W, H;
    esp_overlay_size(&W, &H);
    if (sx) *sx = (ndx * 0.5f + 0.5f) * W;
    if (sy) *sy = (1.0f - (ndy * 0.5f + 0.5f)) * H;
    return true;
}

/* --------------------------------------------------------------------- */
/* Color                                                                  */
/* --------------------------------------------------------------------- */
uint32_t esp_argb(uint32_t rgb, float alpha)
{
    uint32_t a = (uint32_t)(alpha < 0 ? 0 : (alpha > 1 ? 1 : alpha) * 255.0f);
    return (a << 24) | (rgb & 0x00FFFFFFu);
}

static void set_stroke(CGContextRef c, uint32_t argb)
{
    CGFloat a = ((argb >> 24) & 0xFF) / 255.0;
    CGFloat r = ((argb >> 16) & 0xFF) / 255.0;
    CGFloat g = ((argb >>  8) & 0xFF) / 255.0;
    CGFloat b = ( argb        & 0xFF) / 255.0;
    CGContextSetStrokeColorWithColor(c, CGColorCreateGenericRGB(r, g, b, a));
}

static void set_fill(CGContextRef c, uint32_t argb)
{
    CGFloat a = ((argb >> 24) & 0xFF) / 255.0;
    CGFloat r = ((argb >> 16) & 0xFF) / 255.0;
    CGFloat g = ((argb >>  8) & 0xFF) / 255.0;
    CGFloat b = ( argb        & 0xFF) / 255.0;
    CGContextSetFillColorWithColor(c, CGColorCreateGenericRGB(r, g, b, a));
}

/* --------------------------------------------------------------------- */
/* Primitivas                                                             */
/* --------------------------------------------------------------------- */
void esp_draw_box(float x, float y, float w, float h, uint32_t argb, float thickness)
{
    CGContextRef c = UIGraphicsGetCurrentContext();
    if (!c) return;
    set_stroke(c, argb);
    CGContextSetLineWidth(c, thickness);
    CGContextStrokeRect(c, x, y, w, h);
}

void esp_draw_corners(float x, float y, float w, float h, uint32_t argb,
                      float thickness, float ratio)
{
    CGContextRef c = UIGraphicsGetCurrentContext();
    if (!c) return;
    if (ratio <= 0.0f) ratio = 0.25f;
    if (ratio > 0.5f) ratio = 0.5f;
    float lx = w * ratio, ly = h * ratio;
    set_stroke(c, argb);
    CGContextSetLineWidth(c, thickness);
    CGContextSetLineCap(c, kCGLineCapSquare);

    struct { float x0,y0,x1,y1; } L[8] = {
        { x,      y,      x+lx,   y     },   /* arriba izq -> */
        { x,      y,      x,      y+ly  },   /* abajo  izq |  */
        { x+w,    y,      x+w-lx, y     },   /* arriba der <- */
        { x+w,    y,      x+w,    y+ly  },   /* abajo  der |  */
        { x,      y+h,    x+lx,   y+h   },   /* abajo  izq -> */
        { x,      y+h,    x,      y+h-ly},   /* arriba izq |  */
        { x+w,    y+h,    x+w-lx, y+h   },   /* abajo  der <- */
        { x+w,    y+h,    x+w,    y+h-ly},   /* arriba der |  */
    };
    for (int i = 0; i < 8; i++)
        CGContextMoveToPoint(c, L[i].x0, L[i].y0),
        CGContextAddLineToPoint(c, L[i].x1, L[i].y1);
    CGContextStrokePath(c);
}

void esp_draw_line(float x0, float y0, float x1, float y1, uint32_t argb, float thickness)
{
    CGContextRef c = UIGraphicsGetCurrentContext();
    if (!c) return;
    set_stroke(c, argb);
    CGContextSetLineWidth(c, thickness);
    CGContextMoveToPoint(c, x0, y0);
    CGContextAddLineToPoint(c, x1, y1);
    CGContextStrokePath(c);
}

void esp_draw_filled(float x, float y, float w, float h, uint32_t argb)
{
    CGContextRef c = UIGraphicsGetCurrentContext();
    if (!c) return;
    set_fill(c, argb);
    CGContextFillRect(c, x, y, w, h);
}

void esp_draw_circle(float cx, float cy, float r, uint32_t argb, float thickness)
{
    CGContextRef c = UIGraphicsGetCurrentContext();
    if (!c) return;
    set_stroke(c, argb);
    CGContextSetLineWidth(c, thickness);
    CGContextAddEllipseInRect(c, CGRectMake(cx - r, cy - r, r * 2, r * 2));
    CGContextStrokePath(c);
}

/* El contexto esta invertido (y crece hacia abajo) por el CTM que se aplica
   en drawRect. UIKit no dibuja bien asi que se restaura la matriz normal
   alrededor de cada texto. */
void esp_draw_text(float x, float y, float size, uint32_t argb, bool centered,
                   const char *text)
{
    if (!text || !*text) return;
    @autoreleasepool {
        CGContextRef c = UIGraphicsGetCurrentContext();
        if (!c) return;
        UIColor *col = [UIColor colorWithRed:((argb >> 16) & 0xFF) / 255.0
                                       green:((argb >>  8) & 0xFF) / 255.0
                                        blue:( argb        & 0xFF) / 255.0
                                       alpha:((argb >> 24) & 0xFF) / 255.0];
        UIFont *fnt = [UIFont fontWithName:@"Menlo-Bold" size:size]
                   ?: [UIFont systemFontOfSize:size weight:UIFontWeightBold];
        NSDictionary *attrs = @{ NSFontAttributeName: fnt,
                                 NSForegroundColorAttributeName: col };
        CGSize sz = [(NSString *)text sizeWithAttributes:attrs];
        CGFloat px = centered ? x - sz.width / 2.0 : x;

        CGContextSaveGState(c);
        CGContextTranslateCTM(c, 0, y + sz.height);      /* y crece hacia abajo */
        CGContextScaleCTM(c, 1, -1);                     /* texto hacia arriba */
        [(NSString *)text drawAtPoint:CGPointMake(px, 0) withAttributes:attrs];
        CGContextRestoreGState(c);
    }
}

void esp_draw_text_shadow(float x, float y, float size, uint32_t argb,
                          bool centered, const char *text)
{
    uint32_t sh = esp_argb(0x000000, 0.75f);
    esp_draw_text(x + 1, y + 1, size, sh, centered, text);
    esp_draw_text(x,     y,     size, argb, centered, text);
}

void esp_fmt(char *dst, size_t n, const char *fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(dst, n, fmt, ap);
    va_end(ap);
}

/* El CADisplayLink llama aqui; solo invalida para que se dispare drawRect. */
- (void)onTick:(CADisplayLink *)link
{
    [self setNeedsDisplay];
}