/* ===========================================================================
 *  imgui_app.mm — panel en ImGui (core + backend Metal) con la IDENTIDAD FUSION.
 *
 *  No es un clon visual de nada: el motor de UI es ImGui, pero los colores y el
 *  emblema salen del propio mod, leidos EN VIVO por mm_panel_api.h:
 *
 *    - acento primario   = mm_neon_green()   (tema FUSION: 0.20, 1.00, 0.58)
 *    - acento secundario = mm_neon_purple()  (tema FUSION: 0.63, 0.30, 1.00)
 *    - gradiente animado entre los dos, periodo 9 s con autoreverse, igual que
 *      mm_start_neon_gradient() del panel UIKit
 *    - emblema: hexagono regular con estela violeta (18% del perimetro) y nucleo
 *      casi blanco (10%) recorriendo el borde, igual que MMBtnGlyph
 *
 *  Asi, si el usuario cambia de tema (Hielo, Magenta, Fuego, Aqua o custom), el
 *  panel ImGui cambia con el, porque no tiene colores propios.
 *
 *  Se compila SOLO con MM_USE_IMGUI definido. Sin ese define no entra al link.
 * ========================================================================= */

#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <QuartzCore/QuartzCore.h>

#include <math.h>

#include "imgui.h"
#include "imgui_impl_metal.h"

#include "mm_panel_api.h"

#define MM_PI 3.14159265358979323846f

/* ======================================================== identidad FUSION */

/* Acento en vivo desde el mod. Si el panel no lo puede leer, cae al tema 0. */
static ImVec4 mm_accent(int secondary)
{
    float c[3] = { 0.20f, 1.00f, 0.58f };
    mm_panel_accent(secondary, c);
    return ImVec4(c[0], c[1], c[2], 1.00f);
}

static ImVec4 mm_accent_a(float alpha, int secondary)
{
    ImVec4 c = mm_accent(secondary);
    c.w = alpha;
    return c;
}

/* Gradiente A<->B del panel UIKit: 9 s, ease in-out, autoreverse. */
static ImVec4 mm_gradient(void)
{
    ImVec4 a = mm_accent(0);
    ImVec4 b = mm_accent(1);
    float t = 0.5f - 0.5f * cosf((float)(ImGui::GetTime() * 2.0 * M_PI / 9.0));
    return ImVec4(a.x + (b.x - a.x) * t,
                  a.y + (b.y - a.y) * t,
                  a.z + (b.z - a.z) * t, 1.00f);
}

/* --- geometria del emblema: hexagono de MMBtnGlyph ----------------------- */
static void mm_hex_points(ImVec2 c, float R, ImVec2 out[6])
{
    for (int i = 0; i < 6; i++) {
        float a = MM_PI / 3.0f * (float)i - MM_PI / 6.0f;
        out[i] = ImVec2(c.x + cosf(a) * R, c.y + sinf(a) * R);
    }
}

/* punto a lo largo del perimetro (t en [0,1]); hexagono regular = lados iguales */
static ImVec2 mm_hex_at(const ImVec2 p[6], float t)
{
    t = t - floorf(t);
    float seg = t * 6.0f;
    int i = (int)seg;
    if (i > 5) i = 5;
    float f = seg - (float)i;
    const ImVec2 &a = p[i];
    const ImVec2 &b = p[(i + 1) % 6];
    return ImVec2(a.x + (b.x - a.x) * f, a.y + (b.y - a.y) * f);
}

static void mm_hex_arc(ImDrawList *dl, const ImVec2 p[6], float t0, float t1,
                       ImU32 col, float th, int steps)
{
    ImVec2 prev = mm_hex_at(p, t0);
    for (int i = 1; i <= steps; i++) {
        float t = t0 + (t1 - t0) * (float)i / (float)steps;
        ImVec2 cur = mm_hex_at(p, t);
        dl->AddLine(prev, cur, col, th);
        prev = cur;
    }
}

