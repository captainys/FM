Kyukyoku Tiger. for FM TOWNS CD-ROM BIOS Patch

This patch is to run Kyukyoku Tiger for FM TOWNS on a real FM TOWNS hardware from an external CD drive using YSSCSICD.SYS or Rescue IPL.

If you only run this game in an emulator, you do not need this patch.

Kyukyoku Tiger for FM TOWNS directly writes to CD-ROM I/O to play CDDA BGM.  This patch modifies that part of the code of KTIGER.EXP and forces them to use CD-ROM BIOS.  CD-ROM BIOS can be interecepted and re-interpreted to SCSI commands by YSSCSICD.YS and Rescue IPL.  Therefore, the game becomes playable with music from an external CD drive.

Compile this patch with a C compiler, and apply the patch to a BIN, IMG, or MDF file.  Before writing back to a CD-R, CRC and error correction code need to be re-calculated.  I have confirmed that edcre (https://github.com/alex-free/edcre) works.  But, the original edcre uses UNIX-standard library, and cannot be compiled by Visual C++.  So, I made a fork that you can compile with Visual C++ in https://github.com/captainys/edcre

If you are interested, the source file is also available here.  The game executable first self-uncompress the binary, and then jump to the real entry point.  Only timing I could find to patch the code was after uncompressing and before jumping to the real entry point.  This patch extends the executable by 256 bytes, and inserts the patch-application code at the end of the uncompressor.
