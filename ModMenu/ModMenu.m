/*=============================================================================
 *  ModMenu.m  -  menu runtime del proyecto fusion (fase A)
 *  ---------------------------------------------------------------------------
 *  Este archivo se compila como ModMenu.dylib y la herramienta lo mete en el
 *  IPA REEMPLAZANDO el binario de una framework que el juego ya carga:
 *
 *      Payload/cod.app/Frameworks/MSDKPolicy.framework/MSDKPolicy
 *
 *  Consecuencias (el motivo de hacerlo asi):
 *    - cero LC_LOAD_DYLIB nuevas en el cod: dyld carga la framework porque
 *      ya venia en su lista de imagenes;
 *    - cero claves nuevas en el Info.plist;
 *    - cero archivos nuevos en el paquete.
 *  Es la misma tecnica del modder que sigue vivo (SP3CTERIOS V1.2.0).
 *
 *  Fase A = prueba de vida:
 *    1. el constructor anota en el log del sistema que la dylib cargo;
 *    2. a los ~0.5 s aparece una burbuja flotante "ModMenu cargado".
 *  Cuando eso se vea en el equipo desechable, el esqueleto esta validado y
 *  las siguientes fases (ESP, skins, stream, guest reset, anti-checksum) se
 *  cuelgan de este mismo binario.
 *============================================================================*/

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#include <unistd.h>

#define MODMENU_VERSION "0.1.0-faseA"
#define MM_TAG          "[MODMENU]"

/* Marcador global: el CI lo verifica para confirmar que este fuente llego al
   binario (el constructor es static y no sirve como prueba de presencia). */
const char *modmenu_build_id = "modmenu-faseA-0.1.0";

static UIWindow *g_pill_win = nil;

/* Escena activa, si ya existe. */
static UIWindowScene *mm_active_scene(void)
{
    for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
        if (![s isKindOfClass:[UIWindowScene class]]) continue;
        if (s.activationState == UISceneActivationStateForegroundActive ||
            s.activationState == UISceneActivationStateForegroundInactive)
            return (UIWindowScene *)s;
    }
    return nil;
}

/* Crea la burbuja. Reintenta cada 0.5 s hasta 40 veces (~20 s) por si la app
   todavia no tiene escena cuando llegamos (el constructor corre muy temprano).
   En fase A la ventana NO recibe toques: solo tiene que verse. */
static void mm_pill_try(int intento)
{
    if (intento >= 40) {
        NSLog(@"%s burbuja: sin escena tras 20 s; me rindo", MM_TAG);
        return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        UIWindowScene *scene = mm_active_scene();
        if (scene == nil) { mm_pill_try(intento + 1); return; }

        g_pill_win = [[UIWindow alloc] initWithWindowScene:scene];
        g_pill_win.frame = CGRectMake(12, 100, 250, 34);
        g_pill_win.windowLevel = UIWindowLevelAlert + 2;
        g_pill_win.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.55];
        g_pill_win.layer.cornerRadius = 8.0;
        g_pill_win.clipsToBounds = YES;
        g_pill_win.userInteractionEnabled = NO;   /* fase A: no roba toques */

        UIViewController *vc = [[UIViewController alloc] init];
        g_pill_win.rootViewController = vc;

        UILabel *lbl = [[UILabel alloc] initWithFrame:g_pill_win.bounds];
        lbl.text = @"ModMenu " MODMENU_VERSION @" cargado";
        lbl.textColor = [UIColor colorWithRed:0.35 green:1.0 blue:0.55 alpha:1.0];
        lbl.font = [UIFont boldSystemFontOfSize:13.0];
        lbl.textAlignment = NSTextAlignmentCenter;
        [vc.view addSubview:lbl];

        g_pill_win.hidden = NO;
        NSLog(@"%s burbuja en pantalla v%s", MM_TAG, MODMENU_VERSION);
    });
}

__attribute__((constructor)) static void modmenu_init(void)
{
    NSLog(@"%s dylib cargada v%s  bundle=%s  pid=%d",
          MM_TAG, MODMENU_VERSION,
          [NSBundle.mainBundle.bundleIdentifier UTF8String],
          (int)getpid());
    mm_pill_try(0);
}
