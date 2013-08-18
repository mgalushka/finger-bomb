public abstract class Movings{
  public abstract PVector initial();  
  public abstract float rotation();
  public abstract AniSequence sequence(PApplet applet, Object target);
}

public class Square extends Movings{
  
  int circle = 0;
  float speed = random(1, 3);  
  
  Square(){
    speed = random(1, 3);
  }  
  
  public PVector initial(){
    return new PVector(100, 100);
  }
  
  public float rotation(){
    return 0;
  }
  
  public AniSequence sequence(PApplet applet, Object target){
    AniSequence seq = new AniSequence(applet);
    seq.beginSequence();
    seq.add(Ani.to(target, speed, "x", 540, Ani.QUAD_IN_OUT));
    seq.add(Ani.to(target, 0.5, "rotation", circle*2*PI + PI/2, Ani.QUAD_IN_OUT));    
    seq.add(Ani.to(target, speed, "y", 380, Ani.QUAD_IN_OUT));
    seq.add(Ani.to(target, 0.5, "rotation", circle*2*PI + PI, Ani.QUAD_IN_OUT));
    seq.add(Ani.to(target, speed, "x", 100, Ani.QUAD_IN_OUT));
    seq.add(Ani.to(target, 0.5, "rotation", circle*2*PI + 3*PI/2, Ani.QUAD_IN_OUT));
    seq.add(Ani.to(target, speed, "y", 100, Ani.QUAD_IN_OUT));
    seq.add(Ani.to(target, 0.5, "rotation", circle*2*PI + 2*PI, Ani.EXPO_OUT, "onEnd:update"));
    seq.endSequence();
    circle++;
    return seq;
  }
}

public class LeftRight extends Movings{
  
  int circle = 0;
  boolean back = false;
  float speed = 0;
  
  LeftRight(boolean b){
    back = b;
    speed = random(1, 3);    
  }
  
  public float rotation(){
    return back ? PI : 0;
  }
  
  public PVector initial(){
    return new PVector(random(100, 500), random(100, 380));
  }
  
  public AniSequence sequence(PApplet applet, Object target){
    AniSequence seq = new AniSequence(applet);
    seq.beginSequence();
    seq.add(Ani.to(target, speed, "x", 540, Ani.QUAD_IN_OUT));
    seq.add(Ani.to(target, 0.5, "rotation", circle*2*PI + PI, Ani.QUAD_IN_OUT));    
    seq.add(Ani.to(target, speed, "x", 100, Ani.QUAD_IN_OUT));
    seq.add(Ani.to(target, 0.5, "rotation", circle*2*PI + 2*PI, Ani.EXPO_OUT, "onEnd:update"));
    seq.endSequence();
    circle++;
    return seq;
  }
}

public class TopBottom extends Movings{
  
  int circle = 0;
  boolean back = false;
  float speed = 0;
  
  TopBottom(boolean b){
    back = b;
    speed = random(1, 3);
  }
  
  public float rotation(){
    return back ? PI/2 : 3*PI/2;
  }
    
  public PVector initial(){
    return new PVector(random(100, 500), random(100, 380));
  }
  
  public AniSequence sequence(PApplet applet, Object target){
    AniSequence seq = new AniSequence(applet);
    seq.beginSequence();
    seq.add(Ani.to(target, speed, "y", 380, Ani.QUAD_IN_OUT));
    seq.add(Ani.to(target, 0.5, "rotation", circle*2*PI + PI, Ani.QUAD_IN_OUT));    
    seq.add(Ani.to(target, speed, "y", 100, Ani.QUAD_IN_OUT));
    seq.add(Ani.to(target, 0.5, "rotation", circle*2*PI + 2*PI, Ani.EXPO_OUT, "onEnd:update"));
    seq.endSequence();
    circle++;
    return seq;
  }
}

public class RandomMover extends Movings{
  
  float speed = 0;
  
  RandomMover(){
    speed = random(0.5, 2);
  }  
  
  public float rotation(){
    return random(2*PI);
  }
      
  public PVector initial(){
    return new PVector(random(100, 500), random(100, 380));
  }
  
  public AniSequence sequence(PApplet applet, Object target){
    AniSequence seq = new AniSequence(applet);
    seq.beginSequence();
    seq.add(Ani.to(target, speed, "x", random(100, 540), Ani.QUAD_IN_OUT));
    seq.add(Ani.to(target, speed, "y", random(100, 380), Ani.QUAD_IN_OUT));
    seq.add(Ani.to(target, 0.5, "rotation", random(2*PI), Ani.QUAD_IN_OUT));    
    seq.add(Ani.to(target, speed, "y", random(100, 380), Ani.EXPO_OUT, "onEnd:update"));
    seq.endSequence();
    return seq;
  }
}
