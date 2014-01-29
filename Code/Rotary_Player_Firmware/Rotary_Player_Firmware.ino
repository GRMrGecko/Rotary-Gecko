//
//  Rotary_Player_Firmware.ino
//
//  Created by Mr. Gecko's Media (James Coleman) on 1/28/14.
//  No Copyright Claimed. Public Domain.
//

#include <SoftwareSerial.h>

SoftwareSerial btSerial(2,3); // RX,TX
int eventPin = 4;
int eventValue = 1;
int commandPin = 5;

int hookPin = 6;
int hookValue = 1;
int startPosPin = 7;
int startPosValue = 1;
int rotaryPin = 8;
int rotaryValue = 1;
int dialedNumber = 0;

int speakerShutOffPin = 9;
int speakerShutOffToggle = 0;

void setup() {
	// Setup Serial Interfaces.
	Serial.begin(9600);
	btSerial.begin(9600);
	
	// Setup Pins.
	pinMode(eventPin, INPUT);
	pinMode(commandPin, OUTPUT);
	digitalWrite(commandPin, HIGH);
	
	pinMode(hookPin, INPUT_PULLUP);
	pinMode(startPosPin, INPUT_PULLUP);
	pinMode(rotaryPin, INPUT_PULLUP);
	pinMode(speakerShutOffPin, OUTPUT);
	
	// Allow for RN-52 to play startup tone.
	digitalWrite(speakerShutOffPin, HIGH);
	delay(1000);
	digitalWrite(speakerShutOffPin, LOW);
}

void loop() {
	if (btSerial.available())
		Serial.write(btSerial.read());
	if (Serial.available()) {
		btSerial.write(Serial.read());
	}
	
	// Gather information from the pins to work with.
	int hook = digitalRead(hookPin);
	int hookChanged = (hookValue!=hook);
	hookValue = hook;
	
	int startPos = digitalRead(startPosPin);
	int startPosChanged = (startPosValue!=startPos);
	startPosValue = startPos;
	
	int rotary = digitalRead(rotaryPin);
	int rotaryChanged = (rotaryValue!=rotary);
	rotaryValue = rotary;
	
	// Debug Code.
	if (hookChanged) {
		Serial.print("Hook: ");
		Serial.print(hook);
		Serial.print("\n");
		btSerial.print("Hook: ");
		btSerial.print(hook);
		btSerial.print("\n");
	}
	if (startPosChanged) {
		Serial.print("Start Position: ");
		Serial.print(startPos);
		Serial.print("\n");
	}
	if (rotaryChanged) {
		Serial.print("Rotary: ");
		Serial.print(rotary);
		Serial.print("\n");
	}
	
	if (startPosChanged) {
		if (startPos==0) {
			dialedNumber = 0;
		} else {
			if (dialedNumber!=0) {
				if (dialedNumber>=10)
					dialedNumber = 0;
				Serial.print("Dialed: ");
				Serial.print(dialedNumber);
				Serial.print("\n");
				btSerial.print("Dialed: ");
				btSerial.print(dialedNumber);
				btSerial.print("\n");
				if (dialedNumber==0) {
					if (speakerShutOffToggle==0) {
						speakerShutOffToggle = 1;
						digitalWrite(speakerShutOffPin, HIGH);
					} else {
						speakerShutOffToggle = 0;
						digitalWrite(speakerShutOffPin, LOW);
					}
				}
			}
		}
	}
	if (startPos==0 && rotaryChanged && rotary==0) {
		dialedNumber++;
		delay(50);
	}
}
