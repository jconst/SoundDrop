//Sulaiman

#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include "opencv2/imgproc/imgproc.hpp"
#include <iostream>
#include <algorithm>
#include <functional>

using namespace cv;
using namespace std;
#define PI 3.14159265

//----------------------------------    Global variables

Mat curFrame, lastFrame, curGray, diff, threshed, blurred;
int c1 = 0, c2=1;
int numLights = 1;
int minArea = 10;
int maxArea = 1000;
vector<Point2f> lightPoints(numLights, Point2f(0,0));


int main(int argc, char **argv)
{
    cout.precision(3);
    cvNamedWindow( "Original", CV_WINDOW_AUTOSIZE);
    moveWindow("Original", 20,200);

//------------------------------    This default setting is for red color and variables
    int iLowH = 164;
    int iHighH = 179;
    int iLowS = 88; 
    int iHighS = 255;
    int iLowV = 116;
    int iHighV = 255;

    vector< vector<Point> > contours;
    vector< Vec4i > hierarchy;
    
//----------------------------------    Read an image and check for invalid input
    int imgHeight = 480, //Default 480
         imgWidth = 640; //Default 640
    CvSize imgSize = cvSize(imgWidth,imgHeight); // The size of the image used. Default capture size - 640x480.

    VideoCapture p_capwebcam(0); //capture the video from default webcam and check it
    if ( !p_capwebcam.isOpened() ){
        cout << "Cannot open the Web Cam" << endl;
        return -1;
    }

    Mat firstFrame;
    p_capwebcam.read(firstFrame);
    cvtColor(firstFrame, lastFrame, COLOR_BGR2GRAY);

//----------------------------------    Start Looping
    while (true) {
        //Grab image frame
        bool bSuccess = p_capwebcam.read(curFrame); // read a new frame from video
        if (!bSuccess) { //if not success, break loop
            cout << "Cannot read a frame from video stream" << endl;
            getchar(); 
            break;
        }
//----------------------------------    Image pre-processing and then display

        cvtColor(curFrame, curGray, COLOR_BGR2GRAY);
        absdiff(lastFrame, curGray, diff);

        GaussianBlur(diff, blurred, Size(21,21), 1.5, 1.5);

        inRange(blurred, Scalar(200), Scalar(255), threshed); 

        // //morphological opening (removes small objects from the foreground)
        // erode(threshed, threshed, getStructuringElement(MORPH_ELLIPSE, Size(5, 5)) );
        // dilate(threshed, threshed, getStructuringElement(MORPH_ELLIPSE, Size(5, 5)) ); 

        // //morphological closing (removes small holes from the foreground)
        // dilate(threshed, threshed, getStructuringElement(MORPH_ELLIPSE, Size(10,10)) ); 
        // erode(threshed, threshed, getStructuringElement(MORPH_ELLIPSE, Size(10,10)) );
        

//-------------------------     Image Processing
    
        //Find Contours
        findContours(threshed, contours, hierarchy, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE, Point(0,0));
        // cout << "# " << contours.size();

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
            Moments mts = moments(contours[i]);
            lightPoints[i] = Point2f(mts.m10/mts.m00, mts.m01/mts.m00);
            cout << i << "th biggest contour at x:" << lightPoints[i].x
                 << " y:" << lightPoints[i].y << " has area " 
                 << contourArea(contours[i]) << endl;
        }

        for (auto i = lightPoints.begin(); i != lightPoints.end(); ++i) {
            circle(curFrame, *i, 15, Scalar(0, 0, 255), -1);
        }
        imshow("Original",curFrame);

        if (waitKey(30) == 27) {
            cout << "ESC key is pressed by user" << endl;
            break;
        }

        lastFrame = curGray.clone();
    }
}
