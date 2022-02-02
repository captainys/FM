FM TOWNS Rescue IPL
by CaptainYS
http://www.ysflight.com



[Revisions]
2022/02/02
  INT 93H AX=01C0H was not returning drive mode in DL.  Ms. Detective #1 was crashing due to this problem.
  The problem has been fixed.  I don't know if there were more of the 

2020/09/21
  Start.
  Exploring a possibility of developing a rescue boot loader for a TOWNS with a dead CD-ROM drive.
  The goal is to start the new boot loader from a floppy disk or a virtual SCSI hard drive, and then load a system on the external SCSI CD drive.
  So far succeeded in starting the IPL sector, and draw a test message on the screen.
