// Modified Jeelabs Demo sketch for an LCD connected to I2C port via MCP23008 I/O expander 
// with added DS18B20 
#include <PortsLCD.h> 
#include <RF12.h> // needed to avoid a linker error :( 
#include <Ports.h> 
#include <OneWire.h> 
#include <DallasTemperature.h> //Version 3.6 
#include <avr/sleep.h>
#include <stdlib.h>
PortI2C myI2C (4); 
LiquidCrystalI2C lcd (myI2C); 
OneWire ds18b20 (14); // 1-wire temperature sensors, uses DIO port 4 
OneWire oneWire(ds18b20); // Setup a oneWire instance to communicate with any OneWire devices 
DallasTemperature sensors(&oneWire);// Pass our oneWire reference to Dallas Temperature. 
float temp;
DeviceAddress outsideThermometer = { 0x10, 0xAB, 0xD2, 0x01, 0x02, 0x08, 0x00, 0x34 }; 
float runningAvg; //was word type

byte radioIsOn;
int sendval;
MilliTimer readoutTimer,aliveTimer;


void setup() { 
 Serial.begin(57600);
 Serial.println(" ");
 Serial.println("[tempnode.3]");
 lcd.begin(16, 2);
 lcd.print("[tempnode.3]");
 rf12_config();
 sensors.begin();
 sensors.setResolution(outsideThermometer, 8); 
 sensors.requestTemperatures();
 temp=sensors.getTempC(outsideThermometer);
 lcd.setCursor(0,1);
 lcd.print(temp);
 runningAvg=21.0; //give reasonable startvalue
 runningAvg=(runningAvg+temp)/2;
 Serial.print("Number of sensors found:");
 Serial.println(sensors.getDeviceCount(),DEC);
 Serial.println();
 Serial.print(runningAvg,DEC);
 Serial.println();
 loseSomeTime(5000);
 sensors.requestTemperatures();
 temp=sensors.getTempC(outsideThermometer);
 runningAvg=(runningAvg+temp)/2;
 lcd.setCursor(0,1);
 lcd.print(temp);
 radioIsOn=1;
} 

static void lowPower(byte mode) {
    // disable the ADC
    byte prrSave = PRR, adcsraSave = ADCSRA;
    ADCSRA &= ~ bit(ADEN);
    PRR &= ~ bit(PRADC);
    // go into power down mode
    set_sleep_mode(mode);
    sleep_mode();
    // don't re-enable the ADC, we don't need it in this sketch
    //PRR = prrSave;
    //ADCSRA = adcsraSave;
}

static void loseSomeTime (word ms) {
    // only slow down for longer periods of time, as this is a bit inaccurate
    if (ms > 100) {
        word ticks = ms / 32 - 1;
        if (ticks > 127)    // careful about not overflowing as a signed byte
            ticks = 127;
        rf12_sleep(ticks);  // use the radio watchdog to bring us back to life
        lowPower(SLEEP_MODE_PWR_DOWN); // now we'll completely power down
        rf12_sleep(0);      // stop the radio watchdog again
        // adjust the milli ticks, since we've just missed lots of them
        extern volatile unsigned long timer0_millis;
        timer0_millis += 32U * ticks;
    }
}

void loop() { 
 lowPower(SLEEP_MODE_IDLE);
 sleep_mode();
 lcd.setCursor(0, 1); // col 0, line 1
 //keep easy_transmission going
 if (radioIsOn && rf12_easyPoll()==0) {
   rf12_sleep(0); //turn radio off
   radioIsOn=0;
 }
 // if we will wait for quite some time, go into total power down mode
 if (!radioIsOn)
     loseSomeTime(readoutTimer.remaining());
 //rf12_easyPoll();
 if (readoutTimer.poll(60000)) {
   sensors.requestTemperatures();
   //printTemperature(outsideThermometer);
   temp=sensors.getTempC(outsideThermometer);
   runningAvg=(3*runningAvg+(temp))/4;
   Serial.println(runningAvg,DEC);
   lcd.print(runningAvg);
   lcd.setCursor(6,1);
   lcd.print(temp);
   sendval=runningAvg*10;
   //dtostrf(runningAvg,3,1,sendval);
   char sending = rf12_easySend(&sendval, sizeof sendval); 
   if (aliveTimer.poll(120000))
     sending=rf12_easySend(0,0);
   if (sending) {
     rf12_sleep(-1);
     radioIsOn=1;
   }
 }
} 

void printTemperature(DeviceAddress deviceAddress) { 
 float tempC = sensors.getTempC(deviceAddress); 
 if (tempC == -127.00) { 
  Serial.print("Error"); 
 } else { 
  temp=tempC;
  //Serial.println(temp);
 } 
}
