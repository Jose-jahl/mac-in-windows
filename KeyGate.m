/* ============================================================================
 *  KeyGate.m  -  arreglo de estabilidad
 *  ---------------------------------------------------------------------------
 *  Que pasaba antes
 *  ----------------
 *  El vigilante (commit 4be2dc7) presenting el dialogo sobre el controlador
 *  del JUEGO, cada 0,6 s, mientras creyera que no estaba en pantalla:
 *
 *      if (gate_visible()) { schedule_tick(0.6); return; }
 *      ...
 *      if (... || top.presentedViewController || ...) { schedule_tick(0.5); return; }
 *      build_alert(); [top presentViewController:g_alert ...];
 *
 *  Eso tiene dos fallos encadenados:
 *
 *  - La condicion de guarda mira top.presentedViewController, que es nil
 *    DURANTE la animacion de presentacion. En el siguiente tick el dialogo
 *    anterior sigue animandose, gate_visible() dice que no esta, y se presenta
 *    otro encima. UIKit lanza NSInternalInconsistencyException y la app muere.
 *
 *  - Si la presentacion falla, g_alert queda apuntando a un controlador que
 *    nunca se presento. Cada tick crea uno nuevo y lo intenta otra vez: se
 *    acumulan view controllers sin limite hasta que revienta.
 *
 *  Que se hace ahora
 *  -----------------
 *  El dialogo se presenta en una UIWindow PROPIA, con su propio
 *  UIViewController raiz. El juego puede cambiar de rootViewController,
 *  desmontar escenas y traerse lo suyo: esta ventana no depende de el.
 *
 *  Ademas:
 *    - g_presenting evita solapar dos presentaciones.
 *    - La presentacion va dentro de @try: una inconsistencia de UIKit avisa en
 *      el log y reintenta, pero no tumba la app.
 *    - El vigilante sigue como red, pero cada reintento cuenta y hay tope.
 * ==========================================================================*/

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <string.h>   /* memcpy / strlen, los usa el SHA-256 */
#import <stdlib.h>   /* exit(), para cerrar la app al cancelar o denegar */

static NSString *const kTitle  = @"CODM AIM";
static NSString *const kPrompt = @"Introduce tu llave.";

/* Ventana propia. El nivel alto la pone por encima de la del juego sin
   stealarle el foco: backgroundColor transparente y userInteractionEnabled
   en NO, asi que los toques siguen yendo al juego (que ya esta corriendo). */
static UIWindow           *g_win   = nil;
static UIAlertController  *g_alert = nil;

/* No tocar la ventana del juego en ningun momento. */

/* ============================================================================
 *  Utilidades
 * ==========================================================================*/

/* Ventana de la puerta. Se crea una sola vez y se reutiliza. */
static UIWindow *gate_window(void)
{
    if (g_win) return g_win;

    UIWindowScene *scene = nil;
    for (UIScene *sc in UIApplication.sharedApplication.connectedScenes) {
        if (![sc isKindOfClass:[UIWindowScene class]]) continue;
        if (sc.activationState != UISceneActivationStateForegroundActive) continue;
        scene = (UIWindowScene *)sc;
        break;
    }
    if (!scene) return nil;

    UIWindow *w = [[UIWindow alloc] initWithWindowScene:scene];
    w.windowLevel = UIWindowLevelAlert + 100.0;
    w.backgroundColor = [UIColor clearColor];
    w.userInteractionEnabled = YES;      /* el dialogo tiene que recibir toques */
    w.rootViewController = [[UIViewController alloc] init];
    w.hidden = NO;
    g_win = w;
    return g_win;
}

/* ¿Esta la puerta ya en pantalla? Se mira la ventana PROPIA, no la del juego. */
static BOOL gate_visible(void)
{
    if (!g_alert) return NO;
    if (g_alert.presentingViewController == nil) return NO;
    return YES;
}

/* ============================================================================
 *  Base del SHA-256 (identico a la version anterior)
 * ==========================================================================*/

typedef struct { uint32_t s[8]; uint64_t len; unsigned char buf[64]; size_t n; } sha256_t;

static const uint32_t K256[64] = {
0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2 };

#define ROR(x,n) (((x)>>(n))|((x)<<(32-(n))))

static void sha256_block(sha256_t *c, const unsigned char *p)
{
    uint32_t w[64], a,b,cc,d,e,f,g,h,t1,t2; int i;
    for (i = 0; i < 16; i++)
        w[i] = ((uint32_t)p[i*4]<<24)|((uint32_t)p[i*4+1]<<16)|((uint32_t)p[i*4+2]<<8)|p[i*4+3];
    for (; i < 64; i++) {
        uint32_t s0 = ROR(w[i-15],7)^ROR(w[i-15],18)^(w[i-15]>>3);
        uint32_t s1 = ROR(w[i-2],17)^ROR(w[i-2],19)^(w[i-2]>>10);
        w[i] = w[i-16] + s0 + w[i-7] + s1;
    }
    a=c->s[0];b=c->s[1];cc=c->s[2];d=c->s[3];e=c->s[4];f=c->s[5];g=c->s[6];h=c->s[7];
    for (i = 0; i < 64; i++) {
        uint32_t S1 = ROR(e,6)^ROR(e,11)^ROR(e,25);
        uint32_t ch = (e&f)^((~e)&g);
        t1 = h + S1 + ch + K256[i] + w[i];
        uint32_t S0 = ROR(a,2)^ROR(a,13)^ROR(a,22);
        uint32_t mj = (a&b)^(a&cc)^(b&cc);
        t2 = S0 + mj;
        h=g; g=f; f=e; e=d+t1; d=cc; cc=b; b=a; a=t1+t2;
    }
    c->s[0]+=a;c->s[1]+=b;c->s[2]+=cc;c->s[3]+=d;c->s[4]+=e;c->s[5]+=f;c->s[6]+=g;c->s[7]+=h;
}

