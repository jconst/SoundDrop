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

int numLights = 1;
int minArea = 10;
int maxArea = 1000;

vector< vector<Point> > contours;
vector<Point2f> lightPoints(numLights, Point2f(0,0));
vector<Vec4i> hierarchy;

vector<Point2f> flashesInImage(Mat &curFrame)
{
    if (lastFrame.empty()) {
        lastFrame = curFrame.clone();
        return vector<Point2f>();
    }
    
    diffImages(curFrame, lastFrame, diff);
    
    //Find Contours
    findContours(threshed, contours, hierarchy, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE, Point(0,0));
    
    //Identify the biggest n contours
    sort(contours.begin(), contours.end(),
         [](const vector<Point> &c1, const vector<Point> &c2) -> bool {
             return contourArea(c1) > contourArea(c2);
         });
    remove_if(contours.begin(), contours.end(),
              [](const vector<Point> &c) -> bool {
                  int area = contourArea(c);
                  return area < minArea || area > maxArea;
              });
    int numFound = min((int)contours.size(), numLights);
    for (int i=0; i < numFound; ++i) {
        if (contours[i].size() == 0)
            continue;
        Moments mts = moments(contours[i]);
        lightPoints[i] = Point2f(mts.m10/mts.m00, mts.m01/mts.m00);
        cout << i << "th biggest contour at x:" << lightPoints[i].x
             << " y:" << lightPoints[i].y << " has area "
             << contourArea(contours[i]) << endl;
    }
    
    lastFrame = curGray.clone();
    return lightPoints;
}

void diffImages(Mat &cur, Mat &last, Mat &dest)
{
    cvtColor(cur, curGray, COLOR_BGR2GRAY);
    absdiff(last, curGray, diff);
    
    GaussianBlur(diff, blurred, Size(31,31), 0, 0);
    
    inRange(blurred, Scalar(210), Scalar(255), threshed);
}
