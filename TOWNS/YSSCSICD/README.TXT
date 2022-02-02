FM TOWNS Internal CDROM to SCSI CDROM Redirector Driver
by CaptainYS
http://www.ysflight.com



[Revisions]
V0.93 2022/02/02
  INT 93H AX=01C0H was not returning drive mode in DL.  Ms. Detective #1 was crashing due to this problem.
  The problem has been fixed.  I don't know if there were more of the 

V0.91 2020/01/04
  Now supports Operation Wolf.

  Fixed AH=54H (Read TOC).  When I was reading CDSD.SYS source, I understood that the total length returned
  must be the length returned from SCSI CD-ROM minus 2 seconds (150 frames).  I may have gotten it wrong,
  or CDSD.SYS was wrong, or it was for MSCDEX not for FM TOWNS CD-ROM BIOS after all.

  To make it compatible with FM TOWNS CD-ROM BIOS, I apparently shouldn't subtract 2 seconds.  Operation Wolf
  was checking the total length of the CD to make sure the original disc was in the drive, and this 2-second
  discrepancy was preventing it from starting.


V0.90 2019/12/31
  Supported INT 93H, AH=05H/15H, CH=0FFH, read sector to physical memory location.
  With this addition RAYXANBER can start from a boot floppy disk.

  Added original function AX=71C0H (Play CDDA) and AX=72C0H (Play CDDA BCD).  The usage is:
    INT 93H
    AX=71C0H or 72C0H
    BL Starting time M (In BCD if AH=72H)
    BH Starting time S (In BCD if AH=72H)
    CL Starting time F (In BCD if AH=72H)
    CH Ending time M (In BCD if AH=72H)
    DL Ending time S (In BCD if AH=72H)
    DH Ending time F (In BCD if AH=72H)

  This addition was needed for patching Puyo Puyo to enable CDDA BGM, and may be used for other titles in the future.

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

