
//Wait for the modules to be available then read and store the values in arr
bool read_8hx(uint32_t *arr, int channels[], int n, int sclk) {
  //wait for the 8 modules to be ready (dout=0 for each module)
  int rdy = 0;
  for (int i = 0; i < n; i++)
    rdy += digitalRead(channels[i]);
  if (rdy != 0)
    return false;

  uint32_t values[n] = { 0 };

  //read 24 bits for each modules
  for (uint8_t i = 0; i < 24; i++) {
    digitalWrite(sclk, HIGH);
    for (int j = 0; j < n; j++) {
      values[j] |= (uint32_t)(digitalRead(channels[j])) << (23 - i);
    }
    digitalWrite(sclk, LOW);
  }


  // Send clock cycles to select the gain of following reading 1=128
  for (uint8_t i = 0; i < 1; i++) {
    digitalWrite(sclk, HIGH);
    digitalWrite(sclk, LOW);
  }

  for (uint8_t i = 0; i < n; i++) {
    arr[i] = 0;
    uint8_t d[3] = { (values[i] & 0xff), ((values[i] >> 8) & 0xff), ((values[i] >> 16) & 0xff) };

    uint8_t filler = 0x00;
    if (d[2] & 0x80)
      filler = 0xff;

    arr[i] = (static_cast<unsigned long>(filler) << 24
              | static_cast<unsigned long>(d[2]) << 16
              | static_cast<unsigned long>(d[1]) << 8
              | static_cast<unsigned long>(d[0]));
  }
  return true;
}