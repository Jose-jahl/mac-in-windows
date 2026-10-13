/*
 *  KeyGate.dylib   —   llave de inicio para CODM
 *  ------------------------------------------------------------------
 *  Se inyecta en cod.app con una entrada LC_LOAD_DYLIB. Al arrancar la app
 *  lee la llave esperada del Info.plist (clave CODMGateKey = SHA-256 en
 *  base64), la pide al usuario y cierra la app si no coincide.
 *
 *  Solo depende de Foundation y UIKit. El SHA-256 va implementado aqui
 *  para no depender de CommonCrypto ni de ningun SDK concreto: compila
 *  en Mac, Linux, WSL o GitHub Actions con el mismo clang.
 *
 *  La llave en claro NUNCA va dentro de la IPA, solo su hash. Por eso un
 *  mismo dylib sirve para cualquier llave: la herramienta escribe el hash.
 */

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <string.h>

static NSString *const kPlistKey    = @"CODMGateKey";
static NSString *const kPlistDevice = @"CODMGateDevice";

/* Donde queda guardada, en el equipo, la huella del primer telefono que valido
   la llave. Vive en NSUserDefaults: se crea al vuelo, no va dentro de la IPA. */
static NSString *const kStoreDevice = @"codmgate.devicehash.v1";

/* ==================================================================== SHA-256 */

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

/* Comparacion en tiempo constante: no filtra nada por temporizacion. */
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

/* ============================================================ atar al equipo */

/* identifierForVendor no pide permiso ni entitlement y no se puede leer desde
   fuera. Solo cambia si se borran TODAS las apps del mismo fabricante del
   telefono, que para este caso es justo lo que se quiere. */
static NSString *device_fingerprint(void)
{
    NSString *v = [UIDevice currentDevice].identifierForVendor;
    if (v.length == 0) return nil;
    return sha256_base64(v);
}

/* Devuelve nil si todo esta bien, o el motivo por el que hay que bloquear.
   Si el equipo no se puede identificar no se bloquea nunca: es preferible
   dejar pasar a dejar al usuario sin poder jugar. */
static NSString *device_problem(void)
{
    NSString *now = device_fingerprint();
    if (!now) return nil;                                   // no se puede comprobar
    NSString *saved = [[NSUserDefaults standardUserDefaults] stringForKey:kStoreDevice];
    if (!saved || saved.length == 0) return nil;             // primer uso: se atara luego
    if ([saved isEqualToString:now]) return nil;             // mismo equipo
    return @"Esta llave ya se valido en otro equipo.";
}

/* Se llama justo despues de acertar la llave: fija el equipo. */
static void device_bind(void)
{
    NSString *fp = device_fingerprint();
    if (!fp) return;
    NSUserDefaults *u = [NSUserDefaults standardUserDefaults];
    [u setObject:fp forKey:kStoreDevice];
    [u synchronize];
}

/* ==================================================================== UI */

static UIWindow *active_window(void)
{
    UIApplication *app = UIApplication.sharedApplication;

    /* API de escenas: la que sigue en pie desde iOS 13. */
    for (UIScene *sc in app.connectedScenes) {
        if (![sc isKindOfClass:[UIWindowScene class]]) continue;
        if (sc.activationState != UISceneActivationStateForegroundActive) continue;
        for (UIWindow *c in ((UIWindowScene *)sc).windows)
            if (c.isKeyWindow) return c;
    }
    /* Si ninguna escena esta en primer plano, sirve la primera ventana que haya. */
    for (UIScene *sc in app.connectedScenes) {
        if (![sc isKindOfClass:[UIWindowScene class]]) continue;
        for (UIWindow *c in ((UIWindowScene *)sc).windows)
            return c;
    }
    /* Reserva para apps que no usan escenas. */
    id delegate = app.delegate;
    if ([delegate respondsToSelector:@selector(window)])
        return [delegate window];
    return nil;
}

static void refuse(NSString *why)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *a =
            [UIAlertController alertControllerWithTitle:@"Acceso denegado"
                                               message:why
                                        preferredStyle:UIAlertControllerStyleAlert];
        [a addAction:[UIAlertAction actionWithTitle:@"Salir"
                                             style:UIAlertActionStyleDestructive
                                           handler:^(UIAlertAction *act) { exit(0); }]];
        UIWindow *w = active_window();
        UIViewController *top = w.rootViewController;
        while (top.presentedViewController) top = top.presentedViewController;
        [top presentViewController:a animated:YES completion:nil];
    });
    /* Si el usuario no toca nada, se cierra solo. */
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{ exit(0); });
}

static void ask(NSString *expected, BOOL bindDevice)
{
    UIAlertController *a =
        [UIAlertController alertControllerWithTitle:@"CODM AIM"
                                           message:@"Introduce tu llave."
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
        if (!secure_equals(sha256_base64(typed), expected)) { refuse(@"La llave no es correcta."); return; }
        /* Correcta: se ata al equipo la primera vez y la app sigue su curso. */
        if (bindDevice) device_bind();
    }]];

    [a addAction:[UIAlertAction actionWithTitle:@"Cancelar"
                                         style:UIAlertActionStyleCancel
                                       handler:^(UIAlertAction *act) { exit(0); }]];

    UIWindow *w = active_window();
    if (!w) { refuse(@"No se pudo mostrar el diálogo."); return; }
    UIViewController *top = w.rootViewController;
    while (top.presentedViewController) top = top.presentedViewController;
    [top presentViewController:a animated:YES completion:nil];
}

/* ================================================================ arranque */

__attribute__((constructor))
static void KeyGate_init(void)
{
    /* Margen para que la app termine de arrancar y tenga ventana. */
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        NSString *expected = [[NSBundle mainBundle] objectForInfoDictionaryKey:kPlistKey];
        if (![expected isKindOfClass:[NSString class]] || expected.length == 0) {
            /* Sin llave configurada: esta build no va protegida. */
            return;
        }

        id dev = [[NSBundle mainBundle] objectForInfoDictionaryKey:kPlistDevice];
        BOOL bindDevice = [dev isKindOfClass:[NSString class]] && [dev isEqualToString:@"1"];

        /* Si ya se ató a otro equipo, no se llega ni a pedir la llave. */
        if (bindDevice) {
            NSString *bad = device_problem();
            if (bad) { refuse(bad); return; }
        }

        ask(expected, bindDevice);
    });
}
