Rainbow Island CD-ROM BIOS Patch.

This patch will replace Rainbow Island's CDDA code, which directly talk to CD-ROM I/O, with CD-ROM BIOS calls.  It also writes SCSI/Internal CD boot IPL.  Once this patch is applied, the CD image can boot from the internal CD or SCSI CD with no help from Rescue IPL or Boot floppy disk.

This patch can be applied to .BIN/.MDF/.IMG.  May be able to patch ISO and then re-assemble with WAVs, but I haven't tested on ISO.

After applying the patch, you need to re-calculate EDC/ECC of the binary with a utility such as edcre.

The original version of edcre can be found at https://github.com/alex-free/edcre

The original version does not compile with Visual C++.  In case you are primarily using Visual C++, I made a fork that can be compiled with Visual C++ at https://github.com/captainys/edcre

Thanks nabe-abk (https://github.com/nabe-abk) for the file format of .EXP!  The executables were encrypted, and without appending patch-applier after the decryptor, I could not make it work.  Without his documentation, I could not append my code after the decryptor.


Just FYI, cddaplay.nsm is the patch I wrote.  It is appended to the tail of the executable RI.EXP


Usage:

(1) Compile patch to build patch.exe
(2) Run the following command (assuming the CD-image binary is RAINBOW.MDF):
  .\patch.exe RAINBOW.MDF
(4) If things go well, RAINBOW.MDF will be patched.




Rainbow Island CD-ROM BIOSパッチ

このパッチを適用することで、Rainbow IslandのCDDAコードを書き替えて、CD-ROM BIOSを使ってCDDAを演奏するようになります。元のコードはCD-ROM I/Oを直接攻撃しているので、SCSI CDから起動したとき、BGMが鳴りません。また、内蔵/SCSI共用ブートIPLを書き込むので、このパッチで作成したCD-ROMは、救難IPLや起動フロッピーを使わなくてもそのままSCSI CDドライブから起動できます。

このパッチは、.BINまたは.MDFまたは.IMGに適用することを想定しています。.ISOイメージにも使えるかもしれませんが、試してません。

なお、適用後、edcreなどのユーティリティを使って、EDC/ECCを再計算する必要があります。

オリジナルのedcreは、https://github.com/alex-free/edcre ここにあります。

ただし、オリジナルはVisual C++でコンパイルできないので、Visual C++をメインに使ってる人は、僕がVCでコンパイルできるように書き替えたforkを使ってください。https://github.com/captainys/edcre ここにあります。


なお、cddaplay.nsmがパッチ本体で、RI.EXPの末尾に追加されます。というか、最後のRETを削って追加。


使い方:

(1) patch.cをコンパイルしてpatch.exeをビルド。
(2) patch.exeを実行 (RAINBOW.MDFがイメージファイルと仮定):
  .\patch.exe RAINBOW.MDF
(4) うまくいけばRAINBOW.MDFにパッチが適用される。

Free386作者のnabe-abkさん(https://github.com/nabe-abk)がEXPファイルフォーマットを公開していただいたおかげでこのパッチが実現できました！実行ファイルは暗号化されていたので、複合コードの末尾にパッチ適用コードを追加する必要があったのですが、EXPファイルのフォーマットがわからなかったのでできずにいました！ありがとうございます！