/* Dibuja el emblema: borde tenue + estela violeta + nucleo blanco girando. */
static void mm_draw_emblem(ImDrawList *dl, ImVec2 center, float R)
{
    ImVec2 hex[6];
    mm_hex_points(center, R, hex);

    const ImU32 edge   = ImGui::GetColorU32(mm_accent_a(0.30f, 1));
    const ImU32 glow   = ImGui::GetColorU32(mm_accent_a(0.55f, 1));
    const ImU32 beam   = ImGui::GetColorU32(mm_accent_a(0.90f, 1));
    const ImU32 core   = IM_COL32(219, 255, 250, 255);      /* 0.86,1.0,0.98 */

    /* borde completo, fino */
    for (int i = 0; i < 6; i++) dl->AddLine(hex[i], hex[(i + 1) % 6], edge, 1.4f);

    /* la estela recorre el borde: 18% del perimetro, con halo */
    float t = (float)fmod(ImGui::GetTime() * 0.16, 1.0);
    mm_hex_arc(dl, hex, t, t + 0.18f, ImGui::GetColorU32(mm_accent_a(0.16f, 1)), 8.0f, 14);
    mm_hex_arc(dl, hex, t, t + 0.18f, glow, 4.6f, 14);
    /* el nucleo: 10%, casi blanco */
    mm_hex_arc(dl, hex, t, t + 0.10f, ImGui::GetColorU32(mm_accent_a(0.35f, 0)), 5.0f, 10);
    mm_hex_arc(dl, hex, t, t + 0.10f, core, 1.7f, 10);
    (void)beam;
}

/* ------------------------------------------------------------------ estilo */
static void mm_imgui_style(void)
{
    ImGuiStyle *s = &ImGui::GetStyle();
    ImGui::StyleColorsDark(s);

    ImVec4 a = mm_accent(0);
    ImVec4 b = mm_accent(1);

    s->WindowRounding    = 14.0f;
    s->ChildRounding     = 10.0f;
    s->FrameRounding     = 8.0f;
    s->GrabRounding      = 8.0f;
    s->ScrollbarRounding = 8.0f;
    s->WindowBorderSize  = 0.0f;
    s->FrameBorderSize   = 0.0f;
    s->WindowPadding     = ImVec2(14, 12);
    s->FramePadding      = ImVec2(10, 6);
    s->ItemSpacing       = ImVec2(8, 7);
    s->ScrollbarSize     = 12.0f;

    ImVec4 *c = s->Colors;
    c[ImGuiCol_WindowBg]         = ImVec4(0.043f, 0.051f, 0.067f, 0.96f);
    c[ImGuiCol_ChildBg]          = ImVec4(0.075f, 0.090f, 0.114f, 1.00f);
    c[ImGuiCol_Border]           = ImVec4(1.00f, 1.00f, 1.00f, 0.07f);
    c[ImGuiCol_Text]             = ImVec4(0.910f, 0.933f, 0.957f, 1.00f);
    c[ImGuiCol_TextDisabled]     = ImVec4(0.53f, 0.58f, 0.64f, 1.00f);
    c[ImGuiCol_Button]           = ImVec4(0.13f, 0.15f, 0.18f, 1.00f);
    c[ImGuiCol_ButtonHovered]    = ImVec4(a.x * 0.30f, a.y * 0.30f, a.z * 0.30f, 1.00f);
    c[ImGuiCol_ButtonActive]     = ImVec4(a.x * 0.45f, a.y * 0.45f, a.z * 0.45f, 1.00f);
    c[ImGuiCol_FrameBg]          = ImVec4(0.12f, 0.14f, 0.17f, 1.00f);
    c[ImGuiCol_FrameBgHovered]   = ImVec4(0.17f, 0.20f, 0.24f, 1.00f);
    c[ImGuiCol_FrameBgActive]    = ImVec4(0.20f, 0.24f, 0.29f, 1.00f);
    c[ImGuiCol_CheckMark]        = a;                       /* verde del tema */
    c[ImGuiCol_SliderGrab]       = a;
    c[ImGuiCol_SliderGrabActive] = b;                       /* morado al agarrar */
    c[ImGuiCol_Header]           = ImVec4(0.13f, 0.16f, 0.20f, 1.00f);
    c[ImGuiCol_HeaderHovered]    = ImVec4(a.x * 0.22f, a.y * 0.22f, a.z * 0.22f, 1.00f);
    c[ImGuiCol_HeaderActive]     = ImVec4(a.x * 0.32f, a.y * 0.32f, a.z * 0.32f, 1.00f);
    c[ImGuiCol_Separator]        = ImVec4(b.x, b.y, b.z, 0.22f);
    c[ImGuiCol_TextSelectedBg]   = ImVec4(a.x, a.y, a.z, 0.35f);
    c[ImGuiCol_TitleBg]          = ImVec4(0.043f, 0.051f, 0.067f, 1.00f);
    c[ImGuiCol_TitleBgActive]    = ImVec4(0.043f, 0.051f, 0.067f, 1.00f);
    c[ImGuiCol_PopupBg]          = ImVec4(0.075f, 0.090f, 0.114f, 0.98f);
}

