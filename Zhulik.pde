class Zhulik {
  // polar coordinates
  //float a, l;

  // image
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
  
  int circle = 0;
  Zhulik(PApplet a) {
    applet = a;
    init();
    img = loadImage("img/zhulik.png");
  }

  void init() {
    //zhulikX = 100;
    //zhulikY = 100;
    //l = 100 * 1.44;
    x = 100;
    y = 100;
  }

  void randomize() {
    //a = 0;
    //newScaling = random(scaleStart,scaleEnd);
    //float tmpRotation = AniUtil.shortRotation(rotation,newRotation);
    //newRotation = a + random(-PI,PI);
  }

  void update() {
    if(!isDestroyed){
      //init();    
      //newX = width/2 + cos(a) * l;
      //newY = height/2 + sin(a) * l;
      //aniX = Ani.to(this, random(5,10), "x", newX, Ani.QUAD_IN_OUT);
      //aniY = Ani.to(this, random(5,10), "y", newY, Ani.QUAD_IN_OUT);
      //aniRotation = Ani.to(this, random(5,10), "rotation", newRotation, Ani.QUAD_IN_OUT, "onEnd:update");
      //aniScaling = Ani.to(this, random(1,5), "scaling", newScaling, Ani.SINE_IN_OUT);
      
      //zhulik = new AniSequence(this);
      //zhulik.beginSequence();
      seq = new AniSequence(applet);
      seq.beginSequence();
      seq.add(Ani.to(this, 2, "x", 400, Ani.QUAD_IN_OUT));
      seq.add(Ani.to(this, 2, "rotation", circle*2*PI + PI/2, Ani.QUAD_IN_OUT));    
      seq.add(Ani.to(this, 2, "y", 400, Ani.QUAD_IN_OUT));
      seq.add(Ani.to(this, 2, "rotation", circle*2*PI + PI, Ani.QUAD_IN_OUT));
      seq.add(Ani.to(this, 2, "x", 100, Ani.QUAD_IN_OUT));
      seq.add(Ani.to(this, 2, "rotation", circle*2*PI + 3*PI/2, Ani.QUAD_IN_OUT));
      seq.add(Ani.to(this, 2, "y", 100, Ani.QUAD_IN_OUT));
      seq.add(Ani.to(this, 2, "rotation", circle*2*PI + 2*PI, Ani.EXPO_OUT, "onEnd:update"));
      seq.endSequence();
      seq.start();
      circle++;
      //println ("Zhulik update executed");
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
  
  PVector getZhulik(){
    return new PVector(x, y);
  }
  
  void stop(){
    seq.pause();
    isDestroyed = true;
  }
}



