#include <adc.h>
#include <display.h>
#include <fet.h>
#include <keypad.h>
#include <pressure.h>
#include <servos.h>
#include <temp.h>
#include <timer.h>
#include <ui.h>
#include <util.h>
#include <avr/io.h>  
// Datalogging variables
unsigned int samplePeriod = 1000; // length of time between samples (call to loop())
long unsigned int nextTime = 0;
int lines = 0;

void setup() {
  // timer initialization
  nextTime = millis() + samplePeriod;
  DoHeartBeatLED();
  delay(1);
  //Specify GCU: (version,fill,psequence)
  //version = V2 or V3 / 2.0 or 3.0
  //fill = FULLFILL | HALFFILL | LITEFILL / full, half, or lite fill boards
  //psequence: for V3.01 boards, check sequence of P sensor part numbers (e.g. MXP7007 or MXP7002, and use last digit). V3.02 boards use P777722:
  // P777222, P222777, P777722
  GCU_Setup(V3,FULLFILL,P777722);
  Disp_Init();
  Kpd_Init();
  UI_Init();
  ADC_Init();
  Temp_Init();
  Press_Init();
  Fet_Init();
  Servo_Init();
  Timer_Init();

  Disp_Reset();
  Kpd_Reset();
  UI_Reset();
  ADC_Reset();
  Temp_Reset();
  Press_Reset();
  Fet_Reset();
  Servo_Reset();
  Timer_Reset();

  Serial.begin(115200);
}

void loop() {
  int key;
  // first, read all KS's sensors
  Temp_ReadAll();  // reads into array Temp_Data[], in deg C
  Press_ReadAll(); // reads into array Press_Data[], in hPa
  Timer_ReadAll(); // reads pulse timer into Timer_Data, in RPM ??? XXX

// INSERT USER CONTROL CODE HERE
  if (millis() >= nextTime) {
    nextTime += samplePeriod;
    DoDatalogging();
  }
  
// END USER CONTROL CODE
  UI_DoScr();       // output the display screen data, 
                    // (default User Interface functions are in library KS/ui.c)
                    // XXX should be migrated out of library layer, up to sketch layer                      
  key = Kpd_GetKeyAsync();
                    // get key asynnchronous (doesn't wait for a keypress)
                    // returns -1 if no key

  UI_HandleKey(key);  // the other two thirds of the UI routines:
                      // given the key press (if any), then update the internal
                      //   User Interface data structures
                      // ALSO: Manipulate the various output data structures
                      //   based on the keypad input

  Fet_WriteAll();   // Write the FET output data to the PWM hardware
  Servo_WriteAll(); // Write the Futaba hobby servo data to the PWM hardware
        
  PORTJ ^= 0x80;    // toggle the heartbeat LED
  delay(10);
}

void LogTempInputs(boolean header = false) {
  if (header) {
      for (int i= 0; i<16; i++) {
        if (Temp_Available[i]) {
          PrintColumnHeader("T",i);
        }
      }
  } else {
    for (int i= 0; i<16; i++) {
      if (Temp_Available[i]) {
        PrintColumnInt(Temp_Data[i]);
      }
    }
  }
}

void LogPressureInputs(boolean header = false) {
  if (header) {
      for (int i= 0; i<6; i++) {
        if (Press_Available[i]) {
          PrintColumnHeader("P",i);
        }
      }
  } else {
    for (int i= 0; i<6; i++) {
      if (Press_Available[i]) {
        PrintColumnInt(Press_Data[i]);
      }
    }
  }
}

void LogAnalogInputs(boolean header = false) {
  if (header) {
    for (int i= 0; i<8; i++) {
      if (ANA_available[i] == 1) {
        PrintColumnHeader("ANA",i);
      }
    }
  } else {
    if (ANA_available[0] == 1) {
      PrintColumnInt(analogRead(ANA0));
    }
    if (ANA_available[1] == 1) {
      PrintColumnInt(analogRead(ANA1));
    }
    if (ANA_available[2] == 1) {
      PrintColumnInt(analogRead(ANA2));
    }
    if (ANA_available[3] == 1) {
      PrintColumnInt(analogRead(ANA3));
    }
    if (ANA_available[4] == 1) {
      PrintColumnInt(analogRead(ANA4));
    }
    if (ANA_available[5] == 1) {
      PrintColumnInt(analogRead(ANA5));
    }
    if (ANA_available[6] == 1) {
      PrintColumnInt(analogRead(ANA6));
    }
    if (ANA_available[7] == 1) {
      PrintColumnInt(analogRead(ANA7));
    }
  }
}

void LogTime(boolean header = false) {
  if (header) {
    PrintColumn("Time");
  } else {
    PrintColumnInt(millis()/100.0); // time since restart in deciseconds
  }
}


void PrintColumnHeader(String str,int n) {
   Serial.print(str);
   Serial.print(n);
   Serial.print(", ");  
}

void PrintColumn(float str) {
   Serial.print(str);
   Serial.print(", ");  
}

void PrintColumn(String str) {
   Serial.print(str);
   Serial.print(", "); 
} 

void PrintColumnInt(int str) {
   Serial.print(str);
   Serial.print(", ");  
}

void DoHeartBeatLED() {
  DDRJ |= 0x80;
  PORTJ |= 0x80;
}

void DoDatalogging() {
    boolean header;
    if (lines == 0) {
      header = true;
    } else {
      header = false;
    }
    // Serial output for datalogging
    LogTime(header);
    LogTempInputs(header);
    LogPressureInputs(header);
    LogAnalogInputs(header);
    Serial.print("\r\n"); // end of line
    lines++;
}
