//
//  Debug_Cable_Connection.ino
//
//  Created by Mr. Gecko's Media (James Coleman) on 1/12/14.
//  No Copyright Claimed. Public Domain.
//

int testPin = 2;
int lastValue = 1;

void setup() {
  Serial.begin(9600);
  pinMode(testPin, INPUT_PULLUP);
}

void loop() {
  int value = digitalRead(testPin);
  if (value!=lastValue) {
    Serial.print("Changed value ");
    Serial.print(value);
    Serial.print("\n");
    lastValue = value;
  }
}
