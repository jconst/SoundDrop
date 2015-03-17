//
//  OCCamera.m
//  SoundDrop
//
//  Created by Joseph Constantakis on 3/17/15.
//  Copyright (c) 2015 jconst. All rights reserved.
//

#import "OCCamera.h"
#import "Camera.h"

@implementation OCCamera
+ (void) showCam
{
    Camera::showCamera();
}
@end