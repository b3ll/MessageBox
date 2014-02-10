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

- (void)applicationWillResignActive:(UIApplication *)application {
    notify_post("ca.adambell.messagebox.fbQuitting");
    DebugLog(@"FACEBOOK QUITTING RIGHT NOW");

    FBApplicationController *controller = [%c(FBApplicationController) sharedInstance];

    controller.messengerModule.chatHeadViewController.chatHeadSurfaceView.hasInbox = YES;
    [controller.messengerModule.chatHeadViewController showComposerChatHead];
    [controller.messengerModule.chatHeadViewController resignChatHeadViews];
    [controller.messengerModule.chatHeadViewController.chatHeadSurfaceView sortChatHeads];

    [controller setUIHiddenForMessageBox:YES];

    %orig;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    notify_post("ca.adambell.messagebox.fbLaunching");
    DebugLog(@"FACEBOOK OPENING RIGHT NOW");

    FBApplicationController *controller = [%c(FBApplicationController) sharedInstance];
    [controller setUIHiddenForMessageBox:NO];

    %orig;
}

%end

%hook FBApplicationController
- (id)initWithSession:(id)session {
    _applicationController = %orig;

    return _applicationController;
}

%new
- (void)setUIHiddenForMessageBox:(BOOL)hidden {
    [[UIApplication sharedApplication].keyWindow setKeepContextInBackground:hidden];

    [UIApplication sharedApplication].keyWindow.backgroundColor = hidden ? [UIColor clearColor] : [UIColor blackColor];

    FBChatHeadViewController *chatHeadController = _applicationController.messengerModule.chatHeadViewController;

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

    [[UIApplication sharedApplication].keyWindow setNeedsDisplay];
}

%new
+ (id)sharedInstance {
    return _applicationController;
}

%end

%end
