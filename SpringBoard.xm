//
//  SpringBoard.xm
//  MessageBox
//
//  Created by Adam Bell on 2014-02-04.
//  Copyright (c) 2014 Adam Bell. All rights reserved.
//

#import "messagebox.h"
#import "MBChatHeadWindow.h"

/**
 * SpringBoard Hooks
 *
 */

static MBChatHeadWindow *_chatHeadWindow;
static BKSProcessAssertion *_keepAlive;

static __weak SBWindowContextHostWrapperView *_hostView;

static BOOL _chatHeadPopoverCanBeDismissed;

GROUP(SpringBoardHooks)

static void fbDidTapChatHead(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    SBIconController *iconController = [GET_CLASS(SBIconController) sharedInstance];
    
    //If icons are wiggling and a chat head is tapped, stop the wiggling
    if (iconController.isEditing)
        [iconController setIsEditing:NO];
}

static void fbLaunching(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [[GET_CLASS(SBUIController) sharedInstance] mb_removeChatHeadWindow];
}

static void fbQuitting(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    /*if ([(__bridge NSString*)name rangeOfString:@"paper"].location != NSNotFound)
        [[GET_CLASS(SBUIController) sharedInstance] mb_addChatHeadWindowForApp:@"Paper"];
    else
        [[GET_CLASS(SBUIController) sharedInstance] mb_addChatHeadWindowForApp:@"Facebook"];*/
}

HOOK(SBUIController)

//Stack up the chat heads when the home button is pressed

- (BOOL)clickedMenuButton {
    //To keep in app as stock as possible, don't intercept the home button when the app is active
    //So only take action if FB is active but in the background
    if ([_keepAlive valid] && _chatHeadPopoverCanBeDismissed) {
        notify_post("ca.adambell.messagebox.paperResignChatHeads");
        notify_post("ca.adambell.messagebox.fbResignChatHeads");
        return YES;
    }
    
    return ORIG_T();
}

- (BOOL)handleMenuDoubleTap {
    if ([_keepAlive valid]) {
        notify_post("ca.adambell.messagebox.paperResignChatHeads");
        notify_post("ca.adambell.messagebox.fbResignChatHeads");
    }
    
    return ORIG_T();
}

- (id)init {
    SBUIController *controller = ORIG();
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mb_screenOn:)
                                                 name:@"SBLockScreenUndimmedNotification"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mb_screenOff:)
                                                 name:@"SBLockScreenDimmedNotification"
                                               object:nil];
    
    CPDistributedMessagingCenter *sbMessagingCenter = [GET_CLASS(CPDistributedMessagingCenter) centerNamed:@"ca.adambell.MessageBox.sbMessagingCenter"];
    rocketbootstrap_distributedmessagingcenter_apply(sbMessagingCenter);
    [sbMessagingCenter runServerOnCurrentThread];
    [sbMessagingCenter registerForMessageName:@"messageboxOpenURL"
                                       target:self
                                     selector:@selector(mb_handleMessageBoxMessage:withUserInfo:)];
    [sbMessagingCenter registerForMessageName:@"messageboxUpdateChatHeadsState"
                                       target:self
                                     selector:@selector(mb_updateChatHeadsState:withUserInfo:)];
    
    return controller;
}

NEW()
- (void)mb_handleMessageBoxMessage:(NSString *)message withUserInfo:(NSDictionary *)userInfo {
    if ([message isEqualToString:@"messageboxOpenURL"]) {
        NSString *urlString = userInfo[@"url"];
        
        if (urlString != nil) {
            NSURL *url = [NSURL URLWithString:urlString];
            
            if (url != nil) {
                [[UIApplication sharedApplication] openURL:url];
            }
        }
    }
}

NEW()
- (void)mb_updateChatHeadsState:(NSString *)message withUserInfo:(NSDictionary *)userInfo {
    if ([message isEqualToString:@"messageboxUpdateChatHeadsState"]) {
        NSNumber *chatHeadsPopoverOpened = userInfo[@"opened"];
        
        if (chatHeadsPopoverOpened != nil) {
            _chatHeadPopoverCanBeDismissed = chatHeadsPopoverOpened.boolValue;
        }
    }
}

NEW()
- (void)mb_screenOn:(NSNotification *)notification {
    notify_post("ca.adambell.messagebox.fbForceActive");
    notify_post("ca.adambell.messagebox.paperForceActive");
}

NEW()
- (void)mb_screenOff:(NSNotification *)notification {
    notify_post("ca.adambell.messagebox.fbForceBackground");
    notify_post("ca.adambell.messagebox.paperForceBackground");
}

