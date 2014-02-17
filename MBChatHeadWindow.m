//
//  MBChatHeadWindow.m
//  MessageBox
//
//  Created by Adam Bell on 2014-02-05.
//  Copyright (c) 2014 Adam Bell. All rights reserved.
//

#import "MBChatHeadWindow.h"

#define USE_SPRINGS 1
#define CHAT_HEAD_TRANSITION_DELAY 0.5

@interface MBChatHeadWindow ()
@end

@implementation MBChatHeadWindow

- (instancetype)init {
    self = [self initWithFrame:[[UIScreen mainScreen] bounds]];
    if (self != nil){

    }

    return self;
}

+ (instancetype)sharedInstance {
    static dispatch_once_t p = 0;

    __strong static id _sharedSelf = nil;

    dispatch_once(&p, ^{
        _sharedSelf = [[self alloc] init];
    });

    return _sharedSelf;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    //forward touches to everything beneath this window, unless a touch falls upon something within this windows subviews

    if (![[super hitTest:point withEvent:event] isKindOfClass:[MBChatHeadWindow class]]) {
        return [super hitTest:point withEvent:event];
    }
    else {
        return nil;
    }
}

- (void)hide {
    self.hidden = YES;
}

- (void)show {
    self.hidden = NO;
}

- (void)hideAnimated {
    [self hide];

    [self.layer removeAllAnimations];

    CATransform3D scaleTransform = CATransform3DMakeScale(1.4, 1.0, 1.0);
    self.layer.transform = CATransform3DIdentity;

#ifdef USE_SPRINGS
    [UIView animateWithDuration:0.6
                          delay:0.0
         usingSpringWithDamping:0.8
          initialSpringVelocity:0.6
                        options:0
                     animations:^{
                            self.layer.transform = scaleTransform;
                        }
                     completion:nil];
#else
    [UIView animateWithDuration:0.4
                  delay:0.0
                options:0
             animations:^{
                    self.layer.transform = scaleTransform;
                }
             completion:nil];
#endif
}

- (void)showAnimated {
    [self show];

    [self.layer removeAllAnimations];

    CATransform3D scaleTransform = CATransform3DMakeScale(1.4, 1.0, 1.0);
    self.layer.transform = scaleTransform;

#ifdef USE_SPRINGS
    [UIView animateWithDuration:0.6
                          delay:CHAT_HEAD_TRANSITION_DELAY
         usingSpringWithDamping:0.8
          initialSpringVelocity:0.6
                        options:0
                     animations:^{
                            self.layer.transform = CATransform3DIdentity;
                        }
                     completion:nil];
#else
    [UIView animateWithDuration:0.4
                  delay:CHAT_HEAD_TRANSITION_DELAY
                options:0
             animations:^{
                    self.layer.transform = CATransform3DIdentity;
                }
             completion:nil];
#endif
}

@end
