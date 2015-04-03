//
//  ImageReader.m
//  SoundDrop
//
//  Created by Joseph Constantakis on 3/19/15.
//  Copyright (c) 2015 jconst. All rights reserved.
//

#import "ImageReader.h"
#import "OpenCVImageReader.h"

@implementation ImageReader

- (NSArray *)flashesInImage:(UIImage *)image
{
    return flashPointsInImage(image);
}

@end
