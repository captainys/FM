TAITO Chase HQ for FM TOWNS  YSSCSICD.SYS Patch

This patch enables TAITO Chase HQ for FM TOWNS to start from external SCSI CD-ROM drive by redirecting CD-ROM I/O manipulations to CD-ROM BIOS.

CDDAPlay will use an expanded function of YSSCSICD.SYS (AX=72C0H) therefore you need to install YSSCSICD.SYS in the boot disk to play CDDA BGM.

Thanks nabe-abk (https://github.com/nabe-abk) for the file format of .EXP!  The executables were encrypted, and without appending patch-applier after the decryptor, I could not make it work.  Without his documentation, I could not append my code after the decryptor.

By the way, you don't need a boot floppy if you have a working hard-drive TownsOS installation.  I was able to start directly (without rebooting) from Towns OS V2.1 L31 GUI.



Usage:

(1) Compile patch.c and patch2.c to build patch.exe and patch2.exe.
(2) Copy LASINT.EXP and LASINT2.EXP to the same directory as the patches from TAITO Chase HQ for FM TOWNS CD-ROM..
(3) Run patch.exe, and then patch2.exe.  No parameters are needed.
(4) If things go well, you get LASINTP.EXP and LASINT2P.EXP.
(5) Copy LASINTP.EXP and LASINT2P.EXP to a Towns OS SCSI CD Boot floppy disk.
(6) Use the following AUTOEXEC.BAT



Q:
RUN386 SYS
IF ERRORLEVEL 1 GOTO NORMAL
:LABEL
RUN386 A:LASINTP
RUN386 ENDING
GOTO LABEL

:NORMAL
RUN386 A:LASINT2P
GOTO NORMAL





TAITO Chase HQ for FM TOWNS YSSCSICD.SYS対応パッチ

このパッチを適用することで、FM TOWNS版TAITO Chase HQを外付けCD-ROMドライブから実行できるようになる。

CDDAによるBGMはYSSCSICD.SYSの拡張機能(AX=72C0H)を使用するので、YSSCSICD.SYSを組み込まないとCDDAによるBGMは演奏されない。

ハードディスクからTowns OSが起動可能であれば起動フロッピーディスクを使わなくてもGUIから直接起動できる模様。Towns OS V2.1 L31 GUIから普通に起動できた。

使い方:

(1) patch.c, patch2.cをコンパイルしてpatch.exeとpatch2.exeをビルド。
(2) LASINT.EXPとLASINT2.EXPをTAITO Chase HQのCD-ROMからパッチの実行ファイルと同じディレクトリにコピー。
(3) patch.exeとpatch2.exeを順に実行。順番は逆でもいいけど。
(4) うまく行ってたらLASINTP.EXPとLASINT2P.EXPができているはず。
(5) 作成したLASINTP.EXPとLASINT2P.EXPをTowns OS SCSI CD起動フロッピーディスクにコピー。
(7) 上に書いたようなAUTOEXEC.BATを使って起動。



Free386作者のnabe-abkさん(https://github.com/nabe-abk)がEXPファイルフォーマットを公開していただいたおかげでこのパッチが実現できました！実行ファイルは暗号化されていたので、複合コードの末尾にパッチ適用コードを追加する必要があったのですが、EXPファイルのフォーマットがわからなかったのでできずにいました！ありがとうございます！

