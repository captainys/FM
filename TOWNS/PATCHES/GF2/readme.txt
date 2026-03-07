Galaxy Force II for FM TOWNS CD-ROM BIOS Patch.

This patch replaces two of Galaxy Force II's functions.  Galaxy Foce II's malloc was assuming a specific version of DOS-Extender.  After this patch, it does not assume any specific version.  You can double-click GF2.EXP from any version of TOWNS OS to start the program.

Galaxy Force II uses CD-ROM I/O directly to read from CD sectors, which prevented it from running from SCSI CD drive.  This patch replaces the CD-reading function and make it run from SCSI CD drive.

It also injects Internal/SCSI dual boot IPL so that it can start from the internal CD drive (lucky you if you have one working!) or the external SCSI CD drive without help from Rescue IPL.  Well, the injected IPL is a special version of the Rescue IPL.

This patch can be applied to .BIN/.MDF/.IMG.  May be able to patch ISO and then re-assemble with WAVs, but I haven't tested on ISO.

After applying the patch, you need to re-calculate EDC/ECC of the binary with a utility such as edcre.

The original version of edcre can be found at https://github.com/alex-free/edcre

The original version does not compile with Visual C++.  In case you are primarily using Visual C++, I made a fork that can be compiled with Visual C++ at https://github.com/captainys/edcre

FYI, patch.nsm is the patch source code.


Usage:

(1) Compile patch to build patch.exe
(2) Run the following command (assuming the CD-image binary is GF2.MDF):
  .\patch.exe GF2.MDF




Galaxy Force II for FM TOWNS CD-ROM BIOSパッチ

このパッチは、FM TOWNS版Galaxy Force IIの実行ファイルの中のふたつの関数を置き換えます。ひとつは、mallocで、このmallocは特定のバージョンのDOS Extenderを前提としていますが、このパッチを適用した後は、どのバージョンでもよくなるので、例えばTowns OS V2.1 L51からGF2.EXPをダブルクリックすることで起動できるようになります。ただ、CDが無いとBGMがかからないのでHDインストールはできないんですが。

また、元の実行ファイルは、CD-ROM I/Oを直接攻撃してセクタの中身を読んでいます。このため、SCSI CDドライブから起動することができませんでした。が、このパッチはCD-ROM BIOSを使うように書き替えるので、SCSI CDドライブから実行できるようになります。

ついでに、内蔵/SCSI両起動用のIPLも書き込むので、救難IPLや起動フロッピーディスクに頼らなくてもSCSI CDドライブから直接起動できるようになります。というか、このパッチが書きこむIPLが救難IPLの特別版なわけですが。

このパッチは、.BINまたは.MDFまたは.IMGに適用することを想定しています。.ISOイメージにも使えるかもしれませんが、試してません。

なお、適用後、edcreなどのユーティリティを使って、EDC/ECCを再計算する必要があります。

オリジナルのedcreは、https://github.com/alex-free/edcre ここにあります。

ただし、オリジナルはVisual C++でコンパイルできないので、Visual C++をメインに使ってる人は、僕がVCでコンパイルできるように書き替えたforkを使ってください。https://github.com/captainys/edcre ここにあります。

なお、patch.nsmがソースです。


使い方:

(1) patch.cをコンパイルしてpatch.exeをビルド。
(2) patch.exeを実行 (GF2.MDFがイメージファイルと仮定):
  .\patch.exe GF2.MDF
