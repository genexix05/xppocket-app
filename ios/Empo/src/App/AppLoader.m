#import <UIKit/UIKit.h>
#import "AudioSession.h"

static Class empoBootstrapClass(void) {
    Class cls = NSClassFromString(@"EmpoUIBootstrap");
    if (!cls) {
        cls = NSClassFromString(@"XP_Pocket.EmpoUIBootstrap");
    }
    if (!cls) {
        cls = NSClassFromString(@"XPPocket.EmpoUIBootstrap");
    }
    return cls;
}

static void empoCallSelector(SEL sel) {
    Class cls = empoBootstrapClass();
    if (cls && [cls respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [cls performSelector:sel];
#pragma clang diagnostic pop
    }
}

static void empoCallBootstrap(void) {
    empoCallSelector(NSSelectorFromString(@"ensureAppWindowInstalled"));
}

static void empoScheduleBootstrapRetries(void) {
    // Xcode Play can run SDL_main before the Swift runtime registers
    // EmpoUIBootstrap. Retry until the overlay window exists.
    for (int i = 0; i < 120; i++) {
        dispatch_after(
            dispatch_time(DISPATCH_TIME_NOW, (int64_t)(i * 50 * NSEC_PER_MSEC)),
            dispatch_get_main_queue(), ^{
                empoCallBootstrap();
            });
    }
}

/// Called from mkxp_waitForGamePath on every run-loop pump so UIKit and
/// SwiftUI get layout/display-link time while SDL_main blocks the thread.
void empo_pumpUIKitShell(void) {
    if (![NSThread isMainThread]) {
        return;
    }
    empoCallSelector(NSSelectorFromString(@"pumpWhileWaiting"));
}

__attribute__((constructor)) static void appLoaderInit(void) {
    mkxp_configureAudioSession();
    dispatch_async(dispatch_get_main_queue(), ^{
        empoCallBootstrap();
        empoScheduleBootstrapRetries();
    });
}
