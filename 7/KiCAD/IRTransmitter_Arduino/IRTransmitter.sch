EESchema Schematic File Version 4
LIBS:IRTransmitter-cache
EELAYER 26 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 1
Title ""
Date ""
Rev ""
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L Transistor_BJT:BC337 Q1
U 1 1 5D23E875
P 4300 3300
F 0 "Q1" H 4491 3346 50  0000 L CNN
F 1 "BC33740TA" H 4491 3255 50  0000 L CNN
F 2 "Transistors:NPN_Transistor" H 4500 3225 50  0001 L CIN
F 3 "http://www.nxp.com/documents/data_sheet/BC817_BC817W_BC337.pdf" H 4300 3300 50  0001 L CNN
	1    4300 3300
	1    0    0    -1  
$EndComp
$Comp
L Device:LED D1
U 1 1 5D23EA04
P 2650 2800
F 0 "D1" H 2642 3016 50  0000 C CNN
F 1 "IR_VSLB3940" H 2642 2925 50  0000 C CNN
F 2 "LED_THT:LED_D5.0mm" H 2650 2800 50  0001 C CNN
F 3 "~" H 2650 2800 50  0001 C CNN
	1    2650 2800
	-1   0    0    -1  
$EndComp
$Comp
L Diode:BAW76 D4
U 1 1 5D23EA91
P 3800 3500
F 0 "D4" V 3846 3421 50  0000 R CNN
F 1 "BAW27" V 3755 3421 50  0000 R CNN
F 2 "Diode_THT:D_T-1_P10.16mm_Horizontal" H 3800 3325 50  0001 C CNN
F 3 "http://www.vishay.com/docs/85551/baw76.pdf" H 3800 3500 50  0001 C CNN
	1    3800 3500
	0    -1   -1   0   
$EndComp
$Comp
L Diode:BAW76 D5
U 1 1 5D23EAEF
P 3800 3850
F 0 "D5" V 3846 3771 50  0000 R CNN
F 1 "BAW27" V 3755 3771 50  0000 R CNN
F 2 "Diode_THT:D_T-1_P10.16mm_Horizontal" H 3800 3675 50  0001 C CNN
F 3 "http://www.vishay.com/docs/85551/baw76.pdf" H 3800 3850 50  0001 C CNN
	1    3800 3850
	0    -1   -1   0   
$EndComp
$Comp
L Device:LED D2
U 1 1 5D23EBC7
P 3200 2800
F 0 "D2" H 3191 3016 50  0000 C CNN
F 1 "IR_VSLB3940" H 3191 2925 50  0000 C CNN
F 2 "LED_THT:LED_D5.0mm" H 3200 2800 50  0001 C CNN
F 3 "~" H 3200 2800 50  0001 C CNN
	1    3200 2800
	-1   0    0    -1  
$EndComp
$Comp
L Device:LED D3
U 1 1 5D23ECDE
P 3400 3800
F 0 "D3" V 3345 3878 50  0000 L CNN
F 1 "LED" V 3436 3878 50  0000 L CNN
F 2 "LED_THT:LED_D5.0mm" H 3400 3800 50  0001 C CNN
F 3 "~" H 3400 3800 50  0001 C CNN
	1    3400 3800
	0    1    1    0   
$EndComp
$Comp
L Connector_Generic:Conn_01x04 J1
U 1 1 5D23EE15
P 2200 3300
F 0 "J1" H 2120 2975 50  0000 C CNN
F 1 "Arduino_Pin_8_9" H 2120 3066 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_1x04_P2.54mm_Vertical" H 2200 3300 50  0001 C CNN
F 3 "~" H 2200 3300 50  0001 C CNN
	1    2200 3300
	-1   0    0    1   
$EndComp
$Comp
L Connector_Generic:Conn_01x04 J2
U 1 1 5D23EEC9
P 2150 2150
F 0 "J2" H 2070 1825 50  0000 C CNN
F 1 "Arduino_Pin_5V_GND" H 2070 1916 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_1x04_P2.54mm_Vertical" H 2150 2150 50  0001 C CNN
F 3 "~" H 2150 2150 50  0001 C CNN
	1    2150 2150
	-1   0    0    1   
