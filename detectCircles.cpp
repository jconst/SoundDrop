//Sulaiman

#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include "opencv2/imgproc/imgproc.hpp"
#include <iostream>

using namespace cv;
using namespace std;
#define PI 3.14159265

//----------------------------------    Global variables

Mat imgOriginal, imgConvert, imgProcessed, imgThresholded, imgDrawing;
//RNG rng(12345);
int c1 = 0, c2=1;       // c1 = Center Point of Big Circle and c2 = Center Point of Small Circle
//double aAreaBig = 0;  //


int main( int argc, char **argv )
{
    cout.precision(3);
//----------------------------------    Declare  Windows and Initial Positions
    namedWindow("HSV Control", CV_WINDOW_AUTOSIZE); //Create a window called "HSV Control" with autosize = 1
    cvNamedWindow( "Original", CV_WINDOW_AUTOSIZE);
    //cvNamedWindow( "Processed", CV_WINDOW_AUTOSIZE );
    moveWindow("HSV Control", 800,20);
    moveWindow("Original", 20,200);
    //moveWindow("Processed", 680,200);

//------------------------------    This default setting is for red color and variables
    int iLowH = 164;
    int iHighH = 179;
    int iLowS = 88; 
    int iHighS = 255;
    int iLowV = 116;
    int iHighV = 255;

    //Create trackbars in "HSV Control" window
    createTrackbar("LowH", "HSV Control", &iLowH, 240); //Hue (0 - 179)
    createTrackbar("HighH", "HSV Control", &iHighH, 255);
    createTrackbar("LowS", "HSV Control", &iLowS, 165); //Saturation (0 - 255)
    createTrackbar("HighS", "HSV Control", &iHighS, 180);
    createTrackbar("LowV", "HSV Control", &iLowV, 185);//Value (0 - 255)
    createTrackbar("HighV", "HSV Control", &iHighV, 205);

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

    cout<<"Press enter to start. Try tweaking the HSV mins and maxes using the trackbar window"<<endl;
    getchar();


//----------------------------------    Start Looping
    while (true) {
        //Grab image frame
        bool bSuccess = p_capwebcam.read(imgOriginal); // read a new frame from video
        if (!bSuccess) { //if not success, break loop
            cout << "Cannot read a frame from video stream" << endl;
            getchar(); 
            break;
        }
//----------------------------------    Image pre-processing and then display
    
        //Convert the captured frame from BGR to HSV
        cvtColor(imgOriginal, imgConvert, COLOR_BGR2HSV); 
        GaussianBlur(imgConvert,imgThresholded, Size(3,3), 1.5, 1.5);
        
        //Checks if array elements lie between the elements of two other arrays.
        inRange(imgThresholded, Scalar(iLowH, iLowS, iLowV), Scalar(iHighH, iHighS, iHighV), imgProcessed); 
        
        //morphological opening (removes small objects from the foreground)
        erode(imgProcessed, imgProcessed, getStructuringElement(MORPH_ELLIPSE, Size(5, 5)) );
        dilate( imgProcessed, imgProcessed, getStructuringElement(MORPH_ELLIPSE, Size(5, 5)) ); 

        //morphological closing (removes small holes from the foreground)
        dilate( imgProcessed, imgProcessed, getStructuringElement(MORPH_ELLIPSE, Size(10,10)) ); 
        erode(imgProcessed, imgProcessed, getStructuringElement(MORPH_ELLIPSE, Size(10,10)) );
        
        //imshow("Processed",imgProcessed);

//-------------------------     Image Processing
    
        //Find Contours
        findContours(imgProcessed, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE, Point(0,0));
        //Mat imgDrawing = Mat::zeros( imgOriginal.size(), CV_8UC3 );
        cout << "# " << contours.size();
        
        if (contours.size() == 2) {   
            /*
            for( int i = 0; i < contours.size(); i++ )
            {
                Scalar color = Scalar( rng.uniform(0, 255), rng.uniform(0,255), rng.uniform(0,255) );
                drawContours( imgOriginal, contours, i, color, 2, 8, hierarchy, 0, Point(0,0) );
            }
            */
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
                //circle( imgOriginal, mc[i], 6, Scalar(255, 0, 0), -1, 8, 0 );  
            }
            
            circle( imgOriginal, mc[c1], 8, Scalar(255, 0, 0), -1, 8, 0 );  //Mark only on big circle
            line(imgOriginal, mc[c1], mc[c2], Scalar(0, 0, 255), 4, 8, 0);  //Connect Mass Center 
            cout <<", "<< mc[c1] ;  // only center for big circle


            float angle = (atan2(mc[c2].y - mc[c1].y, mc[c2].x - mc[c1].x))*180/PI; //Determine the angle from horizontal line
            //cout << " ,& " <<mc[c2].y - mc[c1].y<<endl;
            if (mc[c2].y - mc[c1].y >= 0)
                cout << " ,* " << 360 - angle << endl;
            else 
                cout << " , " << angle*(-1) << endl;
        } else {   
            cout << " No mark detected." << endl;
        }
            
        imshow("Original",imgOriginal);
        //imshow("Processed",imgProcessed);

        if (waitKey(30) == 27) {//wait for 'esc' key press for 30ms. If 'esc' key is pressed, break loop
            cout << "ESC key is pressed by user" << endl;
            break;
        }
    }
}
