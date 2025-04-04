# Reflex Time Measurement Project

## Overview
This project is designed to measure the reflex time of a user in response to a visual stimulus. A LED lights up randomly between 1 to 5 seconds, and the user must press a button as quickly as possible. The system then measures and displays the time taken by the user to respond, in milliseconds. The procedure is repeated five times, and the system can display either the minimum or maximum reaction time based on user input.

## Project Structure
The project includes several VHDL modules that together form the reflex time measurement system:

- `fsm.vhd`: Implements the finite state machine for controlling the sequence of operations including LED control, button press detection, and display logic.
- `driver7seg.vhd`: Manages the 7-segment display outputs for showing times and results.
- `DeBouncer.vhd`: Debounces the button input to ensure accurate measurements and avoid false triggering.
- `Basys3_master.xdc`: Configuration file for pin assignments on the Basys3 FPGA board.

## Hardware Requirements
- **Basys3 FPGA Board**: The project is specifically designed for the Basys3 board.
- **LEDs and Buttons**: Standard onboard LEDs and buttons are used for interaction.
- **7-segment Display**: Used for displaying the reaction times and results.

## Getting Started
### Prerequisites
You need to have Xilinx Vivado installed to open, simulate, synthesize, and upload the VHDL code to the Basys3 FPGA board.

### Setup
1. Clone this repository to your local machine or download the source files.
2. Open the project in Vivado:
   - Create a new project in Vivado and include all VHDL files and the constraint file (`Basys3_master.xdc`).
3. Generate the bitstream and program the FPGA.

### Operation
1. Reset the system using the middle button to start the measurements.
2. Observe the LED: when it lights up, press the button as quickly as possible.
3. The time between the LED lighting up and the button press will be displayed on the 7-segment display.
4. After five trials, the display can show either the minimum or maximum reaction time based on the position of switch SW0:
   - **SW0 = '0'**: Minimum reaction time.
   - **SW0 = '1'**: Maximum reaction time.
5. Reset to start a new set of measurements.
