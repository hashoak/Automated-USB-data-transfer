#include <SPI.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

#define SCREEN_WIDTH 128  // Display width, in pixles
#define SCREEN_HEIGHT 32  // Display height, in pixles

#define OLED_RESET -1        // Reset pin # (or -1 if sharing Arduino reset pin)
#define SCREEN_ADDRESS 0x3C  // See datasheet for Address; 0x3D for 128x64, 0x3C for 128x32
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

int relay[4] = { 2, 3, 4, 5 };  // Pin numbers of relays
int buzzpin = 9;                // Pin number of buzzer
int potpin = A6;                // Pin number of potentiometer

int maxTime = 30;     // Maximum time limit for potentiometer, in minutes
int changeTime = 10;  // Remove USB interval, in seconds
int buzzTime = 500;   // Buzzer on time, in milliseconds
int buzzFreq = 750;   // Buzzer frequency, in Hz

void setup() {
  Serial.begin(9600);

  // Initializing display...
  while (!display.begin(SSD1306_SWITCHCAPVCC, SCREEN_ADDRESS))
    Serial.println(F("SSD1306 allocation failed..."));
  Serial.println("hello");
  display.clearDisplay();
  display.setTextColor(SSD1306_WHITE);
  display.cp437(true);
  display.setCursor(0, 0);
  display.setTextSize(1);
  display.println("Initializing...");
  display.display();

  // Initializing pin modes...
  pinMode(relay[0], OUTPUT);
  pinMode(relay[1], OUTPUT);
  pinMode(relay[2], OUTPUT);
  pinMode(relay[3], OUTPUT);
  pinMode(buzzpin, OUTPUT);
  pinMode(potpin, INPUT);
}

int potval = 0;
int state = 0;
int time = 0;

void loop() {
  // Set time according to potentiometer setting...
  time = setOrRemove();
  
  // Set states of relays...
  digitalWrite(relay[0], state);
  digitalWrite(relay[1], state);
  digitalWrite(relay[2], state);
  digitalWrite(relay[3], state);

  doNotRemove(time * 60);
  state = !state;  // Toggle state
}

void doNotRemove(int time)  // Function to display progress
{
  display.clearDisplay();
  display.setCursor(0, 0);
  display.setTextSize(1);
  display.println("Do not remove USB...\n");
  display.print("Now connected to PC");
  display.println(1 + state);
  display.display();
  delay(5000);
  time -= 5;
  while (time) {
    display.clearDisplay();
    display.setCursor(0, 8);
    display.setTextSize(2);
    display.print("Time:");
    display.print(time--);
    display.println("s");
    display.display();
    delay(1000);
  }
}

int setOrRemove(void)  // Function to alert remove USB interval
{
  tone(buzzpin, buzzFreq, buzzTime);
  display.clearDisplay();
  display.setCursor(0, 0);
  display.setTextSize(2);
  display.print("Remove USB\nor...");
  display.display();
  delay(5000);
  unsigned long start = millis();
  int read = 0;
  while (millis() - start < changeTime * 1000) {
    read = max(1, int((maxTime + 1) * (analogRead(potpin) / 2048.0))) * 2;
    display.clearDisplay();
    display.setCursor(0, 0);
    display.println("Set time:");
    display.print(read);
    display.println("min");
    display.display();
  }
  return read;
}
