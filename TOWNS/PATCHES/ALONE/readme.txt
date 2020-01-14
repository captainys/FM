Alone In The Dark   Patch for Playing BGM from SCSI CD-ROM

Alone In The Dark for FM OTWNS can start from an external SCSI CD-ROM drive using YSSCSICD.SYS if the internal drive is broken.  However, it doesn't play CDDA BGM.

After applying this patch to INDARK.EXP, you can start Alone In The Dark from an external SCSI CD-ROM drive, and it plays CDDA BGM.


Usage:
  patch.exe input.exp output.exp

Please use any C compiler to compile patch.c to build patch.exe.

input.exp is INDARK.EXP in the Alone In The Dark for FM TOWNS CD-ROM.  Output.exp can be something like INDARKP.EXP.


Starting the Game:

Boot into Towns OS V2.1.  The easiest way is to use SCSI CD-ROM Boot floppy disk.  Then, run it from a batch file like:

Q:
CD ALONE
RUN386 A:INDARKP.EXP

If your INDEARKP.EXP is not in A drive, modify it accoringly.





アローン・イン・ザ・ダーク FM TOWNS版 SCSI CD-ROMからBGM再生パッチ

アローン・イン・ザ・ダーク FM TOWNS版は、内蔵CDドライブが既に故障している場合YSSCSICD.SYSを使うことで外付けSCSI CD-ROMドライブから起動できる。しかし、CDDAによるBGMは再生されない。

このパッチを適用することで、YSSCSICD.SYSを利用して外付けCD-ROMドライブからアローン・イン・ザ・ダーク FM TOWNS版を起動した場合でもCDDAによるBGMが再生されるようになる。


使用方法:
  patch.exe input.exp output.exp

patch.cを適当なCコンパイラでコンパイルしてpatch.exeをビルドする。

input.expはゲームのCD-ROMドライブのINDARK.EXP。output.expは例えばINDARKP.EXPのようにする。


ゲームの開始:

まずTowns OS V2.1を起動する。簡単なのはアローン・イン・ザ・ダークのCD-ROMとV2.1起動フロッピーディスクを使う方法。その後、次のようなバッチファイルでゲームを起動。

Q:
CD ALONE
RUN386 A:INDARKP.EXP

パッチを適用したINDARKP.EXPがAドライブ以外にある場合は A: を適当に置き換える。