/* =================================================================== vista */
@interface MMImguiView : MTKView
@property (nonatomic, assign) BOOL menuOpen;
@end

@implementation MMImguiView

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    if (!self.menuOpen) return NO;
    ImGuiIO &io = ImGui::GetIO();
    float x = (float)(point.x * self.contentScaleFactor);
    float y = (float)(point.y * self.contentScaleFactor);
    if (x < 0.0f || y < 0.0f || x > io.DisplaySize.x || y > io.DisplaySize.y) return NO;
    return ImGui::IsMouseHoveringRect(ImVec2(x, y), ImVec2(x + 1.0f, y + 1.0f), false);
}

- (void)mm_touch:(NSSet<UITouch *> *)touches down:(BOOL)down
{
    UITouch *t = touches.anyObject;
    if (!t) return;
    CGPoint p = [t locationInView:self];
    ImGuiIO &io = ImGui::GetIO();
    io.AddMousePosEvent((float)(p.x * self.contentScaleFactor),
                        (float)(p.y * self.contentScaleFactor));
    io.AddMouseButtonEvent(0, down);
}

- (void)touchesBegan:(NSSet<UITouch *> *)t withEvent:(UIEvent *)e { [self mm_touch:t down:YES]; }
- (void)touchesMoved:(NSSet<UITouch *> *)t withEvent:(UIEvent *)e { [self mm_touch:t down:YES]; }
- (void)touchesEnded:(NSSet<UITouch *> *)t withEvent:(UIEvent *)e { [self mm_touch:t down:NO]; }
- (void)touchesCancelled:(NSSet<UITouch *> *)t withEvent:(UIEvent *)e { [self mm_touch:t down:NO]; }

@end

/* ==================================================================== host */
@interface MMImguiHost : NSObject <MTKViewDelegate>
@property (nonatomic, strong) MTKView *view;
@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLCommandQueue> queue;
@property (nonatomic, strong) UIButton *fab;
@property (nonatomic, assign) BOOL open;
@property (nonatomic, assign) CFTimeInterval last;
@end

@implementation MMImguiHost

+ (instancetype)shared
{
    static MMImguiHost *s = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [[MMImguiHost alloc] init]; });
    return s;
}

- (UIWindow *)mm_key_window
{
    UIApplication *app = [UIApplication sharedApplication];
    if (@available(iOS 13.0, *)) {
        for (UIScene *sc in app.connectedScenes) {
            if (![sc isKindOfClass:[UIWindowScene class]]) continue;
            for (UIWindow *w in ((UIWindowScene *)sc).windows) {
                if (w.isKeyWindow) return w;
            }
        }
    }
    return app.keyWindow ?: app.windows.firstObject;
}

