//
//  Paper.xm
//  MessageBox
//
//  Created by Adam Bell on 2014-02-04.
//  Copyright (c) 2014 Adam Bell. All rights reserved.
//

#import "messagebox.h"

#define KEYBOARD_WINDOW_LEVEL 1003.0f

static FBApplicationController *_applicationController;
static FBMessengerModule *_messengerModule_paper;

static BOOL _shouldShowPublisherBar_paper = NO;

static BOOL _ignoreBackgroundedNotifications_paper = YES;

static BOOL _UIHiddenForMessageBox_paper;

/**
 * Paper Hooks
 *
 */
GROUP(PaperHooks)

static void paperResignChatHeads(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    FBApplicationController *controller = [GET_CLASS(FBApplicationController) mb_sharedInstance];
    [controller.messengerModule.chatHeadViewController resignChatHeadViews];
    [[UIApplication sharedApplication].keyWindow endEditing:YES];
}

static void paperForceActive(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    _ignoreBackgroundedNotifications_paper = YES;
    FBApplicationController *controller = [GET_CLASS(FBApplicationController) mb_sharedInstance];
    [controller.messengerModule.moduleSession enteredForeground];
}

static void paperForceBackgrounded(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    _ignoreBackgroundedNotifications_paper = NO;
    [[[UIApplication sharedApplication] delegate] applicationDidEnterBackground:[UIApplication sharedApplication]];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil userInfo:nil];
}

// Keyboards also need to be shown when the app is backgrounded
HOOK(UITextEffectsWindow)

//TODO: Pretty sure this isn't necessary, figure out later
- (id)init {
    UITextEffectsWindow *window = ORIG();
    [window setKeepContextInBackground:YES];
    return window;
}

- (void)setKeepContextInBackground:(BOOL)keepContext {
    ORIG(YES);
}

- (BOOL)keepContextInBackground {
    return YES;
}

// Paper does some weird shit with window levels... no u
- (CGFloat)windowLevel {
    return KEYBOARD_WINDOW_LEVEL;
}

- (void)setWindowLevel:(CGFloat)windowLevel {
    ORIG(KEYBOARD_WINDOW_LEVEL);
}

END()

// Since UIMenuItems hate being displayed for some odd reason when an app is in a hosted view, force them to always appear... #yolo
HOOK(UICalloutBar)
- (void)expandAfterAlertOrBecomeActive:(id)arg1 {
    [self setValue:@(YES) forKey:@"m_shouldAppear"];
}

- (void)flattenForAlertOrResignActive:(id)arg1 {
    [self setValue:@(YES) forKey:@"m_shouldAppear"];
}
END()

// Need to force the app to believe it's still active... no notifications for you! >:D
HOOK(NSNotificationCenter)

- (void)postNotificationName:(NSString *)notificationName object:(id)notificationSender userInfo:(NSDictionary *)userInfo {
    NSString *notification = [notificationName lowercaseString];
    if ([notification rangeOfString:@"background"].location != NSNotFound && _ignoreBackgroundedNotifications_paper) {
        notify_post("ca.adambell.messagebox.paperQuitting");

        [[UIApplication sharedApplication].keyWindow endEditing:YES];

        FBApplicationController *controller = [GET_CLASS(FBApplicationController) mb_sharedInstance];
        [controller mb_setUIHiddenForMessageBox:YES];

        return;
    }

    DebugLog(@"Notification Posted: %@ object: %@ userInfo: %@", notificationName, notificationSender, userInfo);

    ORIG();
}

END()

HOOK(UIApplication)

- (UIApplicationState)applicationState {
    if (_ignoreBackgroundedNotifications_paper)
        return UIApplicationStateActive;
    else
        return (UIApplicationState)ORIG_T();
}

END()

HOOK(AppDelegate)

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    for (UIWindow *window in application.windows) {
        [window setKeepContextInBackground:YES];
    }

    return ORIG_T();
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    notify_post("ca.adambell.messagebox.paperLaunching");
    DebugLog(@"PAPER OPENING RIGHT NOW");

    FBApplicationController *controller = [GET_CLASS(FBApplicationController) mb_sharedInstance];
    [controller mb_setUIHiddenForMessageBox:NO];

    ORIG();
}

END()

HOOK(FBApplicationController)

- (id)initWithSession:(id)session {
    _applicationController = ORIG();
    return _applicationController;
}

NEW()
+ (id)mb_sharedInstance {
    return _applicationController;
}

NEW()
- (void)mb_setUIHiddenForMessageBox:(BOOL)hidden {
    _UIHiddenForMessageBox_paper = hidden;

    [[UIApplication sharedApplication].keyWindow setKeepContextInBackground:hidden];

    [UIApplication sharedApplication].keyWindow.backgroundColor = hidden ? [UIColor clearColor] : [UIColor blackColor];

    FBChatHeadViewController *chatHeadController = self.messengerModule.chatHeadViewController;
    [chatHeadController resignChatHeadViews];
    [chatHeadController setHasInboxChatHead:hidden];

    FBStackView *stackView = (FBStackView *)chatHeadController.view;
    UIView *chatHeadContainerView = stackView;

    while (![stackView isKindOfClass:GET_CLASS(FBStackView)]) {
        if (stackView.superview == nil)
            break;

        chatHeadContainerView = stackView;
        stackView = (FBStackView *)stackView.superview;
    }

    for (UIView *view in stackView.subviews) {
        if (view != chatHeadContainerView && ![view isKindOfClass:GET_CLASS(FBDimmingView)])
            view.hidden = hidden;
    }

    // Account for status bar
    CGRect chatHeadWindowFrame = [UIScreen mainScreen].bounds;
    if (hidden) {
        chatHeadWindowFrame.origin.y += 20.0;
        chatHeadWindowFrame.size.height -= 20.0;
    }

    self.messengerModule.chatHeadViewController.chatHeadSurfaceView.frame = chatHeadWindowFrame;

    for (UIView *subview in [UIApplication sharedApplication].keyWindow.subviews) {
        [subview setNeedsLayout];
    }

    _shouldShowPublisherBar_paper = hidden;
}

