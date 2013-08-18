class Enemy {  

  float rotation, newRotation;
  float scaling, newScaling;
  float scaleStart, scaleEnd;

  PImage img;
  
  boolean isDestroyed = false;

  // animation
  float x=0, y=0, newX=0, newY=0;
  Ani zhulikX, zhulikY, zhulikRotation;
  
  AniSequence seq;
  
  PApplet applet;
  Movings movings;
  
  int circle = 0;
  Enemy(PApplet a, String imagePath, Movings m) {
    applet = a;
    movings = m;    
    init();
    img = loadImage(imagePath);
  }

  void init() {
    PVector initial = movings.initial();
    x = initial.x;
    y = initial.y;
    println("Enemy initiated: (" + x + ", " + y + ")");
  }

  void update() {
    if(!isDestroyed){
      seq = movings.sequence(applet, this);
      seq.start();
    }
  }

  void draw() {
    if(!isDestroyed){
      pushMatrix();
      translate(x, y);
      rotate(rotation);
      image(img, 0, 0);
      popMatrix();
    }
  }
  
  PVector getEnemy(){
    return new PVector(x, y);
  }
  
  void stop(){
    seq.pause();
    isDestroyed = true;
  }
}



