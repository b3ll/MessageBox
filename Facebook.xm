//
//  Facebook.xm
//  MessageBox
//
//  Created by Adam Bell on 2014-02-04.
//  Copyright (c) 2014 Adam Bell. All rights reserved.
//

#import "messagebox.h"

static FBApplicationController *_applicationController;
static FBMessengerModule *_messengerModule;

static BOOL shouldShowPublisherBar = NO;

/**
 * Facebook Hooks
 *
 */
%group FacebookHooks

// Keyboards also need to be shown when the app is backgrounded
%hook UITextEffectsWindow

- (void)setKeepContextInBackground:(BOOL)keepContext {
    %orig(YES);
}

- (BOOL)keepContextInBackground {
    return YES;
}

- (CGFloat)windowLevel {
    return 1003.0f;
}

- (void)setWindowLevel:(CGFloat)windowLevel {
    %orig(1003.0f);
}

%end

// Need to force the app to believe it's still active... no notifications for you! >:D
%hook NSNotificationCenter

- (void)postNotificationName:(NSString *)notificationName object:(id)notificationSender userInfo:(NSDictionary *)userInfo {
    NSString *notification = [notificationName lowercaseString];
    if ([notification rangeOfString:@"background"].location != NSNotFound) {
        return;
    }

    DebugLog(@"Notification Posted: %@ object: %@ userInfo: %@", notificationName, notificationSender, userInfo);
    %orig;
}

%end

%hook UIApplication

- (UIApplicationState)applicationState {
    return UIApplicationStateActive;
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

    shouldShowPublisherBar = hidden;
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
    return shouldShowPublisherBar;
}

%end

static void fbResignChatHeads(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    FBApplicationController *controller = [%c(FBApplicationController) mb_sharedInstance];
    [controller.messengerModule.chatHeadViewController resignChatHeadViews];
}

%end
