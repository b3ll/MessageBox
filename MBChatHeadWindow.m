//
//  MBChatHeadWindow.m
//  MessageBox
//
//  Created by Adam Bell on 2014-02-05.
//  Copyright (c) 2014 Adam Bell. All rights reserved.
//

#import "MBChatHeadWindow.h"


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

@end
