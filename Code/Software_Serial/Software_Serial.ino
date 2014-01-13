//
//  Software_Serial.ino
//
//  Created by Mr. Gecko's Media (James Coleman) on 1/12/14.
//  No Copyright Claimed. Public Domain.
//

#include <SoftwareSerial.h>

SoftwareSerial btSerial(2,3);

void setup() {
  Serial.begin(9600);
  while (!Serial) {
    ;
  }
  
  Serial.println("Connected.");
  btSerial.begin(9600);
  btSerial.println("D\r");
}

void loop() {
  if (btSerial.available())
    Serial.write(btSerial.read());
  if (Serial.available())
    btSerial.write(Serial.read());
}
