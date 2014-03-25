#import <Preferences/Preferences.h>
#import <UIKit/UIKit.h>

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

    BOOL enabled = [prefs[@"messageBoxEnabled"] boolValue];
    BOOL previouslyEnabled = [_prefs[@"messageBoxEnabled"] boolValue];

    if (enabled != previouslyEnabled) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"MessageBox"
                                                            message:@"Changing this option requires you to restart SpringBoard."
                                                           delegate:_weakSelf
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"Respring", nil];
        [alertView show];
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

- (void)toggleEnabled:(id)sender {
    NSLog(@"THIS IS A MESSAGE HEY%@", sender);
}

@end

// vim:ft=objc
