public class Level{
  
  int number;
  PImage background;
  List<Enemy> enemies = new ArrayList<Enemy>();
  PApplet applet;
  
  boolean isCompleted = false;

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
    if(!isCompleted){
      imageMode(CORNER);   
      image(background, 0, 0, applet.width, applet.height);
      imageMode(CENTER);   
      for(int i=0; i<enemies.size(); i++){
        enemies.get(i).draw();
      }
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
    isCompleted = true;
    return true;
  } 
  
   
}
