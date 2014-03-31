//
//  Facebook.xm
//  MessageBox
//
//  Created by Adam Bell on 2014-03-29.
//  Copyright (c) 2014 Adam Bell. All rights reserved.
//

#import "messagebox.h"
#import "MBChatHeadWindow.h"

static BOOL _ignoreBackgroundedNotifications_facebook = YES;

static BOOL _UIHiddenForMessageBox_facebook;

static __weak FBMessengerModule *_messengerModule;

GROUP(FacebookHooks)

// Keyboards also need to be shown when the app is backgrounded
HOOK(UITextEffectsWindow)

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

- (CGFloat)windowLevel {
    return KEYBOARD_WINDOW_LEVEL;
}

- (void)setWindowLevel:(CGFloat)windowLevel {
    ORIG(KEYBOARD_WINDOW_LEVEL);
}

END()

static void fbResignChatHeads(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [_messengerModule.chatHeadViewController resignChatHeadViews];
    [[UIApplication sharedApplication].keyWindow endEditing:YES];
}

static void fbForceActive(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    _ignoreBackgroundedNotifications_facebook = YES;
    [_messengerModule.moduleSession enteredForeground];
}

static void fbForceBackgrounded(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    _ignoreBackgroundedNotifications_facebook = NO;
    
    [[[UIApplication sharedApplication] delegate] applicationDidEnterBackground:[UIApplication sharedApplication]];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil userInfo:nil];
}

static void fbShouldRotate(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    UIInterfaceOrientation newOrientation = UIInterfaceOrientationPortrait;
    
    DebugLog(@"FACEBOOK SHOULD ACTUALLY ROTATE");
    
    if ([(__bridge NSString *)name isEqualToString:@ROTATION_PORTRAIT_UPSIDEDOWN_NOTIFICATION]) {
        newOrientation = UIInterfaceOrientationPortraitUpsideDown;
    }
    else if ([(__bridge NSString *)name isEqualToString:@ROTATION_LANDSCAPE_LEFT_NOTIFICATION]) {
        newOrientation = UIInterfaceOrientationLandscapeLeft;
    }
    else if ([(__bridge NSString *)name isEqualToString:@ROTATION_LANDSCAPE_RIGHT_NOTIFICATION]){
        newOrientation = UIInterfaceOrientationLandscapeRight;
    }
    
    [(AppDelegate *)[UIApplication sharedApplication].delegate mb_forceRotationToInterfaceOrientation:newOrientation];
}


HOOK(UIApplication)

- (UIApplicationState)applicationState {
    if (_ignoreBackgroundedNotifications_facebook) {
        return UIApplicationStateActive;
    }
    else {
        return (UIApplicationState)ORIG_T();
    }
}

END()

// Need to force the app to believe it's still active... no notifications for you! >:D
HOOK(NSNotificationCenter)

- (void)postNotificationName:(NSString *)notificationName object:(id)notificationSender userInfo:(NSDictionary *)userInfo {
    NSString *notification = [notificationName lowercaseString];
    if ([notification rangeOfString:@"background"].location != NSNotFound && _ignoreBackgroundedNotifications_facebook) {
        notify_post("ca.adambell.messagebox.fbQuitting");
        
        [[UIApplication sharedApplication].keyWindow endEditing:YES];
        
        [(AppDelegate *)[UIApplication sharedApplication].delegate mb_setUIHiddenForMessageBox:YES];
        
        return;
    }
    
    DebugLog(@"Notification Posted: %@ object: %@ userInfo: %@", notificationName, notificationSender, userInfo);
    
    ORIG();
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
    notify_post("ca.adambell.messagebox.fbLaunching");
    DebugLog(@"FACEBOOK OPENING RIGHT NOW");
    
    [self mb_setUIHiddenForMessageBox:NO];
    
    ORIG();
}