NEW()
- (void)mb_openURL:(NSURL *)url {
    CPDistributedMessagingCenter *sbMessagingCenter = [GET_CLASS(CPDistributedMessagingCenter) centerNamed:@"ca.adambell.MessageBox.sbMessagingCenter"];
    rocketbootstrap_distributedmessagingcenter_apply(sbMessagingCenter);

    [sbMessagingCenter sendMessageName:@"messageboxOpenURL" userInfo:@{ @"url" : [url absoluteString] }];

    FBChatHeadViewController *chatHeadController = self.messengerModule.chatHeadViewController;
    [chatHeadController resignChatHeadViews];
}

NEW()
- (void)mb_forceRotationToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    DebugLog(@"NEXT ORIENTATION: %d", (int)orientation);

    // Popover blows up when rotated
    FBChatHeadViewController *chatHeadController = self.messengerModule.chatHeadViewController;
    [chatHeadController resignChatHeadViews];

    [[UIApplication sharedApplication] setStatusBarOrientation:orientation];

    for (UIWindow *window in [[UIApplication sharedApplication] windows]) {
        [window _setRotatableViewOrientation:orientation
                                    duration:0.0
                                       force:YES];
    }

    /*
     Some crazy UIKeyboard hacks because for some reason UIKeyboard has a seizure when a suspended app tries to rotate...

     if orientation == 1
     revert to identity matrix
     if orientation == 2
     flip keyboard PI
     if orientation == 3
     flip keyboard PI/2 RAD
     set frame & bounds to screen size
     if orientation == 4
     flip keyboard -PI/2 RAD
     set frame & bounds to screen size
     */

    UITextEffectsWindow *keyboardWindow = [UITextEffectsWindow sharedTextEffectsWindow];

    switch (orientation) {
        case UIInterfaceOrientationPortrait: {
            keyboardWindow.transform = CGAffineTransformIdentity;
            break;
        }
        case UIInterfaceOrientationPortraitUpsideDown: {
            keyboardWindow.transform = CGAffineTransformMakeRotation(M_PI);
            break;
        }
        case UIInterfaceOrientationLandscapeLeft: {
            keyboardWindow.transform = CGAffineTransformMakeRotation(-M_PI / 2);
            keyboardWindow.bounds = [[UIScreen mainScreen] bounds];
            keyboardWindow.frame = keyboardWindow.bounds;
            break;
        }
        case UIInterfaceOrientationLandscapeRight: {
            keyboardWindow.transform = CGAffineTransformMakeRotation(M_PI / 2);
            keyboardWindow.bounds = [[UIScreen mainScreen] bounds];
            keyboardWindow.frame = keyboardWindow.bounds;
            break;
        }
        default:
            break;
    }
}

END()

HOOK(FBMInboxViewController)

- (void)viewWillAppear:(BOOL)animated {
    ORIG();

    self.inboxView.showPublisherBar = 0;
}

END()

HOOK(FBMInboxView)

- (void)setShowPublisherBar:(BOOL)showPublisherBar {
    ORIG([self mb_shouldShowPublisherBar]);
}

NEW()
- (BOOL)mb_shouldShowPublisherBar {
    return _shouldShowPublisherBar_paper;
}

END()

HOOK(FBChatHeadSurfaceView)

- (void)setCurrentLayout:(FBChatHeadLayout *)currentLayout {
    CPDistributedMessagingCenter *sbMessagingCenter = [GET_CLASS(CPDistributedMessagingCenter) centerNamed:@"ca.adambell.MessageBox.sbMessagingCenter"];
    rocketbootstrap_distributedmessagingcenter_apply(sbMessagingCenter);
    [sbMessagingCenter sendMessageName:@"messageboxUpdateChatHeadsState" userInfo:@{ @"opened" : @(currentLayout == self.openedLayout) }];

    ORIG();
}

- (void)setFrame:(CGRect)frame {
    if (_UIHiddenForMessageBox_paper) {
        CGRect chatHeadWindowFrame = [UIScreen mainScreen].bounds;
        if (_UIHiddenForMessageBox_paper) {
            chatHeadWindowFrame.origin.y += 20.0;
            chatHeadWindowFrame.size.height -= 20.0;
        }
        
        ORIG(chatHeadWindowFrame);
    }
    else {
        ORIG();
    }
}

END()

HOOK_AND_DECLARE(MessagesViewController, UIViewController)

- (void)messageCell:(id)arg1 didSelectURL:(NSURL *)url {
    if (_UIHiddenForMessageBox_paper && [url isKindOfClass:[NSURL class]] && url != nil) {
        FBApplicationController *applicationController = [GET_CLASS(FBApplicationController) mb_sharedInstance];
        [applicationController mb_openURL:url];
    }
    else {
        ORIG();
    }
}

END()

END_GROUP()
