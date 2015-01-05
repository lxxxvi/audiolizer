// ---------------------------------------------------------------------- //
//                                                                        //
// Grundcode von einem Minim-Manual übernommen und dann weiterentwickelt  //
// http://lernprocessing.wordpress.com/2012/06/18/minim-audio-analyse/    //
// Meco 2014: Audio Visualizer                                            //
// ---------------------------------------------------------------------- //
import java.io.File; 
import ddf.minim.*;
import ddf.minim.analysis.*;
import processing.video.*;

// Objekte erstellen
Minim minim;
AudioPlayer input;
BeatDetect beat;
Capture cam;

FFT fft;
AudioMetaData meta;

// Variablen für den Farbwelchsel
 int colorR = 0;
 boolean isWhite = false;
 
 // Blitzvariablen
 int nsx;
 int nsy;

int x, y;
 
// Anzahl der Peaks
int grid=500;
 
// Abstand zwischen den Peaks
int spacing=1;
 
// Ausschlagmaximum für Peaks festlegen
  // für mittleren Graph
float yScale = 0.3;
  // für oberen und unteren Graph
float yScale2 = 0.05;

PFont f;
File audioFilePath = null;
int fileNameOpacity = 255;
int frames = 0;
 
 int screen_width  = 1024;
 int screen_height = 768;
 
void setup() {
    
  size(1024, 768);
  smooth();

  // user muss file auswaehlen
  selectInput("Select a file to process:", "fileSelected");

  // warte bis file ausgewaehlt ist
  while(audioFilePath == null) {
    delay(100);
  }
  
  f = createFont("Arial",16,true);
  
  // Konstruktor des Minim Objekts aufrufen
  minim = new Minim(this);
 
  // Einlesen der Musikdatei
  //input = minim.loadFile("Blitz.mp3");
  input = minim.loadFile(audioFilePath.getAbsolutePath());
  meta = input.getMetaData();
  
  fft = new FFT(input.bufferSize(), input.sampleRate());
 
  // Wiedergabe starten
  input.play();

  beat = new BeatDetect();
  
  cam = new Capture(this,320,240,30);
  cam.start();
  

  
}

// file selector
void fileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
    audioFilePath = null;
    
  } else {
    audioFilePath = selection;
    println("User selected " + audioFilePath.getAbsolutePath());
  }
}

 
void draw() {
   
  drawCamera();
  
  // für etwas Bewegunsunschärfe
  fill(0, 60);
  rect(-1, -1, width+1, height+1);
  
  beat.detect(input.mix);
 
  // Auslesen und speichern des Spektrums
  float[] buffer = input.mix.toArray();
 
  float lastX = 0.0;
  float lastY = 0.0;
  float lastY2 = 0.0;

  for (int i=1; i <= buffer.length; i+=buffer.length/grid) {
    float x = map(i, 0, buffer.length, 0, width);
    float y = map(buffer[i-1]*yScale, -1, 1, 0, height) ;
    float y2 = map(buffer[i-1]*yScale2, -1, 1, 0, height) ;

    // Farbwechsel von weiss zu grün/blau
    if(isWhite == true){
      strokeWeight(3);
      strokeCap(SQUARE);
      stroke(colorR--,255,255,80);
  
      if(colorR == 0){
        isWhite = false;
      }
    // Farbwechsel von grün/blau zu weiss
    }else{
      strokeWeight(3);
      strokeCap(SQUARE);
      stroke(colorR++, 255, 255,80);
      
      if(colorR == 255){
        isWhite = true;
      }
    }  

    // Zeichnet Linien zwischen den Spektrumshöhen
    line(lastX+10,lastY,x+20,y);

    strokeWeight(3);
    strokeCap(ROUND);
    stroke(colorR,255,255);
    
    line(lastX,lastY,x,y);
    line(lastX,lastY2+90,x,y2+90);
    line(lastX,lastY2-90,x,y2-90);

    lastX = x;
    lastY = y;
    lastY2 = y2;

  }

  // Beatabfrage
  if ( beat.isOnset() ){
    // Flashefekt
    fill(255,150);
    rect(-1, -1, width+1, height+1);

    // Zeichnet einen Blitz in der oberen Hälfte sowie einen in der unteren Hälfte des Bildschirms
    lightning((int)random(1024),height/2-90);
    lightning((int)random(1024),height/2+90);
  }
  
  
  // Filename anzeigen und ausblenden 
  /*if(fileNameOpacity > 0) {
      frames++;
      
      if(frames > 10) {
        fileNameOpacity = 255 - (frames*20); // je hoeher die zahl (20) desto schneller der Fade-Out
      } 
     
      textFont(f,36);
      fill(255, 255, 255, fileNameOpacity);
      text(audioFilePath.getName(), 30, 40);
  }*/

  displayMetaData();
  frequencySpectrum();
    
  
}
 
