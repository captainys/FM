SYSDRV.EXE - Set System Drive for Fujitsu FM TOWNS
by CaptainYS
http://www.ysflight.com/FM/e.html  (English version)
http://www.ysflight.com/FM/j.html  (Japanese version)



FM TOWNS uses a secret I/O address 3C32H to remember from which drive it booted from.

Some of the FM TOWNS system processes look at this information for where to look for files.

If you boot from a floppy, but want to start a system from CD-ROM, since I/O address 3C32H remembers you booted from floppy disk drive, no matter what you do, you may not be able to start a program from CD-ROM stably.

This program let you re-assign starting drive so that FM TOWNS thinks you started from whichever drive you specify.  Do it at the first line of AUTOEXEC.BAT.



Usage:
SYSDRV
  No parameter will set system drive to Q:  (CD-ROM)
SYSDRV /D:H
  Set system drive to H:




FM TOWNSは、未公開I/O 3C32Hに起動ドライブ情報を記録します。

FM TOWNSのシステムプロセスのいくつかは、このI/Oアドレスを参照してどこのファイルを探すか決定します。

なので、フロッピーディスクから起動して、CD-ROMのTowns MENUを起動しようとしても、この情報が不完全のため、完全な形のTowns MENUが起動しません。

このプログラムはAUTOEXEC.BATの先頭で実行することで、任意のドライブを起動ドライブ扱いすることができます。



使用方法:
SYSDRV
  無パラメータだとQドライブ(CD-ROM)をシステムドライブとします。
SYSDRV /D:H
  Hドライブをシステムドライブとします。
