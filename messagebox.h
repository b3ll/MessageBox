#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#ifdef DEBUG
    #define DebugLog(str, ...) NSLog(str, ##__VA_ARGS__)
#else
    #define DebugLog(str, ...)
#endif

@interface UIWindow (hax)
- (void)setKeepContextInBackground:(BOOL)keepContext;
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

- (void)mb_addChatHeadWindow;
- (void)mb_removeChatHeadWindow;

- (void)setIsEditing:(BOOL)editing;
- (BOOL)isEditing;
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

@interface FBChatHeadSurfaceView : UIView
@property (nonatomic) BOOL hasComposer;

- (void)sortChatHeads;
@end

@interface FBChatHeadViewController : UIViewController
@property (nonatomic) BOOL hasInboxChatHead;

- (FBChatHeadSurfaceView *)chatHeadSurfaceView;
- (void)showComposerChatHead;
- (void)resignChatHeadViews;
@end

@interface FBMessengerModule : NSObject
- (FBChatHeadViewController *)chatHeadViewController;
@end

@interface FBApplicationController : NSObject
+ (instancetype)mb_sharedInstance;

- (FBMessengerModule *)messengerModule;
- (void)mb_setUIHiddenForMessageBox:(BOOL)hidden;
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

inline int PIDForProcessNamed(NSString *passedInProcessName) {
    // Thanks to http://stackoverflow.com/questions/6610705/how-to-get-process-id-in-iphone-or-ipad
    // Faster than ps,grep,etc

    int pid = 0;

    int mib[4] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
    size_t miblen = 4;

    size_t size;
    int st = sysctl(mib, miblen, NULL, &size, NULL, 0);

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
        st = sysctl(mib, miblen, process, &size, NULL, 0);

    } while (st == -1 && errno == ENOMEM);

    if (st == 0) {

        if (size % sizeof(struct kinfo_proc) == 0) {
            int nprocess = size / sizeof(struct kinfo_proc);

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
