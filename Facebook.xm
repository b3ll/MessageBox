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

%hook AppDelegate

- (void)applicationWillResignActive:(UIApplication *)application {
    notify_post("ca.adambell.messagebox.fbQuitting");
    DebugLog(@"FACEBOOK QUITTING RIGHT NOW");
    [[%c(FBApplicationController) sharedInstance] setUIHiddenForMessageBox:YES];
    %orig;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    notify_post("ca.adambell.messagebox.fbLaunching");
    DebugLog(@"FACEBOOK OPENING RIGHT NOW");
    [[%c(FBApplicationController) sharedInstance] setUIHiddenForMessageBox:NO];
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