static void sha256_init(sha256_t *c)
{
    c->s[0]=0x6a09e667;c->s[1]=0xbb67ae85;c->s[2]=0x3c6ef372;c->s[3]=0xa54ff53a;
    c->s[4]=0x510e527f;c->s[5]=0x9b05688c;c->s[6]=0x1f83d9ab;c->s[7]=0x5be0cd19;
    c->len = 0; c->n = 0;
}

static void sha256_update(sha256_t *c, const unsigned char *p, size_t len)
{
    c->len += (uint64_t)len * 8;
    while (len) {
        size_t take = 64 - c->n; if (take > len) take = len;
        memcpy(c->buf + c->n, p, take);
        c->n += take; p += take; len -= take;
        if (c->n == 64) { sha256_block(c, c->buf); c->n = 0; }
    }
}

static void sha256_final(sha256_t *c, unsigned char out[32])
{
    unsigned char pad = 0x80;
    uint64_t bits = c->len;
    sha256_update(c, &pad, 1);
    unsigned char z = 0;
    while (c->n != 56) sha256_update(c, &z, 1);
    for (int i = 7; i >= 0; i--) { unsigned char b = (unsigned char)(bits >> (i*8)); sha256_update(c, &b, 1); }
    for (int i = 0; i < 8; i++) {
        out[i*4]   = (unsigned char)(c->s[i] >> 24);
        out[i*4+1] = (unsigned char)(c->s[i] >> 16);
        out[i*4+2] = (unsigned char)(c->s[i] >> 8);
        out[i*4+3] = (unsigned char)(c->s[i]);
    }
}

static NSString *sha256_base64(NSString *input)
{
    sha256_t c; sha256_init(&c);
    const char *u = [input UTF8String] ?: "";
    sha256_update(&c, (const unsigned char *)u, strlen(u));
    unsigned char d[32]; sha256_final(&c, d);
    return [[NSData dataWithBytes:d length:32] base64EncodedStringWithOptions:0];
}

/* Comparacion en tiempo constante. */
static BOOL secure_equals(NSString *a, NSString *b)
{
    if (!a || !b) return NO;
    NSData *da = [a dataUsingEncoding:NSUTF8StringEncoding];
    NSData *db = [b dataUsingEncoding:NSUTF8StringEncoding];
    if (da.length != db.length) return NO;
    const uint8_t *pa = da.bytes, *pb = db.bytes;
    uint8_t diff = 0;
    for (NSUInteger i = 0; i < da.length; i++) diff |= (uint8_t)(pa[i] ^ pb[i]);
    return diff == 0;
}

/* ============================================================================
 *  Estado y callbacks
 * ==========================================================================*/

static NSString *kPlistKey    = @"CODMGateKey";
static NSString *kPlistDevice = @"CODMGateDevice";
static NSString *kStoreDevice = @"codmgate.devicehash.v1";

static NSString *g_expected = nil;
static BOOL     g_bind     = NO;
static BOOL     g_open     = NO;
static BOOL     g_refused  = NO;
static BOOL     g_presenting = NO;   /* hay una presentacion en curso */
static int      g_waits     = 0;

static const int kMaxWaits = 60;     /* 60 intentos x 1 s = 60 s */

/* --- huella del equipo ------------------------------------------------- */

static NSString *device_fingerprint(void)
{
    /* identifierForVendor es un NSUUID, no un NSString. El UUIDString es
       exactamente la misma cadena de texto que se usaba antes, asi que los
       hashes ya atados en NSUserDefaults siguen valiendo. */
    NSUUID *u = [UIDevice currentDevice].identifierForVendor;
    if (u == nil) return nil;
    NSString *v = [u UUIDString];
    if (v.length == 0) return nil;
    return sha256_base64(v);
}

static NSString *device_problem(void)
{
    NSString *now = device_fingerprint();
    if (!now) return nil;
    NSString *saved = [[NSUserDefaults standardUserDefaults] stringForKey:kStoreDevice];
    if (!saved || saved.length == 0) return nil;
    if ([saved isEqualToString:now]) return nil;
    return @"Esta llave ya se valido en otro equipo.";
}

static void device_bind(void)
{
    NSString *fp = device_fingerprint();
    if (!fp) return;
    NSUserDefaults *u = [NSUserDefaults standardUserDefaults];
    [u setObject:fp forKey:kStoreDevice];
    [u synchronize];
}

