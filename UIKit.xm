//
//  UIKit.xm
//  MessageBox
//
//  Created by Adam Bell on 2014-03-31.
//  Copyright (c) 2014 Adam Bell. All rights reserved.
//

#import "messagebox.h"

GROUP(UIKitHooks)

static void forceFacebookApplicationRotation(UIInterfaceOrientation orientation) {
    switch (orientation){
        case UIInterfaceOrientationPortrait:
            notify_post(ROTATION_PORTRAIT_NOTIFICATION);
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            notify_post(ROTATION_PORTRAIT_UPSIDEDOWN_NOTIFICATION);
            break;
        case UIInterfaceOrientationLandscapeLeft:
            notify_post(ROTATION_LANDSCAPE_LEFT_NOTIFICATION);
            break;
        case UIInterfaceOrientationLandscapeRight:
            notify_post(ROTATION_LANDSCAPE_RIGHT_NOTIFICATION);
            break;
        default:
            notify_post(ROTATION_PORTRAIT_NOTIFICATION);
            break;
    }
}

HOOK(UIViewController)

- (void)_willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration forwardToChildControllers:(BOOL)forwardToChildControllers skipSelf:(BOOL)skipSelf {    
    ORIG();
    
    forceFacebookApplicationRotation(orientation);
}

END()

END_GROUP()
