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

FFT fft;
AudioMetaData meta;

// Variablen für den Farbwechsel
int colorR = 0;
boolean isWhite = false;
 
// Blitzvariablen
int nsx;
int nsy;

int x, y;
 
// Anzahl der Peaks
int grid=500;
 
// Abstand zwischen den Peaks
int spacing=3;
 
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
    
  size(screen_width, screen_height);
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
    println("Fenster wurde geschlosse oder user hat cancel gedrückt.");
    audioFilePath = null;
    
  } else {
    audioFilePath = selection;
    println("User selected " + audioFilePath.getAbsolutePath());
  }
}

 
void draw() {

  // Anzeige des Kamerabilds
  volumeCam();
  
  // für etwas Bewegunsunschärfe
  fill(0, 60);
  rect(-1, -1, width+1, height+1);
    
  beat.detect(input.mix);
 
  // Auslesen und speichern des Spektrums
  float[] buffer = input.mix.toArray();
 
  float lastX  = 0.0;
  float lastY  = 0.0;
  float lastY2 = 0.0;

  for (int i=1; i <= buffer.length; i+=buffer.length/grid) {
    float x  = map(i, 0, buffer.length, 0, width);
    float y  = map(buffer[i - 1] * yScale , -1, 1, 0, height) ;
    float y2 = map(buffer[i - 1] * yScale2, -1, 1, 0, height) ;

    // Farbwechsel von weiss zu grün/blau
    if(isWhite == true){
      strokeWeight(3);
      strokeCap(SQUARE);
      stroke(colorR--, 255, 255, 80);
  
      if(colorR == 0){
        isWhite = false;
      }
    // Farbwechsel von grün/blau zu weiss
    } else {
      strokeWeight(3);
      strokeCap(SQUARE);
      stroke(colorR++, 255, 255,80);
      
      if(colorR == 255){
        isWhite = true;
      }
    }  

    // Zeichnet Linien zwischen den Spektrumshöhen
    line(lastX + 10, lastY, x + 20,y);

    strokeWeight(2);
    strokeCap(ROUND);
    stroke(colorR, 255, 255);
    
    line(lastX, lastY      , x, y);
    line(lastX, lastY2 + 90, x, y2 + 90);
    line(lastX, lastY2 - 90, x, y2 - 90);

    lastX  = x;
    lastY  = y;
    lastY2 = y2;

  }

  // Beatabfrage
  if ( beat.isOnset() ){
    // Flasheffekt
    fill(255, 150);
    rect(-1, -1, width+1, height+1);

    // Zeichnet einen Blitz in der oberen Hälfte sowie einen in der unteren Hälfte des Bildschirms
    lightning((int) random(1024), height/2-90);
    lightning((int) random(1024), height/2+90);
  }

  // Anzeige des Liedtitels
  displayMetaData();

  // Frequenzspektren
  frequencySpectrum();   
  
}
 
void lightning(int sx, int sy){
  
  // Abfrage in welche Richtung der Blitz sich ausbreiten soll
  if(sy < height/2){
    nsx = (int) random(sx - 30, sx + 30);
    nsy = (int) random(sy - 5 , sy - 20);
  }else{
    nsx = (int) random(sx - 30, sx + 30);
    nsy = (int) random(sy + 5 , sy + 20);
  }
  
  strokeWeight(5);
  strokeCap(SQUARE);
  stroke(0, 255, 255, 80);
  line(sx, sy, nsx, nsy);
  
  strokeWeight(3);
  strokeCap(SQUARE);
  stroke(0, 255, 255, 120);
  line(sx, sy, nsx, nsy);
  
  strokeWeight(5);
  strokeCap(ROUND);
  stroke(255, 255, 255);
  line(sx, sy, nsx, nsy);

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


// Quelle: http://code.compartmental.net/tools/minim/quickstart/
void frequencySpectrum() {

  // Fast Fourier Transformation des Mix Kanals
  fft.forward(input.mix);
 
  stroke(255, 200, 0, 128);


  // Zeichnen des Spektrums
  for(int i = 0; i < fft.specSize() * 2 ; i = i+30)
  {
    strokeWeight(20);
    line(i, height, i, height - fft.getBand(i) * 40); // multiplikation mit 40, damit man's besser sieht
  }
 
  strokeWeight(2);
  stroke(255);
  // I draw the waveform by connecting 
  // neighbor values with a line. I multiply 
  // each of the values by 50 
  // because the values in the buffers are normalized
  // this means that they have values between -1 and 1. 
  // If we don't scale them up our waveform 
  // will look more or less like a straight line.
  for(int i = 0; i < input.left.size() - 1; i++)
  {
    line(i, (screen_height / 4) + input.left.get(i) * 100     , i + 1, (screen_height / 4) + input.left.get(i + 1) * 100);
    line(i, (screen_height / 4 * 3) + input.right.get(i) * 100, i + 1, (screen_height / 4 * 3) + input.right.get(i + 1) * 100);
  }

}

// display meta data
void displayMetaData()
{
  int metaY = 15;
  int yi = 40;
  
  textFont(f, screen_height/15);
  textAlign(CENTER, CENTER);

  if(meta.title() != "") {
    text(meta.title() + "\nby\n" + meta.author(), screen_width / 2, screen_height / 2);
  }

  // Alle Verfügbaren Werte
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
  //text("Disc: " + meta.disc(), 5, metaY+=yi);
  //text("Composer: " + meta.composer(), 5, metaY+=yi);
  //text("Orchestra: " + meta.orchestra(), 5, metaY+=yi);
  //text("Publisher: " + meta.publisher(), 5, metaY+=yi);
  //text("Encoded: " + meta.encoded(), 5, metaY+=yi);
}

void volumeCam() {

    fft.forward(input.mix); 
    
    if(cam.available()) {
      cam.read();
    }

    PImage currentImage = cam.get();
    int numberOfLines = 50;
   
    // Lautstärke, Wert Zwischen 0 - 100
    double volume = (input.mix.level()) * 400;
    
    for(int i = 0; i < numberOfLines; i++) {
  
       double delta = numberOfLines - i * 1.0;
      
       double threshold =  (delta / numberOfLines) * 100.0;
       //int division = (delta / numberOfLines);
       //println("delta : " + delta + " | numberOfLines : " + numberOfLines + " threshold : " + threshold + " volume : " + volume);

      if(volume > threshold) {
        PImage lineImage = currentImage.get(0, (240 / numberOfLines) * i, 320,  240 / numberOfLines);
        image(lineImage, 0, (height / numberOfLines) * i, width, height / numberOfLines);
        tint(random(255), random(255), random(255));  // Tint
      }
     
     
    }
    
}
