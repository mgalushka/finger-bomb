public class Level{
  
  int number;
  PImage background;
  List<Enemy> enemies = new ArrayList<Enemy>();
  PApplet applet;

  Level(PApplet a, int n, String bg) {
    applet = a;
    number = n;
    init();
    background = loadImage(bg);
    println("Level dimentions: " + applet.width + ", " + applet.height);
  }
  
  void init(){
    
  }
  
  void add(Enemy e){
    enemies.add(e);  
  }

  void draw(){
    image(background, applet.width/2, applet.height/2, applet.width, applet.height);
    //println("Level dimentions: " + applet.width + ", " + applet.height);
    for(int i=0; i<enemies.size(); i++){
      enemies.get(i).draw();
    }
  }
  
  // all collision logic for level is moved here
  boolean collision(Rect lastAim){
    for(int i=0; i<enemies.size(); i++){
      Enemy e = enemies.get(i);
      if(e != null && e.getEnemy() != null){
        if(dist(e.getEnemy().x, e.getEnemy().y, lastAim.x, lastAim.y) < 100){
          // destroys enemy
          e.stop();
          return true;
        }
      }
    }
    return false;
  }
  
  boolean completed(){
    for(int i=0; i<enemies.size(); i++){
      Enemy e = enemies.get(i);
      if(!e.isDestroyed){
        return false;
      }
    }
    return true;
  } 
  
   
}
