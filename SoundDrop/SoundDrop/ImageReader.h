//
//  ImageReader.h
//  SoundDrop
//
//  Created by Joseph Constantakis on 3/19/15.
//  Copyright (c) 2015 jconst. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ImageReader : NSObject

/// @return NSArray of CGPoints wrapped in NSValues
- (NSArray *)flashesInImage:(UIImage *)image;

@end
