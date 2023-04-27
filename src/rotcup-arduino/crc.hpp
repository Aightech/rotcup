class CRC {
public:
  // Create a CRC lookup table to compute CRC16 fatser.
  // poly represent the coeficients use for the polynome of the CRC
  CRC(uint16_t poly = 0x1021) {
    for (int i = 0; i < 256; i++) m_crctable[i] = crchware(i, poly, 0);
  }

  // Generate the values for the CRC lookup table.
  uint16_t crchware(uint16_t data, uint16_t genpoly, uint16_t accum) {
    static int i;
    data <<= 8;
    for (i = 8; i > 0; i--) {
      if ((data ^ accum) & 0x8000)
        accum = (accum << 1) ^ genpoly;
      else
        accum <<= 1;
      data <<= 1;
    }
    return accum;
  }

  // Compute and return the CRC over the n first bytes of buf
  uint16_t compute(uint8_t *buf, int n) {
    m_crc_accumulator = 0;
    for (int i = 0; i < n; i++) CRC_check(buf[i]);
    return (m_crc_accumulator >> 8) | (m_crc_accumulator << 8);
  }
  // Function use in CRC computation
  void CRC_check(uint8_t data) {
    m_crc_accumulator = (m_crc_accumulator << 8) ^ m_crctable[(m_crc_accumulator >> 8) ^ data];
  };
  
private:
  uint16_t m_crctable[256];
  uint16_t m_crc_accumulator;
  uint16_t m_crc;
};