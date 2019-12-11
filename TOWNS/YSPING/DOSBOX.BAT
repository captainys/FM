COPY DOSBOXAUTORUN D:\DOSBoxDev\AUTORUN.BAT

DEL *.obj
DEL *.exe
DEL *.lst
"C:\Program Files (x86)\DOSBox-0.74-3\DOSBox.exe" -userconf

DEL D:\DOSBoxDev\AUTORUN.BAT

TYPE ERR.TXT
