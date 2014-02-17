//
//  MBChatHeadWindow.h
//  MessageBox
//
//  Created by Adam Bell on 2014-02-05.
//  Copyright (c) 2014 Adam Bell. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface MBChatHeadWindow : UIWindow {

}

+ (instancetype)sharedInstance;

- (void)hide;
- (void)hideAnimated;
- (void)show;
- (void)showAnimated;

@end