NEW()
- (void)mb_setUIHiddenForMessageBox:(BOOL)hidden {
    _UIHiddenForMessageBox_facebook = hidden;
    
    [[UIApplication sharedApplication].keyWindow setKeepContextInBackground:hidden];
    
    [UIApplication sharedApplication].keyWindow.backgroundColor = hidden ? [UIColor clearColor] : [UIColor blackColor];
    
    FBChatHeadViewController *chatHeadController = _messengerModule.chatHeadViewController;
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
        if (view != chatHeadContainerView && ![view isKindOfClass:GET_CLASS(FBDimmingView)]) {
            view.hidden = hidden;
        }
    }
    
    chatHeadContainerView.backgroundColor = [UIColor clearColor];
    
    UIView *topBarView = chatHeadContainerView.superview;
    while (![topBarView isKindOfClass:GET_CLASS(FBTopBarAndContentView)]) {
        if (topBarView.superview == nil)
            break;
        
        topBarView = topBarView.superview;
    }
    
    topBarView.backgroundColor = [UIColor clearColor];
}

NEW()
- (void)mb_openURL:(NSURL *)url {
    CPDistributedMessagingCenter *sbMessagingCenter = [GET_CLASS(CPDistributedMessagingCenter) centerNamed:@"ca.adambell.MessageBox.sbMessagingCenter"];
    rocketbootstrap_distributedmessagingcenter_apply(sbMessagingCenter);
    
    [sbMessagingCenter sendMessageName:@"messageboxOpenURL" userInfo:@{ @"url" : [url absoluteString] }];
    
    FBChatHeadViewController *chatHeadController = _messengerModule.chatHeadViewController;
    [chatHeadController resignChatHeadViews];
}

NEW()
- (void)mb_forceRotationToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    DebugLog(@"NEXT ORIENTATION: %d", (int)orientation);
    
    // Popover blows up when rotated
    FBChatHeadViewController *chatHeadController = _messengerModule.chatHeadViewController;
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
    
    [_messengerModule.chatHeadViewController.chatHeadSurfaceView performSelector:@selector(updateChatHeadsPosition)
                                                                      withObject:nil
                                                                      afterDelay:0.25f];
}

END()

HOOK(MessagesViewController)

- (void)messageCell:(id)arg1 didSelectURL:(NSURL *)url {
    if (_UIHiddenForMessageBox_facebook && [url isKindOfClass:[NSURL class]] && url != nil) {
        [(AppDelegate *)[UIApplication sharedApplication].delegate mb_openURL:url];
    }
    else {
        ORIG();
    }
}

END()

HOOK(FBChatHeadSurfaceView)

- (void)setCurrentLayout:(FBChatHeadLayout *)currentLayout {
    CPDistributedMessagingCenter *sbMessagingCenter = [GET_CLASS(CPDistributedMessagingCenter) centerNamed:@"ca.adambell.MessageBox.sbMessagingCenter"];
    rocketbootstrap_distributedmessagingcenter_apply(sbMessagingCenter);
    [sbMessagingCenter sendMessageName:@"messageboxUpdateChatHeadsState" userInfo:@{ @"opened" : @(currentLayout == self.openedLayout) }];
    
    ORIG();
}

END()

HOOK(FBMessengerModule)

// MOTHER OF METHOD
// Totally not retyping this stupid thing with proper arguments :P
- (id)initWithSession:(id)arg1 messengerModuleSessionProvider:(id)arg2 threadViewControllerProvider:(id)arg3 threadUserMapProvider:(id)arg4 jewelThreadListControllerProvider:(id)arg5 immersiveJewelThreadListControllerProvider:(id)arg6 threadSetProvider:(id)arg7 userSetProvider:(id)arg8 presenceNotificationManagerProvider:(id)arg9 authManagerProvider:(id)arg10 projectGatingChecker:(id)arg11 urlHandlerControllerProvider:(id)arg12 interstitialControllerProvider:(id)arg13 {
    id orig = ORIG();
    _messengerModule = orig;
    return orig;
}

END()


END_GROUP()
