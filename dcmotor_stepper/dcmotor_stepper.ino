// Demo for the DC Motor Plug to use a stepper motor
// 2012-06-11 <jeenode@wd77.de>
// based on jcw's dcmotor_demo
// 2010-11-18 <jc@wippler.nl> http://opensource.org/licenses/mit-license.php

#include <JeeLib.h>

PortI2C myport (1 /*, PortI2C::KHZ400 */);
DeviceI2C expander (myport, 0x26);

enum {
  MCP_IODIR, MCP_IPOL, MCP_GPINTEN, MCP_DEFVAL, MCP_INTCON, 
  MCP_IOCON, MCP_GPPU, MCP_INTF, MCP_INTCAP, MCP_GPIO, MCP_OLAT
};

static void exp_setup () {
    expander.send();
    expander.write(MCP_IODIR);
    expander.write(0); // all outputs
    expander.stop();
}

static void exp_write (byte value) {
    expander.send();
    expander.write(MCP_GPIO);
    expander.write(value);
    expander.stop();
}
//==============
// fullstep
//==============
static void fstep_cw(int dlay) {
  exp_write(B00000101);  delay(dlay);
  exp_write(B00001001);  delay(dlay);
  exp_write(B00001010);  delay(dlay);
  exp_write(B00000110);  delay(dlay);
  exp_write(0x0);
}
static void fstep_ccw(int dlay) {
  exp_write(B00000110);  delay(dlay);
  exp_write(B00001010);  delay(dlay);
  exp_write(B00001001);  delay(dlay);
  exp_write(B00000101);  delay(dlay);
  exp_write(0x0);
}

//==============
// halfstep
//==============
static void hstep_cw(int dlay) {
  exp_write(B00000101);  delay(dlay);
  exp_write(B00000001);  delay(dlay);
  exp_write(B00001001);  delay(dlay);
  exp_write(B00001000);  delay(dlay);
  exp_write(B00001010);  delay(dlay);
  exp_write(B00000010);  delay(dlay);
  exp_write(B00000110);  delay(dlay);
  exp_write(B00000100);  delay(dlay);
  exp_write(0x0);
}
static void hstep_ccw(int dlay) {
  exp_write(B00000100);  delay(dlay);
  exp_write(B00000110);  delay(dlay);
  exp_write(B00000010);  delay(dlay);
  exp_write(B00001010);  delay(dlay);
  exp_write(B00001000);  delay(dlay);
  exp_write(B00001001);  delay(dlay);
  exp_write(B00000001);  delay(dlay);
  exp_write(B00000101);  delay(dlay);
  exp_write(0x0);
}

void setup () {
    Serial.begin(57600);
    Serial.println("\n[dcmotor_stepper]");
    Serial.println((int) expander.isPresent());
    exp_setup();
}

void loop () {
    Serial.println("\nHalfStep-Mode\n################");
    Serial.println("51 halfSteps clockwise");
    int i=0;
    while (i<51) {
     hstep_cw(8);
     i++;
    }
    delay(1000);
    Serial.println("51 halfSteps counter-clockwise");
    int j=0;
    while (j<51) {
     hstep_ccw(8);
     j++;
    }
    delay(2500);
    Serial.println("\nFullStep-Mode\n################");
    Serial.println("51 FullSteps clockwise");
    i=0;
    while (i<51) {
     fstep_cw(20);
     i++;
    }
    delay(1000);
    Serial.println("51 FullSteps counter-clockwise");
    j=0;
    while (j<51) {
     fstep_ccw(20);
     j++;
    }
    exp_write(0x0);
}
