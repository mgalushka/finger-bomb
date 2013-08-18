// Class for animating a sequence of GIFs

class Animation {
  PImage[] images;
  int imageCount;
  int frame;
  
  Animation(String imagePrefix, int count, String ext) {
    imageCount = count;
    images = new PImage[imageCount];

    for (int i = 0; i < imageCount; i++) {
      // Use nf() to number format 'i' into four digits
      String filename = imagePrefix + i + ext;
      images[i] = loadImage(filename);
    }
  }

  void display(float xpos, float ypos) {
    frame = (frame+1) % imageCount;
    int adjHeight = (int) Math.floor(images[frame].height * (150.0/images[frame].width));
    image(images[frame], xpos, ypos, 150, adjHeight);
  }
  
  int getWidth() {
    return images[0].width;
  }
}