$EndComp
$Comp
L Device:R_US R1
U 1 1 5D23EFF6
P 3050 3300
F 0 "R1" V 2845 3300 50  0000 C CNN
F 1 "3.6K" V 2936 3300 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0414_L11.9mm_D4.5mm_P20.32mm_Horizontal" V 3090 3290 50  0001 C CNN
F 3 "~" H 3050 3300 50  0001 C CNN
	1    3050 3300
	0    1    1    0   
$EndComp
$Comp
L Device:R_US R2
U 1 1 5D23F083
P 4400 3750
F 0 "R2" H 4468 3796 50  0000 L CNN
F 1 "6.8" H 4468 3705 50  0000 L CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" V 4440 3740 50  0001 C CNN
F 3 "~" H 4400 3750 50  0001 C CNN
	1    4400 3750
	1    0    0    -1  
$EndComp
$Comp
L Device:C C1
U 1 1 5D23F1D3
P 3150 2200
F 0 "C1" H 3265 2246 50  0000 L CNN
F 1 "1uF" H 3265 2155 50  0000 L CNN
F 2 "Capacitor_THT:C_Disc_D4.3mm_W1.9mm_P5.00mm" H 3188 2050 50  0001 C CNN
F 3 "~" H 3150 2200 50  0001 C CNN
	1    3150 2200
	1    0    0    -1  
$EndComp
$Comp
L Device:R_US R3
U 1 1 5D23F264
P 3000 4050
F 0 "R3" V 2795 4050 50  0000 C CNN
F 1 "220" V 2886 4050 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" V 3040 4040 50  0001 C CNN
F 3 "~" H 3000 4050 50  0001 C CNN
	1    3000 4050
	0    1    1    0   
$EndComp
Wire Wire Line
	2350 2250 2900 2250
Wire Wire Line
	2350 2150 2500 2150
Text Label 2450 3400 0    50   ~ 0
P8
Text Label 2450 3300 0    50   ~ 0
P9
Wire Wire Line
	2800 2800 3050 2800
Wire Wire Line
	2300 2800 2500 2800
Wire Wire Line
	3350 2800 4400 2800
Wire Wire Line
	3200 3300 3800 3300
Wire Wire Line
	2400 3400 3400 3400
Text GLabel 3450 2050 2    50   Input ~ 0
GND
Text GLabel 3450 2350 2    50   Input ~ 0
+5V
Text GLabel 2300 2800 0    50   Input ~ 0
+5V
Wire Wire Line
	4400 2800 4400 3100
Wire Wire Line
	2400 3300 2900 3300
Wire Wire Line
	3400 3650 3400 3400
Wire Wire Line
	3400 3950 3400 4050
Wire Wire Line
	3400 4050 3150 4050
Text GLabel 2350 4050 0    50   Input ~ 0
+5V
Wire Wire Line
	2850 4050 2350 4050
Wire Wire Line
	4400 3600 4400 3500
Wire Wire Line
	3800 3300 3800 3350
Connection ~ 3800 3300
Wire Wire Line
	3800 3300 4100 3300
Wire Wire Line
	2900 2150 2900 2050
Wire Wire Line
	2900 2050 3150 2050
Wire Wire Line
	2900 2250 2900 2350
Wire Wire Line
	2900 2350 3150 2350
Wire Wire Line
	3150 2350 3450 2350
Connection ~ 3150 2350
Wire Wire Line
	3150 2050 3450 2050
Connection ~ 3150 2050
Text GLabel 4600 4050 2    50   Input ~ 0
GND
Wire Wire Line
	3800 3650 3800 3700
Wire Wire Line
	4600 4050 4400 4050
Wire Wire Line
	4400 4050 4400 3900
Wire Wire Line
	4400 4050 3800 4050
Wire Wire Line
	3800 4050 3800 4000
Connection ~ 4400 4050
Wire Wire Line
	2350 2050 2500 2050
Wire Wire Line
	2500 2050 2500 2150
Connection ~ 2500 2150
Wire Wire Line
	2500 2150 2900 2150
NoConn ~ 2350 1950
Wire Wire Line
	2400 3100 2650 3100
Wire Wire Line
	2400 3200 2650 3200
NoConn ~ 2650 3100
NoConn ~ 2650 3200
Text Label 2450 3200 0    50   ~ 0
P10
Text Label 2450 3100 0    50   ~ 0
P11
$EndSCHEMATC
