# rotcup

This project demonstrates a method to compare muscle viscoelasticity measurements during specific actions using wearables and electromyography (EMG).
Overview

The project consists of two main parts:
1. Recording data from an Arduino device, including time, acceleration, and load information, and saving the data in .mat files.
2. Processing the recorded data to calculate the offset force and visualize the acceleration data against time. It also analyzes the data to extract specific features, such as zero-crossing indices (ZCI).

## Dependencies

To run this project, you will need the following Python libraries:

- numpy
- scipy
- matplotlib
- serial
- keyboard
- pylsl

You can install them using pip:

```bash
pip install numpy scipy matplotlib pyserial keyboard pylsl
```
## Usage

1. First, run the data recording Python script to collect the data from the Arduino device:

```bash
python data_recording.py [arduino_port] [name_of_the_file]
```

Replace [arduino_port] with the appropriate serial port for your Arduino device (e.g., COM5 or /dev/ttyACM0) and [name_of_the_file] with the desired filename for the output .mat file.

2. After recording the data, run the data processing Python script to process and visualize the data:

```bash
python data_processing.py
```

This script assumes that the data files are named "empty.mat", "pos2_flex.mat", and "pos3_flex.mat". You can modify the script to load your recorded data files.

3. The script will generate plots to visualize the acceleration and force data.