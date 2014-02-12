//
//  Facebook.xm
//  MessageBox
//
//  Created by Adam Bell on 2014-02-04.
//  Copyright (c) 2014 Adam Bell. All rights reserved.
//

#import "messagebox.h"

#define KEYBOARD_WINDOW_LEVEL 1003.0f

static FBApplicationController *_applicationController;
static FBMessengerModule *_messengerModule;

static BOOL _shouldShowPublisherBar = NO;

static BOOL _ignoreBackgroundedNotifications = YES;

/**
 * Facebook Hooks
 *
 */
%group FacebookHooks

static void fbResignChatHeads(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    FBApplicationController *controller = [%c(FBApplicationController) mb_sharedInstance];
    [controller.messengerModule.chatHeadViewController resignChatHeadViews];
}

static void fbForceActive(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    _ignoreBackgroundedNotifications = YES;
    FBApplicationController *controller = [%c(FBApplicationController) mb_sharedInstance];
    [controller.messengerModule enteredForeground];
}

static void fbForceBackgrounded(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    _ignoreBackgroundedNotifications = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil userInfo:nil];
}

// Keyboards also need to be shown when the app is backgrounded
%hook UITextEffectsWindow

- (void)setKeepContextInBackground:(BOOL)keepContext {
    %orig(YES);
}

- (BOOL)keepContextInBackground {
    return YES;
}

// Paper does some weird shit with window levels... no u
- (CGFloat)windowLevel {
    return KEYBOARD_WINDOW_LEVEL;
}

- (void)setWindowLevel:(CGFloat)windowLevel {
    %orig(KEYBOARD_WINDOW_LEVEL);
}

%end

// Need to force the app to believe it's still active... no notifications for you! >:D
%hook NSNotificationCenter

- (void)postNotificationName:(NSString *)notificationName object:(id)notificationSender userInfo:(NSDictionary *)userInfo {
    NSString *notification = [notificationName lowercaseString];
    if ([notification rangeOfString:@"background"].location != NSNotFound && _ignoreBackgroundedNotifications) {
        return;
    }

    DebugLog(@"Notification Posted: %@ object: %@ userInfo: %@", notificationName, notificationSender, userInfo);
    %orig;
}

%end

%hook UIApplication

- (UIApplicationState)applicationState {
    if (_ignoreBackgroundedNotifications)
        return UIApplicationStateActive;
    else
        return %orig;
}

%end

%hook AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL didFinishLaunching = %orig;

    for (UIWindow *window in application.windows) {
        [window setKeepContextInBackground:YES];
    }

    return didFinishLaunching;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    notify_post("ca.adambell.messagebox.fbQuitting");
    DebugLog(@"FACEBOOK QUITTING RIGHT NOW");

    [[UIApplication sharedApplication].keyWindow endEditing:YES];

    FBApplicationController *controller = [%c(FBApplicationController) mb_sharedInstance];
    [controller mb_setUIHiddenForMessageBox:YES];

    %orig;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    notify_post("ca.adambell.messagebox.fbLaunching");
    DebugLog(@"FACEBOOK OPENING RIGHT NOW");

    FBApplicationController *controller = [%c(FBApplicationController) mb_sharedInstance];
    [controller mb_setUIHiddenForMessageBox:NO];

    %orig;
}

%end

%hook FBApplicationController

- (id)initWithSession:(id)session {
    _applicationController = %orig;
    return _applicationController;
}

%new
+ (id)mb_sharedInstance {
    return _applicationController;
}

%new
- (void)mb_setUIHiddenForMessageBox:(BOOL)hidden {
    [[UIApplication sharedApplication].keyWindow setKeepContextInBackground:hidden];

    [UIApplication sharedApplication].keyWindow.backgroundColor = hidden ? [UIColor clearColor] : [UIColor blackColor];

    FBChatHeadViewController *chatHeadController = _applicationController.messengerModule.chatHeadViewController;
    [chatHeadController resignChatHeadViews];
    [chatHeadController setHasInboxChatHead:hidden];

    FBStackView *stackView = (FBStackView *)chatHeadController.view;
    UIView *chatHeadContainerView = stackView;

    while (![stackView isKindOfClass:%c(FBStackView)]) {
        if (stackView.superview == nil)
            break;

        chatHeadContainerView = stackView;
        stackView = (FBStackView *)stackView.superview;
    }

    for (UIView *view in stackView.subviews) {
        if (view != chatHeadContainerView && ![view isKindOfClass:%c(FBDimmingView)])
            view.hidden = hidden;
    }

    // Account for status bar
    CGRect chatHeadWindowFrame = [UIScreen mainScreen].bounds;
    if (hidden) {
        chatHeadWindowFrame.origin.y += 20.0;
        chatHeadWindowFrame.size.height -= 20.0;
    }

    [UIApplication sharedApplication].keyWindow.frame = chatHeadWindowFrame;

    _shouldShowPublisherBar = hidden;
}

%end

%hook FBMInboxViewController

- (void)viewWillAppear:(BOOL)animated {
    %orig;

    self.inboxView.showPublisherBar = 0;
}

%end

%hook FBMInboxView

- (void)setShowPublisherBar:(BOOL)showPublisherBar {
    %orig([self mb_shouldShowPublisherBar]);
}

%new
- (BOOL)mb_shouldShowPublisherBar {
    return _shouldShowPublisherBar;
}

%end

%end
