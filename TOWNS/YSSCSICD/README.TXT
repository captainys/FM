FM TOWNS Internal CDROM to SCSI CDROM Redirector Driver
by CaptainYS
http://www.ysflight.com



[Revision]
V0.87 2019/12/08
  I was forgetting to return BX and DX in AH=02H.
  Also since fix in V0.85, AL was not returned.  I think I fixed AL-not-returned problem all.

V0.85 2019/12/07
  Preserve AL.  Only update AH.
  Preserve CX unless return_AH==0x80.

V0.8 2019/12/05
  Integrated SYSINIW.EXE and SYSDRV.EXE with YSSCSICD.SYS

V0.7 2019/12/04
  Better (probably) emulation of unpublished functions 57H an 58H.

V0.6 2019/12/02
  Disabled CONFIG.SYS options.  Use ECHO command to enable/disable debug output.

V0.5 2019/11/27
  First success and first release!




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
  - Start and play Viewpoint
  - Start and play Bubble Bobble
  - Start and play Kyukyoku Tiger (Twin Cobra)
  - Start and play Wing Commander, but no BGM.
  - Start and play Rainbow Island, but no BGM.
  - Start and play CD_PLAY.EXP (TownsOS standard CD player)
  - Boot into Towns OS V2.1 L20 using a boot floppy disk. (GUI works perfectly)
  - Boot into Towns OS V2.1 L31 using a boot floppy disk. (GUI works perfectly)

Tested but not worked are:
  - Rayxanber



[Debugging Output]
In V0.5 you could specify options in DEVICE=YSSCSICD.SYS for enabling debug output.

But, I realized it is not safe when you don't have an RS232C connected to another computer because /R option will freeze the driver just waiting for TX Rdy. Therefore I disabled command options.

Instead, you can do:
  ECHO R > CPTYS_CD
for enabling RS232C debugging,
  ECHO V > CPTYS_CD
for enabling Console debugging,
  ECHO r > CPTYS_CD
for disabling RS232C debugging, and
  ECHO v > CPTYS_CD
for disabling Console debugging.

Don't do it in AUTOEXEC.BAT.  Enabling RS232C debugging without a computer receiving messages will freeze this driver.




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

