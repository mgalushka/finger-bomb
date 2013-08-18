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

import de.looksgood.ani.*;

ImageLibrary lib;
PImage pimg;
PImage camImg;
Capture cam;
CascadeClassifier classifier;

Maxim maxim;
AudioPlayer boom;
AudioPlayer puk;
AudioPlayer explosionSound;
AudioPlayer win;

ArrayList<Rect> faceRects;

// screen dimentions
int w = 640;
int h = 480;

Slider h1, v1, s1, h2, s2, v2;

Mat resulted_x;
Mat resulted_y;

PImage aimer;
Rect lastAim = new Rect(0, 0, 0, 0);

int HAMMER_FRAMES = 5;
List<Rect> hammers = new ArrayList<Rect>(HAMMER_FRAMES);
 

BufferedReader YELLOW, GREEN;

Scalar YELLOW_LOW = new Scalar(83, 148, 100);
Scalar YELLOW_HIGH = new Scalar(106, 216, 246);

Scalar GREEN_LOW = new Scalar(17, 91, 103);
Scalar GREEN_HIGH = new Scalar(77, 216, 246);

int currentFrame = 0;

boolean isCooling = false;
int coolingFrame = 0;

boolean isFire = false;
int fireFrame = 0;

Animation explosion;
Zhulik zhulik;

void setup()
{
  System.loadLibrary(Core.NATIVE_LIBRARY_NAME);
 
  size(3 * w, h);
  
  flipMap(w, h);

  String[] cameras = Capture.list();
  int finalCamera = -1;
  for(int i=0; i<1000; i++){
    cameras = Capture.list();
    println("Attempt #" + i + ":" + cameras);
    for(int c=0; c<cameras.length; c++){
      if(cameras[c].contains("size=640x480,fps=30")){
        finalCamera = c;
        break;  
      }
    }
    if(finalCamera >= 0){
      break;
    }    
  }
  if(finalCamera == -1){
    throw new RuntimeException("Cannot start camera!");
  }
  
  cam = new Capture(this, cameras[finalCamera]/*w, h*/); //  cameras[0],
  cam.start();
  
  frameRate(30);
  
  lib = new ImageLibrary(this);
  
  cleanupHammers();

  int blur = 9;
  String [] min;
  String [] max;
  try{
    YELLOW = createReader("D:/projects/creativity/CameraBattles/YELLOW.txt"); 
    min = YELLOW.readLine().split("\t");
    max = YELLOW.readLine().split("\t");
    println("Loaded YELLOW = [" + Arrays.toString(min)  + "] - [" + Arrays.toString(max) + "]");
    YELLOW_LOW = new Scalar(Integer.parseInt(min[0]), Integer.parseInt(min[1]), Integer.parseInt(min[2]));  
    YELLOW_HIGH = new Scalar(Integer.parseInt(max[0]), Integer.parseInt(max[1]), Integer.parseInt(max[2]));  
    YELLOW.close();  
      
    GREEN = createReader("D:/projects/creativity/CameraBattles/GREEN.txt"); 
    min = GREEN.readLine().split("\t");
    max = GREEN.readLine().split("\t");
    println("Loaded GREEN = [" + Arrays.toString(min)  + "] - [" + Arrays.toString(max) + "]");
    GREEN_LOW = new Scalar(Integer.parseInt(min[0]), Integer.parseInt(min[1]), Integer.parseInt(min[2]));  
    GREEN_HIGH = new Scalar(Integer.parseInt(max[0]), Integer.parseInt(max[1]), Integer.parseInt(max[2]));  
    GREEN.close();  
  } catch(IOException e) {e.printStackTrace();} 

  int slidersStart = 2*width/3 + 20;
  // RED - aim
  h1 = new Slider("H1", 83, 0, 255, slidersStart, 10, 150, 20, HORIZONTAL);
  s1 = new Slider("S1", 148, 0, 255, slidersStart, 30, 150, 20, HORIZONTAL);
  v1 = new Slider("V1", 100, 0, 255, slidersStart, 50, 150, 20, HORIZONTAL);
  
  // GREEN - hammer
  h2 = new Slider("H2", 106, 0, 255, slidersStart, 110, 150, 20, HORIZONTAL);
  s2 = new Slider("S2", 216, 0, 255, slidersStart, 130, 150, 20, HORIZONTAL);
  v2 = new Slider("V2", 246, 0, 255, slidersStart, 150, 150, 20, HORIZONTAL);


  aimer = loadImage("img/aim.png");
  explosion = new Animation("img/fire/explosion", 12, ".png");

  maxim = new Maxim(this);
  boom = maxim.loadFile("sounds/boom.wav");
  boom.setLooping(false);
  
  puk = maxim.loadFile("sounds/boom-puk.wav");
  puk.setLooping(false);
  
  explosionSound = maxim.loadFile("sounds/explosion.wav");
  explosionSound.setLooping(false);
  
  win = maxim.loadFile("sounds/win.wav");
  win.setLooping(false);

  // zhulik Ani animation
  Ani.init(this);
  zhulik = new Zhulik(this);
  zhulik.update();
  
  stroke(255);
  noFill();
}