/* El boton flotante lleva el mismo hexagono del emblema. */
- (void)mm_decorate_fab:(UIButton *)fab
{
    CGRect b = fab.bounds;
    CGFloat w = b.size.width, h = b.size.height;
    CGFloat cx = w / 2.0, cy = h / 2.0;
    CGFloat R = MIN(w, h) / 2.0 - 3.2;
    UIBezierPath *p = [UIBezierPath bezierPath];
    for (int i = 0; i < 6; i++) {
        CGFloat ang = (CGFloat)(M_PI / 3.0 * i) - (CGFloat)(M_PI / 6.0);
        CGPoint pt = CGPointMake(cx + cos(ang) * R, cy + sin(ang) * R);
        if (i == 0) [p moveToPoint:pt]; else [p addLineToPoint:pt];
    }
    [p closePath];

    float a[3] = { 0.20f, 1.00f, 0.58f };
    mm_panel_accent(0, a);
    UIColor *accent = [UIColor colorWithRed:a[0] green:a[1] blue:a[2] alpha:1.0];

    CAShapeLayer *ring = [CAShapeLayer layer];
    ring.frame = b;
    ring.path = p.CGPath;
    ring.fillColor = [UIColor clearColor].CGColor;
    ring.strokeColor = [accent colorWithAlphaComponent:0.85].CGColor;
    ring.lineWidth = 1.8;
    ring.lineJoin = kCALineJoinRound;
    ring.shadowColor = accent.CGColor;
    ring.shadowRadius = 4.0;
    ring.shadowOpacity = 0.6f;
    ring.shadowOffset = CGSizeZero;
    [fab.layer addSublayer:ring];
}

- (void)setup
{
    if (self.view) return;
    UIWindow *win = [self mm_key_window];
    if (!win) return;

    self.device = MTLCreateSystemDefaultDevice();
    if (!self.device) return;
    self.queue = [self.device newCommandQueue];

    MMImguiView *v = [[MMImguiView alloc] initWithFrame:win.bounds device:self.device];
    v.delegate = self;
    v.opaque = NO;
    v.backgroundColor = [UIColor clearColor];
    v.clearColor = MTLClearColorMake(0, 0, 0, 0);
    v.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
    v.depthStencilPixelFormat = MTLPixelFormatDepth32Float_Stencil8;
    v.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    v.userInteractionEnabled = YES;
    v.multipleTouchEnabled = NO;
    v.menuOpen = NO;

    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    mm_imgui_style();
    ImGuiIO &io = ImGui::GetIO();
    io.IniFilename = NULL;
    io.LogFilename = NULL;
    io.Fonts->AddFontDefault();
    ImGui_ImplMetal_Init(self.device);

    self.view = v;
    [win addSubview:v];

    UIButton *fab = [UIButton buttonWithType:UIButtonTypeCustom];
    fab.frame = CGRectMake(win.bounds.size.width - 62.0, 96.0, 46.0, 46.0);
    fab.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
                           UIViewAutoresizingFlexibleBottomMargin;
    fab.backgroundColor = [UIColor colorWithRed:0.043 green:0.051 blue:0.067 alpha:0.92];
    fab.layer.cornerRadius = 23.0;
    [self mm_decorate_fab:fab];
    [fab addTarget:self action:@selector(toggle) forControlEvents:UIControlEventTouchUpInside];
    [win addSubview:fab];
    self.fab = fab;

    self.open = NO;
    self.last = CACurrentMediaTime();
}

- (void)toggle
{
    self.open = !self.open;
    ((MMImguiView *)self.view).menuOpen = self.open;
}

- (void)close
{
    self.open = NO;
    ((MMImguiView *)self.view).menuOpen = NO;
}

/* ----------------------------------------------------------- MTKViewDelegate */
- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size { (void)size; }

