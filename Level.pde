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
    println("Level dimentions: " + (CameraBattles.TEST ? applet.width/2 : applet.width) + ", " + applet.height);
  }
  
  void init(){
    
  }
  
  void add(Enemy e){
    enemies.add(e);  
  }

  int start = 1;
  void draw(){
    if(start != 0){
      imageMode(CORNER);   
      image(background, 0, 0, CameraBattles.TEST ? applet.width/2 : applet.width, applet.height);
      textSize(60);
      fill(255, 0, 0);
      text("Level " + number, (CameraBattles.TEST ? applet.width/4-100 : applet.width/2), applet.height/2);
      start = (start + 1) % 30;
    }
    if(!isCompleted && start == 0){
      imageMode(CORNER);   
      image(background, 0, 0, CameraBattles.TEST ? applet.width/2 : applet.width, applet.height);
      imageMode(CENTER);   
      for(int i=0; i<enemies.size(); i++){
        enemies.get(i).draw();
      }
    }
  }
  
  // all collision logic for level is moved here
  boolean collision(Rect lastAim){
    if(start == 0){
      for(int i=0; i<enemies.size(); i++){
        Enemy e = enemies.get(i);
        if(e != null && e.getEnemy() != null){
          if(dist(e.getEnemy().x, e.getEnemy().y, lastAim.x, lastAim.y) < 100){
            // destroys enemy
            e.stop();
            println ("stop enemy: " + e.isDestroyed);
            return true;
          }
        }
      }
    }
    return false;
  }
  
  boolean completed(){
    if(start != 0) return false;
    if(isCompleted) return true;
    
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
