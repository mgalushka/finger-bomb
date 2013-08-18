public abstract class Movings{
  public abstract PVector initial();  
  public abstract AniSequence sequence(PApplet applet, Object target);
}

public class Square extends Movings{
  
  int circle = 0;
  
  public PVector initial(){
    return new PVector(100, 100);
  }
  
  public AniSequence sequence(PApplet applet, Object target){
    AniSequence seq = new AniSequence(applet);
    seq.beginSequence();
    seq.add(Ani.to(target, 2, "x", 540, Ani.QUAD_IN_OUT));
    seq.add(Ani.to(target, 0.5, "rotation", circle*2*PI + PI/2, Ani.QUAD_IN_OUT));    
    seq.add(Ani.to(target, 2, "y", 380, Ani.QUAD_IN_OUT));
    seq.add(Ani.to(target, 0.5, "rotation", circle*2*PI + PI, Ani.QUAD_IN_OUT));
    seq.add(Ani.to(target, 2, "x", 100, Ani.QUAD_IN_OUT));
    seq.add(Ani.to(target, 0.5, "rotation", circle*2*PI + 3*PI/2, Ani.QUAD_IN_OUT));
    seq.add(Ani.to(target, 2, "y", 100, Ani.QUAD_IN_OUT));
    seq.add(Ani.to(target, 0.5, "rotation", circle*2*PI + 2*PI, Ani.EXPO_OUT, "onEnd:update"));
    seq.endSequence();
    circle++;
    return seq;
  }
}