void draw() 
{
  imageMode(CORNER);
  if (cam.available() == true) 
  {
    cam.read();
    camImg = cam;
    pimg = cam;
    Mat m = lib.toCV(pimg);
   
    //========= weapon recognizing ==========//
    // convert to HSV
    Mat hsv = new Mat(pimg.width, pimg.height, CvType.CV_8UC4);
    Imgproc.cvtColor(m, hsv, Imgproc.COLOR_BGR2HSV, 0);
    
    // flip
    Mat flipped = new Mat(pimg.width, pimg.height, CvType.CV_8UC4);
    Imgproc.remap(hsv, flipped, resulted_x, resulted_y, 0, 0, new Scalar(0, 0, 0));
    
    // apply gaussian blur
    Mat blured = new Mat(pimg.width, pimg.height, CvType.CV_8UC4);
    Imgproc.GaussianBlur(flipped, blured, new Size(3, 3), 3, 3);
    
    Mat aimInterimFiltered = new Mat(pimg.width, pimg.height, CvType.CV_8UC3);    
    Core.inRange(blured, YELLOW_LOW, YELLOW_HIGH, aimInterimFiltered);
    
    // visual debug     
    Mat aimRgbForDetection = new Mat(pimg.width, pimg.height, CvType.CV_8UC1);   
    Imgproc.cvtColor(aimInterimFiltered, aimRgbForDetection, Imgproc.COLOR_GRAY2BGR, 0); 
    
    // aim
    Rect aim = getRecognizedPosition(aimInterimFiltered);
    if (aim != null){
      lastAim = aim;
    }
    
    
    Mat hammerInterimFiltered = new Mat(pimg.width, pimg.height, CvType.CV_8UC3);    
    Core.inRange(flipped, GREEN_LOW, GREEN_HIGH, hammerInterimFiltered);  
    
    // visual debug - display hammer
    //Mat hammerRgbForDetection = new Mat(pimg.width, pimg.height, CvType.CV_8UC1);   
    //Imgproc.cvtColor(hammerInterimFiltered, hammerRgbForDetection, Imgproc.COLOR_GRAY2BGR, 0);     
    
    // hammer
    Rect hammer = getRecognizedPosition(hammerInterimFiltered);
    //if (hammer != null){
      //hammers.add(currentFrame, hammer);
      //println("Hammer: x=" + hammer.x + ", y=" + hammer.y);
    //}
    
    // background
    fill(255, 255, 255);
    // TEST
    rect(0, 0, width/3, height);
    // PROD
    //rect(0, 0, width, height);
    
    if(!isCooling){
      /*
      int maxY = -1;
      int minY = height + 1;    
      for(int i=0; i<HAMMER_FRAMES; i++){
        PVector h = hammers.get(i);
        if(h != null){
          if(h.y > maxY){
            maxY = (int) h.y;      
          }
          if(h.y < minY){
            minY = (int) h.y;      
          }
        }
        if(maxY != -1 && minY != height + 1){
          println(Math.abs(maxY-minY));
          if(Math.abs(maxY-minY) >= 100){
            // FIRE!!!
            isFire = true;
            isCooling = true; 
            cleanupHammers();     
          }
        }  
      }
      */
      if(lastAim != null && hammer != null){
        // if we are firing
        if(dist(lastAim.x, lastAim.y, hammer.x, hammer.y) < 100){
          isFire = true;
          isCooling = true; 
        }
      }
    }
    
    //pimg = lib.toP5(interimFiltered); 
    //image(pimg, 0, 0, width/3, height);
    
    imageMode(CENTER);
    if(isFire){
      fireFrame = (fireFrame + 1) % 12;
      if(fireFrame == 1){
        boom.cue(0);
        boom.play();
      }
      if(fireFrame == 0){
        isFire = false;
      }
      else{
        // if we targeted to zhulik
        if(dist(zhulik.getZhulik().x, zhulik.getZhulik().y, lastAim.x, lastAim.y) < 100){
          explosion.display(lastAim.x, lastAim.y);  
          zhulik.stop();
          //if(fireFrame == 5){
          explosionSound.cue(0);
          explosionSound.play();
          delay(1000);
          win.cue(0);
          win.play();
          //}   
        }
        else{
           //if(fireFrame == 5){
            puk.cue(0);
            puk.play();
          //}   
        }          
      }
    }
    
    imageMode(CENTER);
    // draw aim
    image(aimer, lastAim.x, lastAim.y);
    
    // TEST
    //rect(lastAim.x, lastAim.y, lastAim.width, lastAim.height);    
        
    // zhulik
    zhulik.draw();
    
    imageMode(CORNER);
    
    
    // draw what actually is displayed in camera
    // flip camera image
    //Mat realCamFlipped = new Mat(pimg.width, pimg.height, CvType.CV_8UC4);
    //Imgproc.remap(m, realCamFlipped, resulted_x, resulted_y, 0, 0, new Scalar(0, 0, 0));
    
    Mat camMat = lib.toCV(camImg);
    Mat realCamFlipped = new Mat(camImg.width, camImg.height, CvType.CV_8UC4);
    Imgproc.remap(camMat, realCamFlipped, resulted_x, resulted_y, 0, 0, new Scalar(0, 0, 0));
    
    Mat camFinal = new Mat(camImg.width, camImg.height, CvType.CV_8UC4);
    Imgproc.cvtColor(realCamFlipped, camFinal, Imgproc.COLOR_BGR2RGB, 0);
    
    // TEST
    image(lib.toP5(camFinal), width/3, 0, width/3, height);
    
    currentFrame = (currentFrame + 1) % HAMMER_FRAMES;
    
    // calculate cooling frames
    if(isCooling){
      coolingFrame = (coolingFrame + 1) % 10;
      if(coolingFrame == 0){
        isCooling = false;
      }
    }
 
  }

  //fill(128, 128, 0);
  
  // TEST
  rect(2*width/3, 0, width/2, height);
  //rect(0, 0, width, height);
  

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
Rect getRecognizedPosition(Mat finger){
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
  
  // if found square is really big (50px)
  if(largestRect != null && largest > 50){
    return new Rect(largestRect.x+largestRect.width/2, largestRect.y+largestRect.height/2, largestRect.width, largestRect.height);
  }
  
  return null;
  
}

void cleanupHammers(){
  
  // just fill the array list
  for(int j=0; j<HAMMER_FRAMES; j++){
    hammers.add(new Rect(0, 0, 0, 0));
  }
  
}




