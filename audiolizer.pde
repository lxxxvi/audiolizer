// ---------------------------------------------------------------------- //
//                                                                        //
// Grundcode von einem Minim-Manual übernommen und dann weiterentwickelt  //
// http://lernprocessing.wordpress.com/2012/06/18/minim-audio-analyse/    //
// Meco 2014: Audio Visualizer                                            //
// ---------------------------------------------------------------------- //

import ddf.minim.*;
import ddf.minim.analysis.*;
import processing.video.*;

// Objekte erstellen
Minim minim;
AudioPlayer input;
BeatDetect beat;
Capture cam;

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

String audioFilePath = "";
 
 
void setup() {
    
  size(1024, 768);
  smooth();

  // user muss file auswaehlen
  selectInput("Select a file to process:", "fileSelected");

  // warte bis file ausgewaehlt ist
  while(audioFilePath == "") {
    delay(100);
  }
  
  // Konstruktor des Minim Objekts aufrufen
  minim = new Minim(this);
 
  // Einlesen der Musikdatei
  //input = minim.loadFile("Blitz.mp3");
  input = minim.loadFile(audioFilePath);
 
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
    audioFilePath = "";
    
  } else {
    audioFilePath = selection.getAbsolutePath();
    println("User selected " + audioFilePath);
  }
}

 
void draw() {
 
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
    line(lastX,lastY,x,y);

    strokeWeight(1);
    strokeCap(ROUND);
    stroke(colorR,255,255);
    
    line(lastX,lastY,x,y);
    line(lastX,lastY2+90,x,y2+90);
    line(lastX,lastY2-90,x,y2-90);

    lastX = x;
    lastY = y;
    lastY2 = y2;
    
    if(cam.available()) {
      cam.read();
    }
    image(cam, random(width),random(height));
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


