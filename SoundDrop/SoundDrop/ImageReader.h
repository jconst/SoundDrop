//
//  ImageReader.h
//  SoundDrop
//
//  Created by Joseph Constantakis on 3/19/15.
//  Copyright (c) 2015 jconst. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


typedef struct {
    CGPoint start;
    CGPoint end;
} Line;

@interface ImageReader : NSObject

- (Line)lineInImage:(UIImage *)image;

@end
