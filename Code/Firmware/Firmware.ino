//
//  Firmware.ino
//
//  Created by Mr. Gecko's Media (James Coleman) on 1/12/14.
//  No Copyright Claimed. Public Domain.
//

#include <SoftwareSerial.h>

SoftwareSerial btSerial(2,3); // RX,TX
int eventPin = 4;
int eventValue = 1;
int commandPin = 5;
int commandToggle = 0;

int hookPin = 6;
int hookValue = 1;
int startPosPin = 7;
int startPosValue = 1;
int rotaryPin = 8;
int rotaryValue = 1;
int dialedNumber = 0;
int phoneNumber[10] = {0,0,0,0,0,0,0,0,0,0};
int numberCount = 0;

int speakerShutOffPin = 9;

typedef enum {
	limbo = 0,
	connectable = 1,
	connectableAndDiscoverable = 2,
	connected = 3,
	outgoingCall = 4,
	incomingCall = 5,
	activeCallInProgress = 6,
	testMode = 7,
	threeWayWaiting = 8,
	threeWayHold = 9,
	threeWay = 10,
	incomingCallHold = 11,
	activeCall = 12,
	audioStreaming = 13,
	lowBattery = 14
} BTState;

int iAP = 0;
int SPP = 0;
int A2DP = 0;
int HFP = 0;
long state;

char *serialSend(const char *command) {
	// Send command.
	btSerial.write(command);
	
	// Get response.
	char *response = (char *)malloc(20);
	memset(response, '\0', sizeof(response));
	unsigned long startRead = millis();
	while (1) {
		if (btSerial.available()) {
			char byteRead = btSerial.read();
			// If we receive a end line, we received the response.
			if (strcmp(&byteRead,"\r")==0)
				continue;
			if (strcmp(&byteRead,"\n")==0)
				break;
			strcat(response, &byteRead);
			// We don't want a buffer overrun. The responses from the bluetooth board is usually 3 characters long.
			if (strlen(response)>=19)
				break;
		}
		// Insure there isn't a error in reading and this doesn't continue reading infinite.
		if ((millis()-startRead)>=1000)
			break;
	}
	return response;
}
int serialSendVerify(const char *command, const char *verify) {
	char *response = serialSend(command);
	int verified = (strcmp(response, verify)==0);
        free(response);
        return verified;
}

void getAndDecodeState() {
	char *stateHex = serialSend("Q\r");
	Serial.print("Response: ");
	Serial.print(stateHex);
	Serial.print("\n");
	
	long response = strtol(stateHex, NULL, 16);
	long status = response >> 8;
	state = response & 0x000F;
	
	iAP = status & 0x1;
	SPP = (status & 0x2) >> 1;
	A2DP = (status & 0x4) >> 2;
	HFP = (status & 0x8) >> 3;
	
	if (state==incomingCall) {
		digitalWrite(speakerShutOffPin, HIGH);
	} else if (state!=audioStreaming && state!=connected) {
		digitalWrite(speakerShutOffPin, LOW);
	}
	free(stateHex);
}

void setup() {
	// Setup Serial Interfaces.
	Serial.begin(9600);
	btSerial.begin(9600);
	
	// Setup Pins.
	pinMode(eventPin, INPUT);
	pinMode(commandPin, OUTPUT);
	digitalWrite(commandPin, LOW);
	commandToggle = 1;
	
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
	int event = digitalRead(eventPin);
	int eventChanged = (eventValue!=event);
	eventValue = event;
	
	int hook = digitalRead(hookPin);
	int hookChanged = (hookValue!=hook);
	hookValue = hook;
	
	int startPos = digitalRead(startPosPin);
	int startPosChanged = (startPosValue!=startPos);
	startPosValue = startPos;
	
	int rotary = digitalRead(rotaryPin);
	int rotaryChanged = (rotaryValue!=rotary);
	rotaryValue = rotary;
	
	if (eventChanged && event==0) {
		getAndDecodeState();
	}
	
	// Debug Code.
	if (hookChanged) {
		Serial.print("Hook: ");
		Serial.print(hook);
		Serial.print("\n");
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
	
	if (hookChanged) {
		if (hook==0) {
			memset(phoneNumber,0,sizeof(phoneNumber));
			numberCount = 0;
			if (state==audioStreaming) {
				serialSendVerify("AP\r", "AOK");
			} else if (state==outgoingCall || state==incomingCall || state==activeCallInProgress || state==threeWayWaiting || state==threeWayHold || state==threeWay || state==incomingCallHold || state==activeCall) {
				serialSendVerify("E\r", "AOK");
			}
		} else {
			if (state==incomingCall || state==incomingCallHold) {
				serialSendVerify("C\r", "AOK");
				digitalWrite(speakerShutOffPin, LOW);
			}
		}
		getAndDecodeState();
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
				if (state==audioStreaming) {
					if (dialedNumber==1) {
						serialSendVerify("AT+\r", "AOK");
					} else if (dialedNumber==2) {
						serialSendVerify("AT-\r", "AOK");
					} else if (dialedNumber==3) {
						serialSendVerify("AP\r", "AOK");
					} else if (dialedNumber==4) {
						digitalWrite(speakerShutOffPin, HIGH);
					} else if (dialedNumber==5) {
						digitalWrite(speakerShutOffPin, LOW);
					}
				} else if (hook==0) {
					if (dialedNumber==3) {
						serialSendVerify("AP\r", "AOK");
					} else if (dialedNumber==9) {
						if (commandToggle==1) {
							Serial.print("Command Mode Off\n");
							digitalWrite(commandPin, HIGH);
							commandToggle = 0;
						} else {
							Serial.print("Command Mode On\n");
							digitalWrite(commandPin, LOW);
							commandToggle = 1;
						}
					}
				} else if (hook==1 && state!=outgoingCall && state!=incomingCall && state!=activeCallInProgress && state!=threeWayWaiting && state!=threeWayHold && state!=threeWay && state!=incomingCallHold && state!=activeCall) {
					phoneNumber[numberCount] = dialedNumber;
					numberCount++;
					if (numberCount==10) {
						char *command = (char *)malloc(14);
						memset(command, '\0', sizeof(command));
						
						sprintf(command, "A,%d%d%d%d%d%d%d%d%d%d\r", phoneNumber[0], phoneNumber[1], phoneNumber[2], phoneNumber[3], phoneNumber[4], phoneNumber[5], phoneNumber[6], phoneNumber[7], phoneNumber[8], phoneNumber[9]);
						Serial.print(command);
						Serial.print("\n");
						
						serialSendVerify(command, "AOK");
						free(command);
						
						memset(phoneNumber,0,sizeof(phoneNumber));
						numberCount = 0;
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
