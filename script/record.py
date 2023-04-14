import numpy as np
import serial
import sys
from scipy.io import savemat
import keyboard
import time 

from pylsl import StreamInlet, resolve_stream



#connect to the arduino
if len(sys.argv) < 2:
    print("Usage:")
    print("\t" + sys.argv[0] + " [arduino_port] [name of the file]")
    print("Ex:")
    print("\t" + sys.argv[0] + " COM5")
    exit()


#create a class CRC
class CRC:
    def __init__(self, poly = 0x1021):
        self.m_crctable = np.zeros(256, dtype=np.uint16)
        for i in range(256):
            self.m_crctable[i] = self.crchware(i, poly, 0)
        # accumulator as a 16 bit integer
        self.m_crc_accumulator = np.uint16(0)

    def crchware(self, data, genpoly, accum):
        data = np.uint16(data << 8)
        for i in range(8):
            if ((data ^ accum) & 0x8000):
                accum = np.uint16((accum << 1) ^ genpoly)
            else:
                accum = np.uint16(accum << 1)
            data = np.uint16(data << 1)
        return np.uint16(accum)

    def compute(self, buf, n):
        #see buff as a array of bytes
        buf = np.frombuffer(buf, dtype=np.uint8)
        self.m_crc_accumulator = np.uint16(0)
        for i in range(n):
            self.CRC_check(buf[i])
        return np.uint16((np.uint16(self.m_crc_accumulator) >> 8) | (np.uint16(self.m_crc_accumulator) << 8))

    def CRC_check(self, data):
        self.m_crc_accumulator = np.uint16((self.m_crc_accumulator << 8) ^ self.m_crctable[(self.m_crc_accumulator >> 8) ^ data])

# stream_name = "CleverHandStream"
# streams = resolve_stream('name', stream_name)
# if(len(streams)==0):
#     print("no stream found. Exit.")
#     exit(0)

# inlet = StreamInlet(streams[0])

    

#new CRC object
crc = CRC()
#connect to the arduino
with serial.Serial(sys.argv[1], 9600, timeout=3) as arduino:
    time.sleep(2)
    
    d=b'\x10'
    print("Press 'q' to quit ")
    
    dt = 0
    acc = np.zeros(3)
    load = np.zeros(2)

    # np array to store the data
    data = np.array([])
    # np array to store the time
    timestamp = np.array([])
    dt = 0

    # np array to store the EMGdata
    dataEMG = np.array([])
    # np array to store the EMGtime
    timestampEMG = np.array([])
    
    while(True):
        if keyboard.is_pressed('q'):
            break

        
        #sample, tsEMG = inlet.pull_chunk()
        # if(tsEMG):
        #     dataEMG = np.vstack((dataEMG, sample)) if dataEMG.size else np.array(sample)
        #     timestampEMG = np.concatenate((timestampEMG, tsEMG)) if timestampEMG.size else np.array(tsEMG)

        #send 1 byte to the arduino
        arduino.write(d)
        #Send position to the arduino and print in the terminal
        prev_dt=dt

        crc1 = 0
        crc2 = 1
        while crc1 != crc2:
            d = b'\x00'
            while d != b'\xaa':#read the first byte and check if it is the start byte 0xaa
                d = arduino.read(1) 
                if d == b'':#if the arduino is not sending data, send a byte to the arduino
                    arduino.write(b'\x10')
            d = arduino.read(24)#read the rest of the data
            crc1 = crc.compute(d, 22) # compute the crc of the data
            crc2 = int.from_bytes(d[22:24], "little") # read the crc from the data

        time_bytes = d[0:8]
        dt = int.from_bytes(time_bytes, "little")

        #read acceleration data
        for i in range(3):
            acc_bytes = d[8+2*i:8+2*(i+1)]
            acc[i] = int.from_bytes(acc_bytes, "little",signed="True")
        #read load data
        for i in range(2):
            load_bytes = d[14+4*i:14+4*(i+1)]
            load[i] = int.from_bytes(load_bytes, "little",signed="True")

            
        data = np.vstack((data, np.hstack((acc, load)))) if data.size else np.hstack((acc, load))
        timestamp = np.vstack((timestamp, dt)) if timestamp.size else np.array([dt])
        #print the time and data and come back to the beginning of the line
        print("\rTime: " + str(dt/1000000.) + " Acc: " + str(acc) + "\tLoad: " + str(load) + "\tEMG count: " + str(len(dataEMG)), end="                                  ")

print("\nSaving data...")
#close the serial port
time.sleep(2)
arduino.close()

dat = {'data':data, 'timestamp':timestamp}
name = sys.argv[2]+".mat"
savemat(name, dat)

dat = {'data':dataEMG, 'timestamp':timestampEMG}
name = sys.argv[2]+"EMG.mat"
savemat(name, dat)
