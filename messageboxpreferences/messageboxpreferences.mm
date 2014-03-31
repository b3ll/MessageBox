#import <Preferences/Preferences.h>
#import <UIKit/UIKit.h>

#define KEY_ENABLED @"messageBoxEnabled"
#define KEY_FORCE_ENABLED @"messageBoxForceEnabled"
#define KEY_USE_PAPER @"messageBoxPaperEnabled"
#define KEY_USE_FACEBOOK @"messageBoxFacebookEnabled"

@interface messageboxpreferencesListController: PSListController <UIAlertViewDelegate> {
}
@end

@implementation messageboxpreferencesListController

NSDictionary *_prefs;
__weak messageboxpreferencesListController *_weakSelf;

- (id)init {
    self = [super init];
    _weakSelf = self;

    // stupid switch setup
    CFNotificationCenterRef darwin = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterAddObserver(darwin, NULL, messageBoxPrefsChanged, CFSTR("ca.adambell.messagebox.preferences-changed"), NULL, CFNotificationSuspensionBehaviorCoalesce);

    _prefs = [[NSDictionary alloc] initWithContentsOfFile:@"/User/Library/Preferences/ca.adambell.messagebox.plist"];

    return self;
}

// dirty hack but apparently the confirmation dict doesn't work anymore :(
static void messageBoxPrefsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:@"/User/Library/Preferences/ca.adambell.messagebox.plist"];

    BOOL enabled = [prefs[KEY_ENABLED] boolValue];
    BOOL previouslyEnabled = [_prefs[KEY_ENABLED] boolValue];

    BOOL forceEnabled = [prefs[KEY_FORCE_ENABLED] boolValue];
    BOOL previouslyForceEnabled = [prefs[KEY_FORCE_ENABLED] boolValue];

    if ((enabled != previouslyEnabled) || (forceEnabled != previouslyForceEnabled)) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"MessageBox"
                                                            message:@"Changing this option requires you to restart SpringBoard."
                                                           delegate:_weakSelf
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"Respring", nil];
        [alertView show];
    }

    BOOL paperEnabled = [prefs[KEY_USE_PAPER] boolValue];
    BOOL paperPreviouslyEnabled = [_prefs[KEY_USE_PAPER] boolValue];

    if (paperEnabled != paperPreviouslyEnabled) {
        system("killall Paper");
    }

    BOOL facebookEnabled = [prefs[KEY_USE_FACEBOOK] boolValue];
    BOOL facebookPreviouslyEnabled = [_prefs[KEY_USE_FACEBOOK] boolValue];

    if (facebookEnabled != facebookPreviouslyEnabled) {
        system("killall Facebook");
    }

    _prefs = [[NSDictionary alloc] initWithContentsOfFile:@"/User/Library/Preferences/ca.adambell.messagebox.plist"];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.firstOtherButtonIndex) {
        // respring
        system("killall backboardd");
    }
}

- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"messageboxpreferences" target:self] retain];
	}
	return _specifiers;
}

@end

// vim:ft=objc