- (void)drawInMTKView:(MTKView *)view
{
    CFTimeInterval now = CACurrentMediaTime();
    float dt = (float)(now - self.last);
    self.last = now;
    if (dt <= 0.0f || dt > 0.5f) dt = 1.0f / 60.0f;

    ImGuiIO &io = ImGui::GetIO();
    CGSize bs = view.bounds.size;
    CGFloat sc = view.contentScaleFactor;
    io.DisplaySize = ImVec2((float)(bs.width * sc), (float)(bs.height * sc));
    io.DisplayFramebufferScale = ImVec2(1.0f, 1.0f);
    io.DeltaTime = dt;
    if (!self.open) io.AddMouseButtonEvent(0, false);

    MTLRenderPassDescriptor *rpd = view.currentRenderPassDescriptor;
    if (!rpd) return;

    ImGui_ImplMetal_NewFrame(rpd);
    ImGui::NewFrame();
    if (self.open) [self buildUI];
    ImGui::Render();

    id<MTLCommandBuffer> cb = [self.queue commandBuffer];
    id<MTLRenderCommandEncoder> enc = [cb renderCommandEncoderWithDescriptor:rpd];
    ImGui_ImplMetal_RenderDrawData(ImGui::GetDrawData(), cb, enc);
    [enc endEncoding];
    [cb presentDrawable:view.currentDrawable];
    [cb commit];
}

/* --------------------------------------------------------------------- la UI */
- (void)mm_header
{
    ImDrawList *dl = ImGui::GetWindowDrawList();
    ImGuiIO &io = ImGui::GetIO();
    float sc = io.DisplayFramebufferScale.x > 0.0f ? 1.0f : 1.0f;
    (void)sc;

    ImVec2 base = ImGui::GetCursorScreenPos();
    float R = 17.0f;
    ImVec2 ctr = ImVec2(base.x + R + 2.0f, base.y + R + 1.0f);
    mm_draw_emblem(dl, ctr, R);

    ImVec4 g = mm_gradient();
    ImGui::SetCursorScreenPos(ImVec2(base.x + R * 2.0f + 14.0f, base.y + 2.0f));
    ImGui::PushStyleColor(ImGuiCol_Text, g);
    ImGui::TextUnformatted("FUSION");
    ImGui::PopStyleColor();

    ImGui::SetCursorScreenPos(ImVec2(base.x + R * 2.0f + 14.0f, base.y + 22.0f));
    ImGui::PushStyleColor(ImGuiCol_Text, mm_accent_a(0.62f, 1));
    ImGui::Text("%s  |  %.0f FPS  |  %d obj", mm_panel_version(), mm_panel_fps(),
                mm_panel_targets());
    ImGui::PopStyleColor();

    ImGui::Dummy(ImVec2(0.0f, R * 2.0f + 4.0f));

    /* barra con el gradiente del tema (verde -> morado) */
    ImVec2 p0 = ImGui::GetCursorScreenPos();
    float w = ImGui::GetContentRegionAvail().x;
    ImVec4 a = mm_accent(0);
    ImVec4 b = mm_accent(1);
    dl->AddRectFilledMultiColor(p0, ImVec2(p0.x + w, p0.y + 2.0f),
                                ImGui::GetColorU32(ImVec4(a.x, a.y, a.z, 0.85f)),
                                ImGui::GetColorU32(ImVec4(b.x, b.y, b.z, 0.85f)),
                                ImGui::GetColorU32(ImVec4(b.x, b.y, b.z, 0.15f)),
                                ImGui::GetColorU32(ImVec4(a.x, a.y, a.z, 0.15f)));
    ImGui::Dummy(ImVec2(0.0f, 8.0f));
}

