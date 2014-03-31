//
//  messagebox.h
//  MessageBox
//
//  Created by Adam Bell on 2014-02-04.
//  Copyright (c) 2014 Adam Bell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <notify.h>

#include <mach/mach.h>
#include <libkern/OSCacheControl.h>
#include <stdbool.h>
#include <dlfcn.h>
#include <sys/sysctl.h>

#import "substrate.h"
#import "rocketbootstrap.h"

#import <xctheos.h>

#ifdef DEBUG
    #define DebugLog(str, ...) NSLog(str, ##__VA_ARGS__)
#else
    #define DebugLog(str, ...)
#endif

@interface UIApplication (openURL)
- (void)applicationOpenURL:(NSURL *)url;
@end

@interface UIWindow (backgroundContext)
- (void)setKeepContextInBackground:(BOOL)keepContext;
- (void)_setRotatableViewOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration force:(BOOL)force;
@end

@interface UITextEffectsWindow : UIWindow
+ (UITextEffectsWindow *)preferredTextEffectsWindow;
+ (UITextEffectsWindow *)sharedTextEffectsWindow;

- (void)setKeepContextInBackground:(BOOL)keepContext;
@end

@interface UICalloutBar : UIView
@end

@interface CPDistributedMessagingCenter : NSObject
+ (CPDistributedMessagingCenter *)centerNamed:(NSString *)name;
- (void)runServerOnCurrentThread;
- (void)registerForMessageName:(NSString *)name target:(id)target selector:(SEL)selector;
- (void)sendMessageName:(NSString *)message userInfo:(NSDictionary *)userInfo;
- (NSDictionary *)sendMessageAndReceiveReplyName:(NSString *)reply userInfo:(NSDictionary *)dictionary;
@end

@interface SBWindowContextHostWrapperView : UIView
@property(nonatomic, strong) UIColor *backgroundColorWhileNotHosting;
@property(nonatomic, strong) UIColor *backgroundColorWhileHosting;
@end

@interface SBWindowContextHostManager : NSObject
- (SBWindowContextHostWrapperView *)hostViewForRequester:(NSString *)requester enableAndOrderFront:(BOOL)enableAndOrderFront;
- (void)disableHostingForRequester:(NSString *)requester;
@end

@interface SBApplication : NSObject
- (SBWindowContextHostManager *)mainScreenContextHostManager;
@end

@interface SBApplicationController : NSObject
+ (instancetype)sharedInstance;
- (SBApplication *)applicationWithDisplayIdentifier:(NSString *)identifier;
@end

@interface SBIconController : NSObject
+ (instancetype)sharedInstance;

- (void)setIsEditing:(BOOL)editing;
- (BOOL)isEditing;
@end

@interface SBUIController : NSObject
+ (instancetype)sharedInstance;

- (void)mb_addChatHeadWindowForApp:(NSString *)appName;
- (void)mb_removeChatHeadWindow;
@end

@interface BKProcessAssertion : NSObject
- (instancetype)initWithReason:(unsigned int)arg1 identifier:(id)arg2;
- (void)setWantsForegroundResourcePriority:(BOOL)arg1;
- (void)setPreventThrottleDownCPU:(BOOL)arg1;
- (void)setPreventThrottleDownUI:(BOOL)arg1;
- (void)setPreventSuspend:(BOOL)arg1;
- (void)setAllowIdleSleepOverrideEnabled:(BOOL)arg1;
- (void)setPreventIdleSleep:(BOOL)arg1;
- (void)setFlags:(unsigned int)arg1;
- (void)invalidate;
@end

@interface BKSProcessAssertion : NSObject
+ (instancetype)NameForReason:(unsigned int)arg1;
- (void)queue_notifyAssertionAcquired:(BOOL)arg1;
- (void)queue_updateAssertion;
- (void)queue_acquireAssertion;
- (void)queue_registerWithServer;
- (void)queue_invalidate:(BOOL)arg1;
- (void)invalidate;
- (void)setReason:(unsigned int)arg1;
- (void)setValid:(BOOL)arg1;
- (void)setFlags:(unsigned int)arg1;
- (int)valid;
- (instancetype)initWithPID:(int)arg1 flags:(unsigned int)arg2 reason:(unsigned int)arg3 name:(id)arg4 withHandler:(id)arg5;
- (instancetype)initWithBundleIdentifier:(id)arg1 flags:(unsigned int)arg2 reason:(unsigned int)arg3 name:(id)arg4 withHandler:(id)arg5;
- (instancetype)init;
@end

