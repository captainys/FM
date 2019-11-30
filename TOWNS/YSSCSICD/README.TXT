FM TOWNS Internal CDROM to SCSI CDROM Redirector Driver
by CaptainYS
http://www.ysflight.com



This device driver is for extending life of FM TOWNS unit with a broken internal CD-ROM drive.

You need a boot floppy disk or boot hard drive, but you have a good chance of running a CD-ROM game title from an external SCSI CD-ROM drive.

All you need to set up is to copy this YSSCSICD.SYS to the root directory of the boot floppy/partition and then add:

DEVICE=\YSSCSICD.SYS

in config.sys.



I have tested with:
  - FM TOWNS IIMX with a broken internal CD-ROM drive
  - Panasonic CW 7502 B SCSI CD-R drive

I've been able to:
  - Start and play Afterburner II
  - Start and play Splatter House
  - Start and play CD_PLAY.EXP (TownsOS standard CD player)



