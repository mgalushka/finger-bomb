import processing.video.*;

import org.opencv.video.*;
import org.opencv.core.*;
import org.opencv.calib3d.*;
import org.opencv.contrib.*;
import org.opencv.objdetect.*;
import org.opencv.imgproc.*;
import org.opencv.utils.*;
import org.opencv.features2d.*;
import org.opencv.highgui.*;
import org.opencv.ml.*;
import org.opencv.photo.*;

import java.util.*;

ImageLibrary lib;
PImage pimg;
PImage camImg;
Capture cam;
CascadeClassifier classifier;

ArrayList<Rect> faceRects;

// screen dimentions
int w = 640;
int h = 480;

Slider h1, v1, s1, h2, s2, v2;

Mat resulted_x;
Mat resulted_y;

PImage aimer;
PVector lastAim = new PVector(0, 0);

void setup()
{
  System.loadLibrary(Core.NATIVE_LIBRARY_NAME);
 
  size(3 * w, h);
  
  flipMap(w, h);

  String[] cameras = Capture.list();
  println(cameras);
  cam = new Capture(this, cameras[1]/*w, h*/); //  cameras[0],
  cam.start();
  
  lib = new ImageLibrary(this);

  int slidersStart = 2*width/3 + 20;
  // YELLOW recognizer
  h1 = new Slider("H1", 83, 0, 255, slidersStart, 10, 150, 20, HORIZONTAL);
  s1 = new Slider("S1", 148, 0, 255, slidersStart, 30, 150, 20, HORIZONTAL);
  v1 = new Slider("V1", 100, 0, 255, slidersStart, 50, 150, 20, HORIZONTAL);
  
  h2 = new Slider("H2", 106, 0, 255, slidersStart, 110, 150, 20, HORIZONTAL);
  s2 = new Slider("S2", 216, 0, 255, slidersStart, 130, 150, 20, HORIZONTAL);
  v2 = new Slider("V2", 246, 0, 255, slidersStart, 150, 150, 20, HORIZONTAL);

  aimer = loadImage("img/aim.png");

  stroke(255);
  noFill();
}

void draw() 
{

  if (cam.available() == true) 
  {
    cam.read();
    camImg = cam;
    pimg = cam;
    Mat m = lib.toCV(pimg);
   
    
    Mat camFlipped = new Mat(pimg.width, pimg.height, CvType.CV_8UC4);
    Imgproc.remap(m, camFlipped, resulted_x, resulted_y, 0, 0, new Scalar(0, 0, 0));
    
    Mat hsv = new Mat(pimg.width, pimg.height, CvType.CV_8UC4);
    Imgproc.cvtColor(m, hsv, Imgproc.COLOR_BGR2HSV, 0);
    
    Mat flipped = new Mat(pimg.width, pimg.height, CvType.CV_8UC4);
    Imgproc.remap(hsv, flipped, resulted_x, resulted_y, 0, 0, new Scalar(0, 0, 0));
    
    //Mat rgbBlured = new Mat(pimg.width, pimg.height, CvType.CV_8UC4);
    //Imgproc.cvtColor(rgb, rgbBlured, 3);
    
    Mat interimFiltered = new Mat(pimg.width, pimg.height, CvType.CV_8UC4);    
    int lower = 150;
    Core.inRange(flipped, new Scalar(h1.get(), s1.get(), v1.get()), new Scalar(h2.get(), s2.get(), v2.get()), interimFiltered);
    
    Mat interimRGB = new Mat(pimg.width, pimg.height, CvType.CV_8UC1);   
    Imgproc.cvtColor(interimFiltered, interimRGB, Imgproc.COLOR_GRAY2BGR, 0); 
    
   
    pimg = lib.toP5(interimFiltered);    
  
  
    if(pimg != null){    
      //image(pimg, 0, 0, width/3, height);
      
      PVector aim = getAimPosition(interimFiltered);
      if (aim != null){
        lastAim = aim;
      }
      fill(255, 255, 255);
      rect(0, 0, width/3, height);
      image(aimer, lastAim.x, lastAim.y);
      
      Mat camMat = lib.toCV(camImg);
      Mat realCamFlipped = new Mat(camImg.width, camImg.height, CvType.CV_8UC4);
      Imgproc.remap(camMat, realCamFlipped, resulted_x, resulted_y, 0, 0, new Scalar(0, 0, 0));
      
      Mat camFinal = new Mat(camImg.width, camImg.height, CvType.CV_8UC4);
      Imgproc.cvtColor(camFlipped, camFinal, Imgproc.COLOR_BGR2RGB, 0);
      image(lib.toP5(camFinal), width/3, 0, width/3, height);
    }
 
  }

  fill(128, 128, 0);
  rect(2*width/3, 0, width/2, height);
  
  noStroke();
  fill(255, 0, 0);
  if (mousePressed) {
      h1.mouseDragged();
      s1.mouseDragged();
      v1.mouseDragged();
      
      h2.mouseDragged();
      s2.mouseDragged();
      v2.mouseDragged();
  }
  
  
  stroke(255, 0, 0);
  h1.display();
  s1.display();
  v1.display();
  
  h2.display();
  s2.display();
  v2.display();
  
  int textStart = 2*width/3 + 180;
  int heightShift = 10;
  text(h1.get(), textStart, heightShift+10);
  text(s1.get(), textStart, heightShift+30);
  text(v1.get(), textStart, heightShift+50);
  
  text(h2.get(), textStart, heightShift+110);
  text(s2.get(), textStart, heightShift+130);
  text(v2.get(), textStart, heightShift+150);
}

void mousePressed() {
  h1.mousePressed();
  s1.mousePressed();
  v1.mousePressed();
  
  h2.mousePressed();
  s2.mousePressed();
  v2.mousePressed();
}


void flipMap(int w, int h)
{   
   resulted_x = new Mat(h, w, CvType.CV_32FC1);
   resulted_y = new Mat(h, w, CvType.CV_32FC1);
   for( int j = 0; j < h; j++ ){ 
     for( int i = 0; i < w; i++ ){        
           resulted_x.put(j, i, w - i);
           resulted_y.put(j, i, j);  
       }
    }
}


/**
 * returns the position of aim to shoot
 */
PVector getAimPosition(Mat finger){
  List<MatOfPoint> contours = new ArrayList<MatOfPoint>();
  Imgproc.findContours(finger, contours, new Mat(), Imgproc.RETR_EXTERNAL, Imgproc.CHAIN_APPROX_SIMPLE);
  
  float largest = 0;
  Rect largestRect = null;
  for (int i=0; i<contours.size(); i++)  {
    Rect r = Imgproc.boundingRect(contours.get(i));
    float dist = dist(r.x, r.y, r.x+r.width, r.y+r.height);
    if(dist > largest){
      largestRect = r;    
      largest = dist;
    }
  }
  
  if(largestRect != null){
    stroke(255, 0 , 0);
    fill(128, 128, 0);
    //rect(largestRect.x, largestRect.y, largestRect.width, largestRect.height);
    return new PVector((largestRect.x+largestRect.width)/2, (largestRect.y+largestRect.height)/2);
  }
  
  return null;
  
}





