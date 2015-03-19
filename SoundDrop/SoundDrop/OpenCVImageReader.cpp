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

using namespace cv;
using namespace std;
#define PI 3.14159265

Mat imgConvert, imgProcessed, imgThresholded;
int c1 = 0, c2=1;       // c1 = Center Point of Big Circle and c2 = Center Point of Small Circle

//Default is red colored circles, will change later
int iLowH = 50;
int iHighH = 255;
int iLowS = 50;
int iHighS = 255;
int iLowV = 50;
int iHighV = 255;

vector<Point2f> lineInImage(Mat &imgOriginal)
{
    vector< vector<Point> > contours;
    vector< Vec4i > hierarchy;
    
    //-- Image pre-processing
    preprocessImage(imgOriginal, imgProcessed);
    
    //-- Image Processing
    
    //Find Contours
    findContours(imgProcessed, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE, Point(0,0));
    cout << "# " << contours.size();
    
    if (contours.size() != 2) {
        cout << " No mark detected." << endl;
        return vector<Point2f>();
    }
    //Identify the biggest circle
    if (contourArea(contours[0]) < contourArea(contours[1])) {
        c1 = 1;
        c2 = 0;
    } else {
        c1 = 0;
        c2 = 1;
    }
    
    vector<Moments> mu(contours.size() );       /// Get the moments
    for( int i = 0; i < contours.size(); i++ ) {
        mu[i] = moments( contours[i], false );
    }
    
    vector<Point2f> mc( contours.size() );      ///  Get the mass centers
    for( int i = 0; i < contours.size(); i++) {
        mc[i] = Point2f( mu[i].m10/mu[i].m00 , mu[i].m01/mu[i].m00 );
    }
    
    return mc;
    
    // Could also return an angle:
    
    //float angle = (atan2(mc[c2].y - mc[c1].y, mc[c2].x - mc[c1].x))*180/PI; //Determine the angle from horizontal line
    //if (mc[c2].y - mc[c1].y >= 0)
    //    cout << " ,* " << 360 - angle << endl;
    //else
    //    cout << " , " << angle*(-1) << endl;
}

void preprocessImage(Mat &imgOriginal, Mat &imgProc)
{
    //Convert the captured frame from BGR to HSV
    cvtColor(imgOriginal, imgConvert, COLOR_BGR2HSV);
    GaussianBlur(imgConvert,imgThresholded, Size(3,3), 1.5, 1.5);


    //Checks if array elements lie between the elements of two other arrays.
    inRange(imgThresholded, Scalar(iLowH, iLowS, iLowV), Scalar(iHighH, iHighS, iHighV), imgProc);

    //morphological opening (removes small objects from the foreground)
    erode(imgProc, imgProc, getStructuringElement(MORPH_ELLIPSE, Size(5, 5)) );
    dilate(imgProc, imgProc, getStructuringElement(MORPH_ELLIPSE, Size(5, 5)) );
    
    //morphological closing (removes small holes from the foreground)
    dilate(imgProc, imgProc, getStructuringElement(MORPH_ELLIPSE, Size(10,10)) );
    erode(imgProc, imgProc, getStructuringElement(MORPH_ELLIPSE, Size(10,10)) );
}