/* ============================================================================
 *  Presentacion
 * ==========================================================================*/

static void refuse(NSString *why);
static void gate_tick(void);

static void build_alert(NSString *why)
{
    UIAlertController *a =
        [UIAlertController alertControllerWithTitle:@"Acceso denegado"
                                           message:(why ?: @"Acceso denegado")
                                    preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"Salir"
                                         style:UIAlertActionStyleDestructive
                                       handler:^(UIAlertAction *act) { exit(0); }]];
    g_alert = a;
}

/* Presenta el dialogo de la llave en la ventana propia. Devuelve NO si no se
   pudo; nunca deja la app en un estado raro. */
static BOOL present_prompt(void)
{
    if (g_presenting) return NO;
    if (gate_visible()) return YES;

    UIWindow *w = gate_window();
    if (!w) return NO;

    UIAlertController *a =
        [UIAlertController alertControllerWithTitle:kTitle
                                           message:kPrompt
                                    preferredStyle:UIAlertControllerStyleAlert];
    [a addTextFieldWithConfigurationHandler:^(UITextField *tf) {
        tf.placeholder = @"llave";
        tf.secureTextEntry = YES;
        tf.autocorrectionType = UITextAutocorrectionTypeNo;
        tf.autocapitalizationType = UITextAutocapitalizationTypeNone;
        tf.spellCheckingType = UITextSpellCheckingTypeNo;
        tf.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];

    __weak UIAlertController *weak = a;
    [a addAction:[UIAlertAction actionWithTitle:@"Entrar"
                                         style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction *act) {
        NSString *typed = weak.textFields.firstObject.text ?: @"";
        typed = [typed stringByTrimmingCharactersInSet:
                    [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (typed.length == 0) { refuse(@"No introdujiste ninguna llave."); return; }
        if (!secure_equals(sha256_base64(typed), g_expected)) { refuse(@"La llave no es correcta."); return; }
        if (g_bind) device_bind();
        g_open = YES;
        g_presenting = NO;
        [g_win resignKeyWindow];
        g_win.hidden = YES;
    }]];

    [a addAction:[UIAlertAction actionWithTitle:@"Cancelar"
                                         style:UIAlertActionStyleCancel
                                       handler:^(UIAlertAction *act) { exit(0); }]];

    g_alert = a;
    g_presenting = YES;

    @try {
        /* animated:NO evita la ventana de tiempo en la que UIKit considera que
           hay una presentacion en curso. Es la causa del crash anterior. */
        [w.rootViewController presentViewController:a animated:NO completion:^{
            g_presenting = NO;
        }];
    }
    @catch (NSException *e) {
        /* Inconsistencia de UIKit: se avisa y se reintenta en el siguiente
           tick. Lo que no se hace es tumbar la app. */
        NSLog(@"[KeyGate] presentacion fallida: %@", e.reason);
        g_presenting = NO;
        g_alert = nil;
        return NO;
    }
    return YES;
}

static void refuse(NSString *why)
{
    g_refused = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        build_alert(why);
        UIWindow *w = gate_window();
        if (!w) { exit(0); return; }
        @try {
            [w.rootViewController presentViewController:g_alert animated:NO completion:nil];
        } @catch (NSException *e) {
            NSLog(@"[KeyGate] no se pudo mostrar el aviso: %@", e.reason);
            exit(0);
        }
    });
    /* Si el usuario no toca nada, se cierra solo. */
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{ exit(0); });
}

/* El vigilante. Cada 0,8 s, mientras la puerta este cerrada. */
static void schedule_tick(double delay)
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{ gate_tick(); });
}

static void gate_tick(void)
{
    if (g_open || g_refused) return;
    if (g_presenting) { schedule_tick(0.8); return; }

    if (gate_visible()) {
        g_waits = 0;
        schedule_tick(0.8);
        return;
    }

    /* Todavia no hay escena activa. Se espera. */
    if (!gate_window()) {
        if (++g_waits > kMaxWaits) { refuse(@"No se pudo mostrar la pantalla de llave."); return; }
        schedule_tick(1.0);
        return;
    }

    if (!present_prompt()) {
        if (++g_waits > kMaxWaits) { refuse(@"No se pudo mostrar la pantalla de llave."); return; }
        schedule_tick(1.0);
        return;
    }

    g_waits = 0;
    schedule_tick(0.8);
}

/* ============================================================================
 *  Arranque
 * ==========================================================================*/

__attribute__((constructor))
static void KeyGate_init(void)
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        NSString *expected = [[NSBundle mainBundle] objectForInfoDictionaryKey:kPlistKey];
        if (![expected isKindOfClass:[NSString class]] || expected.length == 0) {
            return;   /* esta build no va protegida */
        }

        id dev = [[NSBundle mainBundle] objectForInfoDictionaryKey:kPlistDevice];
        BOOL bindDevice = [dev isKindOfClass:[NSString class]] && [dev isEqualToString:@"1"];

        if (bindDevice) {
            NSString *bad = device_problem();
            if (bad) { refuse(bad); return; }
        }

        g_expected = expected;
        g_bind     = bindDevice;
        gate_tick();
    });
}