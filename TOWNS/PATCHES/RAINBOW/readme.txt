Rainbow Island YSSCSICD.SYS Patch

This patch will redirect CD-ROM I/O writes to CD-ROM BIOS calls, and Rainbow Island for FM TOWNS will play CDDA BGM from an external SCSI CD-ROM drive.  Without this patch, Rainbos Island can still start and play from an external SCSI CD-ROM drive, but it did not play CDDA BGM.

CDDAPlay will use an expanded function of YSSCSICD.SYS (AX=72C0H) therefore you need to install YSSCSICD.SYS in the boot disk to play CDDA BGM.

Thanks nabe-abk (https://github.com/nabe-abk) for the file format of .EXP!  The executables were encrypted, and without appending patch-applier after the decryptor, I could not make it work.  Without his documentation, I could not append my code after the decryptor.



Usage:

(1) Compile patch to build patch.exe
(2) Copy RI.EXP to the same directory as the patches from Rainbow Island for FM TOWNS CD-ROM..
(3) Run the following command:
  .\patch.exe RI.EXP RIPATCH.EXP
(4) If things go well, you get RIPATCH.EXP
(5) As far as I experimented, it can just be started from Towns OS V1.1 or V2.1 as:
Q:
RUN386 A:RIPATCH.EXP




Rainbow Island YSSCSICD.SYS用パッチ

このパッチを適用することで、Rainbow Islandを外付けCD-ROMドライブから実行したときCDDAによるBGMが再生できるようになる。パッチを適用しなくてもプレイだけは可能。

CDDAによるBGMはYSSCSICD.SYSの拡張機能(AX=72C0H)を使用するので、YSSCSICD.SYSを組み込まないとCDDAによるBGMは演奏されない。

使い方:

(1) patch.cをコンパイルしてpatch.exeをビルド。
(2) Rainbow IslandのCD-ROMからRI.EXPをパッチの実行ファイルと同じディレクトリにコピー。
(3) patch.exeを実行:
  .\patch.exe RI.EXP RIPATCH.EXP
(4) うまく行ってたらRIPATCH.EXPができているはず。
(5) 実験した限りでは、Towns OS V1.1からでもV2.1からでも実行できる模様。例えば次のようなバッチファイルを使う。
Q:
RUN386 A:\RIPATCH.EXP



Free386作者のnabe-abkさん(https://github.com/nabe-abk)がEXPファイルフォーマットを公開していただいたおかげでこのパッチが実現できました！実行ファイルは暗号化されていたので、複合コードの末尾にパッチ適用コードを追加する必要があったのですが、EXPファイルのフォーマットがわからなかったのでできずにいました！ありがとうございます！