NEW()
- (void)mb_addChatHeadWindowForApp:(NSString *)appName {
    int facebookPID = PIDForProcessNamed(appName);
    if (facebookPID == 0)
        return;
    
    if (_keepAlive != nil)
        [_keepAlive invalidate];
    
    _keepAlive = [[GET_CLASS(BKSProcessAssertion) alloc] initWithPID:facebookPID
                                                               flags:(ProcessAssertionFlagPreventSuspend |
                                                                      ProcessAssertionFlagAllowIdleSleep |
                                                                      ProcessAssertionFlagPreventThrottleDownCPU |
                                                                      ProcessAssertionFlagWantsForegroundResourcePriority)
                                                              reason:kProcessAssertionReasonBackgroundUI
                                                                name:@"epichax"
                                                         withHandler:^void (void)
                  {
                      DebugLog(@"FACEBOOK PID: %d kept alive: %@", facebookPID, [_keepAlive valid] > 0 ? @"TRUE" : @"FALSE");
                  }];
    
    // Remove hosting if we try to add it again, don't want double hosted views!
    if (_hostView != nil) {
        SBWindowContextHostManager *manager = [_hostView valueForKey:@"_manager"];
        [manager disableHostingForRequester:@"hax"];
    }
    
    SBApplication *facebookApplication = [[GET_CLASS(SBApplicationController) sharedInstance] applicationWithDisplayIdentifier:[NSString stringWithFormat:@"com.facebook.%@", appName]];
    
    SBWindowContextHostManager *contextHostManager = [facebookApplication mainScreenContextHostManager];
    
    SBWindowContextHostWrapperView *facebookHostView = [contextHostManager hostViewForRequester:@"hax" enableAndOrderFront: YES];
    facebookHostView.backgroundColorWhileNotHosting = [UIColor clearColor];
    facebookHostView.backgroundColorWhileHosting = [UIColor clearColor];
    
    _hostView = facebookHostView;
    
    for (UIView *subview in facebookHostView.subviews) {
        subview.backgroundColor = [UIColor clearColor];
    }
    
    for (UIView *subview in [_chatHeadWindow.subviews copy]) {
        [subview removeFromSuperview];
    }
    
    [_chatHeadWindow addSubview:facebookHostView];
    
    // TODO: fix flicker when switching from Paper -> Hosted View
    [NSObject cancelPreviousPerformRequestsWithTarget:_chatHeadWindow
                                             selector:@selector(showAnimated)
                                               object:nil];
    [_chatHeadWindow performSelector:@selector(showAnimated)
                          withObject:nil
                          afterDelay:0.2];
}

NEW()
- (void)mb_removeChatHeadWindow {
    if (_keepAlive != nil) {
        // Kill the BKSProcessAssertion because it isn't needed anymore
        // Not sure if creating / removing it is necessary but I'd like to keep it as stock as possible when in app)
        
        [_keepAlive invalidate];
        _keepAlive = nil;
        
        // Remove Paper (if necessary)
        SBApplication *facebookApplication = [[GET_CLASS(SBApplicationController) sharedInstance] applicationWithDisplayIdentifier:@"com.facebook.Paper"];
        
        if (facebookApplication != nil) {
            SBWindowContextHostManager *contextHostManager = [facebookApplication mainScreenContextHostManager];
            [contextHostManager disableHostingForRequester:@"hax"];
        }
        
        // Remove Facebook (if necessary)
        facebookApplication = [[GET_CLASS(SBApplicationController) sharedInstance] applicationWithDisplayIdentifier:@"com.facebook.Facebook"];
        
        if (facebookApplication != nil) {
            SBWindowContextHostManager *contextHostManager = [facebookApplication mainScreenContextHostManager];
            [contextHostManager disableHostingForRequester:@"hax"];
        }
        
        for (UIView *subview in [[MBChatHeadWindow sharedInstance].subviews copy]) {
            [subview removeFromSuperview];
        }
    }
    
    [_chatHeadWindow hide];
}

END()

HOOK_AND_DECLARE(SBAppSliderController, NSObject)

- (void)switcherWillBeDismissed:(BOOL)arg1 {
    [[MBChatHeadWindow sharedInstance] showAnimated];
    ORIG();
}

- (void)switcherWasPresented:(BOOL)arg1 {
    notify_post("ca.adambell.messagebox.paperResignChatHeads");
    notify_post("ca.adambell.messagebox.fbResignChatHeads");
    [[MBChatHeadWindow sharedInstance] hideAnimated];
    ORIG();
}

END()

HOOK(UIWindow)

- (void)makeKeyAndVisible {
    ORIG();
    
    if (self != _chatHeadWindow) {
        if (_chatHeadWindow == nil) {
            _chatHeadWindow = [MBChatHeadWindow sharedInstance];
            _chatHeadWindow.backgroundColor = [UIColor clearColor];
        }
        
        _chatHeadWindow.windowLevel = 10; //1 below UIKeyboard //UIWindowLevelStatusBar;
        _chatHeadWindow.hidden = NO;
        _chatHeadWindow.backgroundColor = [UIColor clearColor];
    }
}

END()

HOOK_AND_DECLARE(SBWorkspace, NSObject)

- (void)workspace:(id)arg1 applicationSuspended:(NSString *)bundleIdentifier withSettings:(id)arg3 {
    if ([bundleIdentifier isEqualToString:@"com.facebook.Facebook"]) {
        [[GET_CLASS(SBUIController) sharedInstance] mb_addChatHeadWindowForApp:@"Facebook"];
    }
    
    if ([bundleIdentifier isEqualToString:@"com.facebook.Paper"]) {
        [[GET_CLASS(SBUIController) sharedInstance] mb_addChatHeadWindowForApp:@"Paper"];
    }
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    forceFacebookApplicationRotation(orientation);
    
    ORIG();
}

END()

END_GROUP()