- (void)buildUI
{
    ImGuiIO &io = ImGui::GetIO();
    ImVec4 a = mm_accent(0);

    ImGui::SetNextWindowPos(ImVec2(io.DisplaySize.x * 0.5f - 176.0f, 84.0f),
                            ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowSize(ImVec2(352.0f, 0.0f), ImGuiCond_FirstUseEver);
    ImGui::Begin("##fusion", NULL, ImGuiWindowFlags_NoCollapse |
                                   ImGuiWindowFlags_AlwaysAutoResize |
                                   ImGuiWindowFlags_NoTitleBar);

    [self mm_header];

    if (mm_panel_lock_active())
        ImGui::TextColored(a, "aimlock ACTIVO  (%ld frames)", mm_panel_lock_frames());
    else
        ImGui::TextDisabled("aimlock inactivo");

    ImGui::Spacing();
    if (ImGui::CollapsingHeader("AIM", ImGuiTreeNodeFlags_DefaultOpen)) {
        bool lock = mm_panel_aimlock() != 0;
        if (ImGui::Checkbox("Aim lock", &lock)) mm_panel_set_aimlock(lock ? 1 : 0);

        float fov = mm_panel_aim_fov();
        if (ImGui::SliderFloat("FOV", &fov, 10.0f, 180.0f, "%.0f")) mm_panel_set_aim_fov(fov);

        float sm = mm_panel_aim_smooth();
        if (ImGui::SliderFloat("Suavizado", &sm, 0.0f, 1.0f, "%.2f"))
            mm_panel_set_aim_smooth(sm);

        float h = mm_panel_aim_height();
        if (ImGui::SliderFloat("Altura", &h, -1.0f, 2.0f, "%.2f m"))
            mm_panel_set_aim_height(h);

        float st = mm_panel_aim_strength();
        if (ImGui::SliderFloat("Fuerza", &st, 0.0f, 28.0f, "%.1f"))
            mm_panel_set_aim_strength(st);

        ImGui::Spacing();
        ImGui::TextDisabled("por tipo de arma");
        const char *kinds[4] = { "Fusil", "Subfusil", "Escopeta", "Franco" };
        for (int i = 0; i < 4; i++) {
            bool on = mm_panel_lock_kind(i + 1) != 0;
            if (i & 1) ImGui::SameLine(ImGui::GetContentRegionAvail().x * 0.5f);
            if (ImGui::Checkbox(kinds[i], &on)) mm_panel_set_lock_kind(i + 1, on ? 1 : 0);
        }
        bool ads = mm_panel_lock_ads() != 0;
        if (ImGui::Checkbox("Solo con mira (ADS)", &ads)) mm_panel_set_lock_ads(ads ? 1 : 0);
    }

    if (ImGui::CollapsingHeader("ESP", ImGuiTreeNodeFlags_DefaultOpen)) {
        struct { const char *label; const char *key; } items[] = {
            { "ESP maestro", "mm_esp_master"  },
            { "Cajas",       "mm_esp_box"     },
            { "Jugadores",   "mm_esp_players" },
            { "Bots",        "mm_esp_bots"    },
            { "Nombres",     "mm_esp_name"    },
            { "Distancia",   "mm_esp_dist"    },
            { "Lineas",      "mm_esp_lines"   },
            { "Vida",        "mm_esp_health"  },
            { "Relleno",     "mm_esp_fill"    },
            { "Radar",       "mm_x_radar"     },
        };
        for (unsigned i = 0; i < sizeof(items) / sizeof(items[0]); i++) {
            int v = mm_panel_esp(items[i].key);
            if (v < 0) continue;
            bool on = v != 0;
            if (ImGui::Checkbox(items[i].label, &on))
                mm_panel_set_esp(items[i].key, on ? 1 : 0);
        }
    }

    if (ImGui::CollapsingHeader("Diagnostico")) {
        ImGui::Text("escritura ok : %ld", mm_panel_lock_stuck());
        ImGui::Text("pisada x juego: %ld", mm_panel_lock_pisan());
        ImGui::TextDisabled("si 'pisada' crece quieto, el juego");
        ImGui::TextDisabled("reescribe la rotacion cada frame.");
    }

    ImGui::Spacing();
    ImGui::Separator();
    ImGui::Spacing();

    ImVec4 b = mm_accent(1);
    ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(b.x, b.y, b.z, 0.22f));
    ImGui::PushStyleColor(ImGuiCol_ButtonHovered, ImVec4(b.x, b.y, b.z, 0.38f));
    if (ImGui::Button("Cerrar", ImVec2(-1.0f, 36.0f))) {
        [self close];
        mm_panel_close();
    }
    ImGui::PopStyleColor(2);

    ImGui::End();
}

@end

/* ================================================================= arranque */
extern "C" void mm_imgui_start(void)
{
    [[MMImguiHost shared] performSelectorOnMainThread:@selector(setup)
                                           withObject:nil
                                        waitUntilDone:NO];
}

extern "C" int mm_imgui_is_open(void)
{
    return [MMImguiHost shared].open ? 1 : 0;
}
