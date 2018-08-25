# 8051_ComandExec_USB_LCD_ADC
The project is for the beginners/intermediates who seek core underestanding of microcontroller principles: such as interfacing a single low-end CMOS 8051 micro-chip with some peripherals: where all working together as a system.

Project descriptions:

-=============================================================-
Interfacing an 8-bit ADC, a USB 2 port, a 16*2 LCD and a temperature sensor (for just an idea of interfacing any sensor) that will keep monitoring and storing data at every 2 seconds time gap (by default) until it is not instructed to change intervals. This device has some commands-execution feature that allows a user to sit in front of a computer and have control from back to perform commands. The device performs 2 types of commands.

1. It sends the stored temperature log to the connected computer via USB port whenever it is instructed.
2. It changes its temperature monitoring time gaps form 1 to 10 seconds when instructed.
++++++++++++++
As soon as the system has command from the computer, it will send an acknowledgement as “COMMAND ACCEPTED” for correct command and “WRONG COMMAND!” for every incorrect command input. If command is correct system will start executing that command immediately. When execution is finished, will go back to the process of monitoring and storing data. In this way user can get a set of data for a certain time gap which he wants to observe. And will be able to identify the certain changes in data/values.
++++++++++++++
The device also performs some measure to stop getting exhausted by frequent commands. It stops user to send any further commands until a '#' sign appears on the connnected computer screen. # means device is connected and ready to take commands.

=============================== [Step by step working description] =========================

1. LCD will start first and show a ready status.
2. If device is connected to the computer, an acknowledgement will be sent to the computer via USB.
3. By default, device will start monitoring and storing the temperature in every two seconds time gap.
4. Any data logging interval between 1~10 seconds can be given as command to the processor from computer.
5. Temperature log can be viewed any time on the computer screen by giving command to the device from computer.
6. If any command is given, controller will send an acknowledgement to the user for each case.
7. If command is correct, controller will display that command on LCD then starts executing it.
8. Until one command is processed, controller will not allow any command in between.
9. All commands must starts with ‘>’ sign and controller will acknowledge on the computer screen by showing ‘#’ sign that it is ready to
take command. User has to wait till ‘#’sign appears.
N.B. One thing has to keep in mind that every command must starts with a ‘>’ sign and should end with an Enter. Otherwise command will not to be granted by the device.

============== [Commands] ============================
>log - sends a log from its memory in a set of 16 to the computer.
>t01 ~ >t10 - sets the time interval of reading sensor.


---------------------
[25-Aug-18]


