FM TOWNS Internal CDROM to SCSI CDROM Redirector Driver
by CaptainYS
http://www.ysflight.com



This device driver is for extending life of FM TOWNS unit with a broken internal CD-ROM drive.

You need a boot floppy disk or boot hard drive, but you have a good chance of running a CD-ROM game title from an external SCSI CD-ROM drive.

All you need to set up is to copy this YSSCSICD.SYS to the root directory of the boot floppy/partition and then add:

DEVICE=\YSSCSICD.SYS

in config.sys.

You don't even have to specify the SCSI ID.  I am assuming you connect only one SCSI CD-ROM drive in the chain.  If you have two, please disconnect one.  It automatically scans SCSI devices 0 to 7.  In FM TOWNS, 7 is supposed to be the host, but just in case, it scans 0 to 7.  When a CD-ROM or CD-R drive is found, this driver will use it.

If no SCSI CD-ROM drive is found, it will not do anything.



I have tested with:
  - FM TOWNS IIMX with a broken internal CD-ROM drive
  - Panasonic CW 7502 B SCSI CD-R drive

I've been able to:
  - Start and play Afterburner II
  - Start and play Splatter House
  - Start and play CD_PLAY.EXP (TownsOS standard CD player)





[Options]
DEVICE=\YSSCSICD.SYS /R
With /R option, the driver will send debugging information to RS232C.  19200bps, No parity, 1 stop bit.
You can see what commands are sent to the CD-ROM BIOS.

DEVICE=\YSSCSICD.SYS /V
With /V option, the driver will print debugging information to Console.

You can specify both.





[Build]
You need MASM and EXE2BIN.  Put them in a directory in PATH.  Then type:

.\FMBUILD.BAT





[Source Files]
All sources start with UT_ are unit test files.

UT_SCxxx.ASM are for testing more direct SCSI command.  

Other UT_xxxx.ASM are mostly for testing CD-ROM BIOS functionalities.





[How it works]
It redirects CD-ROM BIOS calls INT 93H AL=0C0H to SCSI BIOS calls.

It does something similar to CDSD.SYS and CDISC2.SYS, but it is much simpler.

And also it can detect CD change.

