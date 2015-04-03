//
//  OpenCVImageReader.cpp
//  SoundDrop
//
//  Created by Joseph Constantakis on 3/19/15.
//  Copyright (c) 2015 jconst. All rights reserved.
//

#include "OpenCVImageReader.h"

//Sulaiman

#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include "opencv2/imgproc/imgproc.hpp"
#include <iostream>
#include <algorithm>
#include <functional>

using namespace cv;
using namespace std;

Mat curFrame, lastFrame, curGray, diff, threshed, blurred;

int numLights = 5; //return the 5 largest objects
int minArea = 1;
int maxArea = 1000;

vector< vector<cv::Point> > contours;
vector<Point2f> lightPoints(numLights, Point2f(0,0));
vector<Vec4i> hierarchy;


//-- C++ helper functions

CGPoint cgPointFromPoint2f(Point2f pt)
{
    //TODO: dont use hardcoded mapping
    CGPoint point = CGPointMake(pt.x/144.0, 1.0-(pt.y/192.0));
    return point;
}

Mat cvMatFromUIImage(UIImage *image)
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

UIImage *uiImageFromCVMat(Mat cvMat)
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

NSArray *flashPointsInImage(UIImage *image)
{
    Mat mat = cvMatFromUIImage(image);
    vector<Point2f> points = flashPointsInImage(mat);
    NSMutableArray *ret = [NSMutableArray new];
    for (Point2f pt : points) {
        [ret addObject:[NSValue valueWithCGPoint:cgPointFromPoint2f(pt)]];
    }
    return ret;
}

vector<Point2f> flashPointsInImage(Mat &curFrame)
{
    if (lastFrame.empty()) {
        cvtColor(curFrame, curGray, COLOR_BGR2GRAY);
        lastFrame = curGray.clone();
        return vector<Point2f>();
    }
    
    diffImages(curFrame, lastFrame, threshed);
    
    //Find Contours
    findContours(threshed, contours, hierarchy, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE, cv::Point(0,0));
    
    //Identify the biggest n contours
    sort(contours.begin(), contours.end(),
         [](const vector<cv::Point> &c1, const vector<cv::Point> &c2) -> bool {
             return contourArea(c1) > contourArea(c2);
         });
    remove_if(contours.begin(), contours.end(),
              [](const vector<cv::Point> &c) -> bool {
                  int area = contourArea(c);
                  return area < minArea || area > maxArea;
              });
    int numFound = min((int)contours.size(), numLights);
    for (int i=0; i < numFound; ++i) {
        if (contours[i].size() == 0)
            continue;
        Moments mts = moments(contours[i]);
        if (mts.m00 == 0)
            continue;
        lightPoints[i] = Point2f(mts.m10/mts.m00, mts.m01/mts.m00);
        if (i == 0)
            NSLog(@"biggest contour: %@", NSStringFromCGPoint(cgPointFromPoint2f(lightPoints[i])));
    }
    
    lastFrame = curGray.clone();
    return vector<Point2f>(&lightPoints[0], &lightPoints[contours.size()]);
}

void diffImages(Mat &cur, Mat &last, Mat &dest)
{
    cvtColor(cur, curGray, COLOR_BGR2GRAY);
    absdiff(last, curGray, diff);
    
    GaussianBlur(diff, blurred, cv::Size(3,3), 0, 0);
    
    inRange(blurred, Scalar(175), Scalar(255), dest);
}
