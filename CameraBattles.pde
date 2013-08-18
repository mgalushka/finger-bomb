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
PImage hat;

Maxim maxim;
AudioPlayer boom;
AudioPlayer puk;
AudioPlayer explosionSound;
AudioPlayer win;
AudioPlayer total;

boolean faceRec = false;
boolean lastSolo = false;
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

int BLUR = 9;

boolean TEST = true;

int currentFrame = 0;

boolean isCooling = false;
int coolingFrame = 0;

boolean isFire = false;
int fireFrame = 0;

Animation explosion;
Animation miss;

List<Level> levels;
int currentLevel = 0;
int MAX_LEVELS = 0;

void setup()
{
  System.loadLibrary(Core.NATIVE_LIBRARY_NAME);
  w = TEST ? 640 : 640;
  h = TEST ? 480 : 480;
 
  int wdth = TEST ? 3*w : w;
  size(wdth, h);
  
  flipMap(w, h);
  
  classifier = new CascadeClassifier(dataPath("haarcascade_frontalface_default.xml"));
  faceRects = new ArrayList(); 

  String[] cameras = Capture.list();
  int finalCamera = -1;
  for(int i=0; i<1000; i++){
    cameras = Capture.list();
    println("Attempt #" + i + ":" + Arrays.toString(cameras));
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
  
  cam = new Capture(this, cameras[finalCamera]); 
  cam.start();
  
  frameRate(30);
  
  lib = new ImageLibrary(this);
  
  cleanupHammers();

  // load color boundaries to recognize movings
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

  if(TEST){
    int slidersStart = 2*width/3 + 20;
    // RED - aim
    h1 = new Slider("H1", 83, 0, 255, slidersStart, 10, 150, 20, HORIZONTAL);
    s1 = new Slider("S1", 148, 0, 255, slidersStart, 30, 150, 20, HORIZONTAL);
    v1 = new Slider("V1", 100, 0, 255, slidersStart, 50, 150, 20, HORIZONTAL);
    
    // GREEN - hammer
    h2 = new Slider("H2", 106, 0, 255, slidersStart, 110, 150, 20, HORIZONTAL);
    s2 = new Slider("S2", 216, 0, 255, slidersStart, 130, 150, 20, HORIZONTAL);
    v2 = new Slider("V2", 246, 0, 255, slidersStart, 150, 150, 20, HORIZONTAL);
  }

  aimer = loadImage("img/aim.png");
  explosion = new Animation("img/fire/explosion", 12, ".png");
  miss = new Animation("img/miss/miss", 12, ".png");
  hat = loadImage("img/hat.png");

  maxim = new Maxim(this);
  boom = maxim.loadFile("sounds/boom.wav");
  boom.setLooping(false);
  
  puk = maxim.loadFile("sounds/boom-puk.wav");
  puk.setLooping(false);
  
  explosionSound = maxim.loadFile("sounds/explosion.wav");
  explosionSound.setLooping(false);
  
  win = maxim.loadFile("sounds/win.wav");
  win.setLooping(false);
  
  total = maxim.loadFile("sounds/total-win.wav");
  total.setLooping(false);

  // enemies Ani animation
  Ani.init(this);
  levels = generateLevels(this);
  currentLevel = 0;
  MAX_LEVELS = levels.size();
  
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
    Imgproc.GaussianBlur(flipped, blured, new Size(11, 11), 11, 11);
    
    // recognize
    Mat aimInterimFiltered = new Mat(pimg.width, pimg.height, CvType.CV_8UC4);    
    Core.inRange(blured, YELLOW_LOW, YELLOW_HIGH, aimInterimFiltered);
    
    // visual debug     
    //Mat aimRgbForDetection = new Mat(pimg.width, pimg.height, CvType.CV_8UC1);   
    //Imgproc.cvtColor(aimInterimFiltered, aimRgbForDetection, Imgproc.COLOR_GRAY2BGR, 0); 
    
    // aim
    Rect aim = getRecognizedPosition(aimInterimFiltered);
    if (aim != null){
      lastAim = aim;
    }
    
    // hammer
    Mat hammerInterimFiltered = new Mat(pimg.width, pimg.height, CvType.CV_8UC4);    
    Core.inRange(blured, GREEN_LOW, GREEN_HIGH, hammerInterimFiltered);  

    // can be null 
    Rect hammer = getRecognizedPosition(hammerInterimFiltered);
    
    // background - white
    fill(255, 255, 255);
    rect(0, 0, TEST ? width/3 : width, height);
    
    if(!isCooling){
      if(lastAim != null && hammer != null){
        // if we are firing
        if(dist(lastAim.x, lastAim.y, hammer.x, hammer.y) < 100){
          isFire = true;
          isCooling = true; 
        }
      }
    }
    
    
    
    Level current = levels.get(currentLevel);
    if(current.completed()){
      if(!lastSolo){
        delay(1000);
        println("win");
        win.cue(0);
        win.play();
        if(currentLevel == (MAX_LEVELS-1)){
          delay(1800);
          println("total win");
          total.cue(0);
          total.play(); 
        }
        lastSolo = true;
        // start camera performance    
        faceRec = true;
      }
    }
    
    imageMode(CENTER);
    if(isFire && !faceRec){
      fireFrame = (fireFrame + 1) % 12;
      println("Fire frame: " + fireFrame);
      if(fireFrame == 1){
        println("boom");
        boom.cue(0);
        boom.play();
      }
      if(fireFrame == 0){
        isFire = false;
      }
      else{
        // if we targeted the enemy - check it with level
        if(current.collision(lastAim)){
          println("collision");   
          explosion.display(lastAim.x, lastAim.y);
          if(fireFrame == 1){     
            println("explosion");   
            explosionSound.cue(0);
            explosionSound.play();                    
          }
        }
        else{
          // on 7 frame - miss sound 
          if(fireFrame == 7){   
            println("puk");
            puk.cue(0);
            puk.play();
          }
        }          
      }
    }
    
    if(TEST){
      // TEST
      fill(255, 0, 0);
      rect(lastAim.x, lastAim.y, lastAim.width, lastAim.height);
      if(hammer != null){
        fill(0, 0, 255);
        rect(hammer.x, hammer.y, hammer.width, hammer.height);
      }
      noFill();
    }    
        
    // zhulik
    //zhulik.draw();
    // enemies animation handeled here
    levels.get(currentLevel).draw();
    
    imageMode(CENTER);
    // draw aim
    image(aimer, lastAim.x, lastAim.y);
    
    imageMode(CORNER);    
    
    // face featuring
    if(faceRec){
      pimg = lib.toP5(flipped); 
      image(pimg, 0, 0, TEST ? width/3 : width, height);
    }
    
    if(TEST){
      // draw what actually is displayed in camera
      // flip camera image
      Mat camMat = lib.toCV(camImg);
      Mat realCamFlipped = new Mat(camImg.width, camImg.height, CvType.CV_8UC4);
      Imgproc.remap(camMat, realCamFlipped, resulted_x, resulted_y, 0, 0, new Scalar(0, 0, 0));
      
      Mat camFinal = new Mat(camImg.width, camImg.height, CvType.CV_8UC4);
      Imgproc.cvtColor(realCamFlipped, camFinal, Imgproc.COLOR_BGR2RGB, 0);
      
      image(lib.toP5(camFinal), width/3, 0, width/3, height);
    }
    
    // face featuring
    if(faceRec){
      
      // draw what actually is displayed in camera
      // flip camera image
      Mat camMat = lib.toCV(camImg);
      Mat realCamFlipped = new Mat(camImg.width, camImg.height, CvType.CV_8UC4);
      Imgproc.remap(camMat, realCamFlipped, resulted_x, resulted_y, 0, 0, new Scalar(0, 0, 0));
      
      Mat camFinal = new Mat(camImg.width, camImg.height, CvType.CV_8UC4);
      Imgproc.cvtColor(realCamFlipped, camFinal, Imgproc.COLOR_BGR2RGB, 0);
      
      image(lib.toP5(camFinal), 0, 0, TEST ? width/3 : width, height);
      
      Size minSize = new Size(150, 150);
      Size maxSize = new Size(300, 300);
      MatOfRect objects = new MatOfRect();
      Mat gray = new Mat(camImg.width, camImg.height, CvType.CV_8U);
      Imgproc.cvtColor(realCamFlipped, gray, Imgproc.COLOR_BGRA2GRAY);
      classifier.detectMultiScale(gray, objects, 1.1, 3, Objdetect.CASCADE_DO_CANNY_PRUNING | Objdetect.CASCADE_DO_ROUGH_SEARCH, minSize, maxSize);

      if(objects.toArray() != null && objects.toArray().length > 0){
        Rect head = objects.toArray()[0];
        int headWidth = head.width - 10;
        int imgHeight = (int) Math.floor(hat.height * ((float)headWidth/hat.width));
        imageMode(CORNER);    
        image(hat, head.x, head.y-imgHeight+20, headWidth, imgHeight);
      }

    }
    
    currentFrame = (currentFrame + 1) % HAMMER_FRAMES;
    
    // calculate cooling frames
    if(isCooling){
      coolingFrame = (coolingFrame + 1) % 10;
      if(coolingFrame == 0){
        isCooling = false;
      }
    }
 
  }

  
  if(TEST){
    rect(2*width/3, 0, 2*width/3, height);
  
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
}

// TODO: generates all the levels - to move to configuration file
// for demo - this will be just code here
List<Level> generateLevels(PApplet applet){
  List<Level> levels = new ArrayList<Level>();
  Level l0 = new Level(applet, 1, "img/levels/bg0.png");
  Enemy sq = new Enemy(applet, "img/zhulik.png", new Square());
  sq.update();
  l0.add(sq);
  
  levels.add(l0);
  return levels;
}

void mousePressed() {
  if(TEST){
    h1.mousePressed();
    s1.mousePressed();
    v1.mousePressed();
    
    h2.mousePressed();
    s2.mousePressed();
    v2.mousePressed();
  }
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
  
  // if found square is really big (25px)
  if(largestRect != null && largest > 25){
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




