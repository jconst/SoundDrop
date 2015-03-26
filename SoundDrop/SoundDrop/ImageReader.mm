//
//  ImageReader.m
//  SoundDrop
//
//  Created by Joseph Constantakis on 3/19/15.
//  Copyright (c) 2015 jconst. All rights reserved.
//

#import "ImageReader.h"
#import "OpenCVImageReader.h"

#include <opencv2/core/core.hpp>

using namespace cv;
using namespace std;

//-- Objective-C Class Implementation

@implementation ImageReader

- (NSArray *)flashesInImage:(UIImage *)image
{
    Mat mat = cvMatFromUIImage(image);
    vector<Point2f> points = flashesInImage(mat);
    NSMutableArray *ret = [NSMutableArray new];
    for (Point2f pt : points) {
        [ret addObject:[NSValue valueWithCGPoint:cgPointFromPoint2f(pt)]];
    }
    return ret;
}

@end