typedef NS_ENUM(NSUInteger, BKSProcessAssertionReason)
{
    kProcessAssertionReasonAudio = 1,
    kProcessAssertionReasonLocation,
    kProcessAssertionReasonExternalAccessory,
    kProcessAssertionReasonFinishTask,
    kProcessAssertionReasonBluetooth,
    kProcessAssertionReasonNetworkAuthentication,
    kProcessAssertionReasonBackgroundUI,
    kProcessAssertionReasonInterAppAudioStreaming,
    kProcessAssertionReasonViewServices
};

typedef NS_ENUM(NSUInteger, ProcessAssertionFlags)
{
    ProcessAssertionFlagNone = 0,
    ProcessAssertionFlagPreventSuspend         = 1 << 0,
    ProcessAssertionFlagPreventThrottleDownCPU = 1 << 1,
    ProcessAssertionFlagAllowIdleSleep         = 1 << 2,
    ProcessAssertionFlagWantsForegroundResourcePriority  = 1 << 3
};

@interface FBChatHeadLayout : NSObject
@end

@interface FBChatHeadSurfaceView : UIView
@property (nonatomic) BOOL hasComposer;
@property(nonatomic) FBChatHeadLayout *currentLayout;

@property(nonatomic, strong) FBChatHeadLayout *defaultLayout;
@property(nonatomic, strong) FBChatHeadLayout *closedLayout;
@property(nonatomic, strong) FBChatHeadLayout *openedLayout;

- (void)sortChatHeads;
- (void)updateChatHeadsPosition;
@end

@interface FBChatHeadViewController : UIViewController
@property (nonatomic) BOOL hasInboxChatHead;

- (FBChatHeadSurfaceView *)chatHeadSurfaceView;
- (void)showComposerChatHead;
- (void)resignChatHeadViews;
@end

@interface FBMessengerModuleSession : NSObject
- (void)enteredForeground;
@end

@interface FBMessengerModule : NSObject
- (FBChatHeadViewController *)chatHeadViewController;
@property (nonatomic, strong) FBMessengerModuleSession *moduleSession;
@end

@interface FBApplicationController : NSObject
+ (instancetype)mb_sharedInstance;

- (FBMessengerModule *)messengerModule;

- (void)mb_setUIHiddenForMessageBox:(BOOL)hidden;
- (void)mb_openURL:(NSURL *)url;
@end

@interface FBStackView : UIView
@end

@interface FBMInboxView : UIView
@property(nonatomic) BOOL showPublisherBar;

- (BOOL)mb_shouldShowPublisherBar;
@end

@interface FBMInboxViewController : UIViewController

@property(nonatomic, strong) FBMInboxView *inboxView;
@end

@interface AppDelegate : NSObject
- (void)mb_setUIHiddenForMessageBox:(BOOL)hidden;
- (void)mb_openURL:(NSURL *)url;
- (void)mb_forceRotationToInterfaceOrientation:(UIInterfaceOrientation)orientation;
@end

inline int PIDForProcessNamed(NSString *passedInProcessName) {
    // Thanks to http://stackoverflow.com/questions/6610705/how-to-get-process-id-in-iphone-or-ipad
    // Faster than ps,grep,etc

    int pid = 0;

    int mib[4] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
    size_t miblen = 4;

    size_t size;
    int st = sysctl(mib, (u_int)miblen, NULL, &size, NULL, 0);

    struct kinfo_proc * process = NULL;
    struct kinfo_proc * newprocess = NULL;

    do {

        size += size / 10;
        newprocess = (kinfo_proc *)realloc(process, size);

        if (!newprocess) {
            if (process) {
                free(process);
            }
            return 0;
        }

        process = newprocess;
        st = sysctl(mib, (u_int)miblen, process, &size, NULL, 0);

    } while (st == -1 && errno == ENOMEM);

    if (st == 0) {

        if (size % sizeof(struct kinfo_proc) == 0) {
            int nprocess = (int)(size / sizeof(struct kinfo_proc));

            if (nprocess) {
                for (int i = nprocess - 1; i >= 0; i--) {
                    NSString * processName = [[NSString alloc] initWithFormat:@"%s", process[i].kp_proc.p_comm];

                    if ([processName rangeOfString:passedInProcessName].location != NSNotFound) {
                        pid = process[i].kp_proc.p_pid;
                    }
                }

                free(process);
            }
        }
    }
    if (pid == 0) {
        DebugLog(@"GET PROCESS %@ FAILED.", [passedInProcessName uppercaseString]);
    }

    return pid;
}
