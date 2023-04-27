#include <SparkFun_ADXL345.h>
#include <Servo.h>
#include "crc.hpp"
#include "HX711.hpp"


int32_t res[8] = { 0 };
int hx711_data_pin[2] = { 7, 6 };
int hx711_sclk_pin = 8;
ADXL345 adxl = ADXL345();

uint8_t buff[25] = {0xaa};//1 + 8 + 3 * 2 + 4 * 2 + 2
CRC crc;

void setup() {
  Serial.begin(9600);
  pinMode(hx711_sclk_pin, OUTPUT);  //clock pin
  for (int i = 0; i < 2; i++)
    pinMode(hx711_data_pin[i], INPUT_PULLUP);

  adxl.powerOn();  // Power on the ADXL345
  adxl.setRangeSetting(8);
  adxl.setFullResBit(true);
}

void loop() {

  if (Serial.available() >= 1) {
    char n = Serial.read();  //read the nb of col of the squre of value to read
    read_8hx((uint32_t *)(buff + 15), hx711_data_pin, 2, hx711_sclk_pin);
    ((uint64_t *)(buff+1))[0] = micros();
    adxl.readAccel((int *)(buff + 9));
    
    *((uint16_t*)(buff+23)) = crc.compute(buff+1, 22);//don't take the first byte for the crc
    Serial.write(buff, 25);
  }
}


