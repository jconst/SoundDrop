//
//  OpenCVImageReader.h
//  SoundDrop
//
//  Created by Joseph Constantakis on 3/19/15.
//  Copyright (c) 2015 jconst. All rights reserved.
//

#ifndef __SoundDrop__OpenCVImageReader__
#define __SoundDrop__OpenCVImageReader__

#include <iostream>
#include <opencv2/core/core.hpp>

using namespace cv;
using namespace std;

// "Public" interface
vector<Point2f> flashesInImage(Mat &img);
// --

void diffImages(Mat &cur, Mat &last, Mat &dest);

#endif
