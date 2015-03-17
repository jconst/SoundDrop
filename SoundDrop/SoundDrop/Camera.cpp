//
//  Camera.cpp
//  SoundDrop
//
//  Created by Joseph Constantakis on 3/17/15.
//  Copyright (c) 2015 jconst. All rights reserved.
//

#include "Camera.h"

#include <opencv2/opencv.hpp>

int Camera::showCamera(){
    cv::VideoCapture capture(0); // open default camera
    if ( capture.isOpened() == false )
        return -1;
    cv::namedWindow("Test OpenCV",1);
    cv::Mat frame;
    while ( true )
    {
        capture >> frame;
        cv::imshow("Test OpenCV", frame );
        int key = cv::waitKey(1);
        if ( key == 27 )
            break;
    }
    return 0;
}