void lightning(int sx, int sy){
  
  // Abfrage in welche Richtung der Blitz sich ausbreiten soll
  if(sy<height/2){
    nsx = (int)random(sx-30,sx+30);
    nsy = (int)random(sy-5,sy-20);
  }else{
    nsx = (int)random(sx-30,sx+30);
    nsy = (int)random(sy+5,sy+20);
  }
  
  strokeWeight(5);
  strokeCap(SQUARE);
  stroke(0,255,255,80);
  line(sx,sy,nsx,nsy);
  
  strokeWeight(3);
  strokeCap(SQUARE);
  stroke(0,255,255,120);
  line(sx,sy,nsx,nsy);
  
  strokeWeight(1);
  strokeCap(ROUND);
  stroke(255,255,255);
  line(sx,sy,nsx,nsy);

  if(nsy >= 0 && nsy <= height){
    lightning(nsx, nsy);
  }
  
}
 
void stop(){
  // Player in schließen
  input.close();
  // Minim Object stoppen
  minim.stop();
 
  super.stop();
}


// Source: http://code.compartmental.net/tools/minim/quickstart/
void frequencySpectrum() {

  // first perform a forward fft on one of song's buffers
  // I'm using the mix buffer
  //  but you can use any one you like
  fft.forward(input.mix);
 
  stroke(0, 255, 42, 128);
  strokeCap(SQUARE);
  // draw the spectrum as a series of vertical lines
  // I multiple the value of getBand by 4 
  // so that we can see the lines better
  strokeWeight(10);
  for(int i = 0; i < fft.specSize()*2; i = i+20)
  {
    line(i, height, i, height - fft.getBand(i)*20);
    line(i+3, height+5, i+3, height+5 - fft.getBand(i)*20);
  }
 
  stroke(255);
  // I draw the waveform by connecting 
  // neighbor values with a line. I multiply 
  // each of the values by 50 
  // because the values in the buffers are normalized
  // this means that they have values between -1 and 1. 
  // If we don't scale them up our waveform 
  // will look more or less like a straight line.
  strokeWeight(3);
  for(int i = 0; i < input.left.size() - 1; i++)
  {
    line(i, (screen_height/4)   + input.left.get(i)*100 , i+1, (screen_height/4) + input.left.get(i+1)*100);
    line(i, (screen_height/4*3) + input.right.get(i)*100, i+1, (screen_height/4*3) + input.right.get(i+1)*100);
  }

}

void drawCamera() {
   if(cam.available()) {
      cam.read();
    }
    image(cam, 0, 0, screen_width/2,screen_height/2);
    tint(random(255), random(255), random(255));  // Tint 
    
    image(cam, screen_width/2, 0, screen_width/2,screen_height/2);
    tint(random(255), random(255), random(255));  // Tint 
    
    image(cam, 0, screen_height/2, screen_width/2, screen_height/2);
    tint(random(255), random(255), random(255));  // Tint 
    
    image(cam, screen_width/2,screen_height/2, screen_width/2,screen_height/2);
    tint(random(255), random(255), random(255));  // Tint 
}

// display meta data
void displayMetaData()
{
  int metaY = 15;
  int yi = 40;
  
  textFont(f, screen_height/15);
  textAlign(CENTER, CENTER);
  text(meta.title() + "\nby " + meta.author(), screen_width / 2, screen_height / 2);
  
  //text("File Name: " + meta.fileName(), 5, metaY);
  //text("Length (in milliseconds): " + meta.length(), 5, metaY+=yi);
  //text("Title: " + meta.title(), 5, metaY+=yi);
  //text("Author: " + meta.author(), 5, metaY+=yi); 
  //text("Album: " + meta.album(), 5, metaY+=yi);
  //text("Date: " + meta.date(), 5, metaY+=yi);
  //text("Comment: " + meta.comment(), 5, metaY+=yi);
  //text("Track: " + meta.track(), 5, metaY+=yi);
  //text("Genre: " + meta.genre(), 5, metaY+=yi);
  //text("Copyright: " + meta.copyright(), 5, metaY+=yi);
  // text("Disc: " + meta.disc(), 5, metaY+=yi);
  //text("Composer: " + meta.composer(), 5, metaY+=yi);
  //text("Orchestra: " + meta.orchestra(), 5, metaY+=yi);
  //text("Publisher: " + meta.publisher(), 5, metaY+=yi);
  //text("Encoded: " + meta.encoded(), 5, metaY+=yi);
}
