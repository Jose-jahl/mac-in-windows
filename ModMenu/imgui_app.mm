/* ===========================================================================
 *  imgui_app.mm — panel en ImGui (core + backend Metal) sobre el juego.
 *
 *  Se compila SOLO cuando el build define MM_USE_IMGUI y compila ademas las
 *  fuentes de ImGui. Sin ese define este archivo no entra en el link y la build
 *  queda igual que antes: cero riesgo para lo que ya funciona.
 *
 *  Por que ImGui: el panel de referencia de Cloud es ImGui con backend Metal
 *  (ver kit/cloud-ui/README.md). ImGui da gratis ventanas arrastrables,
 *  secciones colapsables, sliders y scroll, y el look se controla con ImGuiStyle
 *  en lugar de dibujar a mano.
 *
 *  Arquitectura:
 *    MMImguiView : MTKView que dibuja ImGui y traduce toques a ImGuiIO. Solo
 *                  captura el toque si cae dentro de la ventana, asi el juego
 *                  sigue recibiendo el resto de la pantalla.
 *    MMImguiHost : delega el frame y arma la ventana con los controles.
 *    mm_imgui_start() : crea el overlay y el boton flotante.
 *
 *  El panel NO toca las variables del mod: habla por mm_panel_api.h.
 * ========================================================================= */

#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <QuartzCore/QuartzCore.h>

#include "imgui.h"
#include "imgui_impl_metal.h"

#include "mm_panel_api.h"

static const ImVec4 MM_GREEN = ImVec4(0.14f, 0.84f, 0.42f, 1.00f);

/* ------------------------------------------------------------------ estilo */
static void mm_imgui_style(void)
{
    ImGuiStyle *s = &ImGui::GetStyle();
    ImGui::StyleColorsDark(s);

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
    c[ImGuiCol_WindowBg]         = ImVec4(0.055f, 0.067f, 0.086f, 0.96f);
    c[ImGuiCol_ChildBg]          = ImVec4(0.086f, 0.106f, 0.133f, 1.00f);
    c[ImGuiCol_Border]           = ImVec4(1.00f, 1.00f, 1.00f, 0.07f);
    c[ImGuiCol_Text]             = ImVec4(0.902f, 0.929f, 0.953f, 1.00f);
    c[ImGuiCol_TextDisabled]     = ImVec4(0.53f, 0.58f, 0.64f, 1.00f);
    c[ImGuiCol_Button]           = ImVec4(0.13f, 0.15f, 0.18f, 1.00f);
    c[ImGuiCol_ButtonHovered]    = ImVec4(0.18f, 0.21f, 0.25f, 1.00f);
    c[ImGuiCol_ButtonActive]     = ImVec4(0.23f, 0.27f, 0.32f, 1.00f);
    c[ImGuiCol_FrameBg]          = ImVec4(0.12f, 0.14f, 0.17f, 1.00f);
    c[ImGuiCol_FrameBgHovered]   = ImVec4(0.17f, 0.20f, 0.24f, 1.00f);
    c[ImGuiCol_FrameBgActive]    = ImVec4(0.20f, 0.24f, 0.29f, 1.00f);
    c[ImGuiCol_CheckMark]        = MM_GREEN;
    c[ImGuiCol_SliderGrab]       = MM_GREEN;
    c[ImGuiCol_SliderGrabActive] = ImVec4(0.18f, 0.95f, 0.50f, 1.00f);
    c[ImGuiCol_Header]           = ImVec4(0.14f, 0.17f, 0.21f, 1.00f);
    c[ImGuiCol_HeaderHovered]    = ImVec4(0.19f, 0.23f, 0.28f, 1.00f);
    c[ImGuiCol_HeaderActive]     = ImVec4(0.23f, 0.28f, 0.34f, 1.00f);
    c[ImGuiCol_Separator]        = ImVec4(1.00f, 1.00f, 1.00f, 0.08f);
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

- (void)setup
{
    if (self.view) return;
    UIWindow *win = [self mm_key_window];
    if (!win) return;

    self.device = MTLCreateSystemDefaultDevice();
    if (!self.device) return;              /* sin Metal no hay panel, y no rompe nada */
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
    io.IniFilename = NULL;                 /* sin .ini en Documents */
    io.LogFilename = NULL;
    io.Fonts->AddFontDefault();
    ImGui_ImplMetal_Init(self.device);

    self.view = v;
    [win addSubview:v];

    UIButton *fab = [UIButton buttonWithType:UIButtonTypeCustom];
    fab.frame = CGRectMake(win.bounds.size.width - 62.0, 96.0, 46.0, 46.0);
    fab.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
                           UIViewAutoresizingFlexibleBottomMargin;
    fab.backgroundColor = [UIColor colorWithRed:0.09 green:0.10 blue:0.13 alpha:0.92];
    fab.layer.cornerRadius = 23.0;
    fab.layer.borderWidth = 1.0;
    fab.layer.borderColor = [UIColor colorWithRed:0.14 green:0.84 blue:0.42 alpha:0.75].CGColor;
    [fab setTitle:@"GL" forState:UIControlStateNormal];
    [fab setTitleColor:[UIColor colorWithRed:0.14 green:0.84 blue:0.42 alpha:1.0]
              forState:UIControlStateNormal];
    fab.titleLabel.font = [UIFont boldSystemFontOfSize:15.0];
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
- (void)buildUI
{
    ImGuiIO &io = ImGui::GetIO();
    ImGui::SetNextWindowPos(ImVec2(io.DisplaySize.x * 0.5f - 170.0f, 90.0f),
                            ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowSize(ImVec2(340.0f, 0.0f), ImGuiCond_FirstUseEver);
    ImGui::Begin("FUSION", NULL, ImGuiWindowFlags_NoCollapse | ImGuiWindowFlags_AlwaysAutoResize);

    ImGui::TextColored(MM_GREEN, "%s", mm_panel_version());
    ImGui::SameLine();
    ImGui::TextDisabled("| %.0f FPS | %d obj", mm_panel_fps(), mm_panel_targets());

    if (mm_panel_lock_active())
        ImGui::TextColored(MM_GREEN, "aimlock ACTIVO (%ld frames)", mm_panel_lock_frames());
    else
        ImGui::TextDisabled("aimlock inactivo");

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

        ImGui::Separator();
        ImGui::TextDisabled("por tipo de arma");
        const char *kinds[4] = { "Fusil", "Subfusil", "Escopeta", "Franco" };
        for (int i = 0; i < 4; i++) {
            bool on = mm_panel_lock_kind(i + 1) != 0;
            if (i & 1) ImGui::SameLine();
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

    ImGui::Separator();
    if (ImGui::Button("Cerrar", ImVec2(-1, 34))) {
        [self close];
        mm_panel_close();
    }
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
