Raiden for FM TOWNS, Patch for starting from SCSI CD-ROM Drive

Instruction:

Compile and apply patch to R.EXE in the Raiden CD-ROM.

Modify Towns OS V1.1 boot floppy disk so that it changes the drive to Q and then starts the patched R.EXE in the floppy disk.

Or, you can run PATCH.EXP like:

run386 PATCH.EXP Q:\R.EXE A:\RPATCH.EXE

To make a patched executable in FM TOWNS (can be done in AUTOEXEC.BAT)



Reverse Engineering:

Oh my god!  R.EXE has its own CD-ROM BIOS in the executable!  Why did they waste it!?  Raiden's own CD-ROM BIOS takes exactly the same command set as FM TOWNS original CD-ROM BIOS.  What I had to do was to replace Raiden's own BIOS call to INT 93H (FM TOWNS's original CD-ROM BIOS).  It doesn't seem to working as a copy protection.  Did VING's programmers just want to explore more about FM TOWNS CD-ROM I/O then?

The patched R.EXe needs to run from Towns OS V1.1.  Unpatched version runs from Towns OS V2.1 if all the drivers are ripped, but the patched version destroys something while reading a file.  I located where the program is crashing, but it was just a plain fread and didn't seem to be doing anything special.  At this time, I cannot make it run from Towns OS V2.1.  Anyway Raiden crashes if drivers of Towns OS V2.1 is installed.  Therefore it requires restart.  Making it runnable from Towns OS V2.1 is not very meaningful.





雷電伝説 for FM TOWNS SCSI CD-ROM起動用パッチ

使い方:

patch.cをコンパイル&実行して雷電伝説のR.EXEにパッチを当てる。Towns OS V1.1用SCSI CD-ROM起動フロッピーディスクを修正して、Towns MENUの代わりにパッチを当てた実行ファイルを実行するように書き換える。

あるいは、PATCH.EXPを次のように実行することでFM TOWNS上でパッチを当てることも可能。

run386 PATCH.EXP Q:\R.EXE A:\RPATCH.EXE

AUTOEXEC.BATの中で実行することでフロッピーディスクから起動したタイミングでパッチを当てることも可能。



解析:

なんと! 雷電伝説実行ファイルR.EXEは中に独自のCD-ROM BIOSを持っていた。なんでそんなものをわざわざ書いたのか!?R.EXE独自CD-ROM BIOSはFM TOWNS標準CD-ROM BIOSと同じコマンドを受け付けるので、単に呼び出しをINT 93Hにリダイレクトするだけで良かった。コピープロテクションとしての意味があるようにも思えないし、VINGのプログラマーは単にFM TOWNSのCD-ROM I/Oをいじってみたかっただけだろうか?

なお、パッチを当てたR.EXEはTowns OS V1.1から起動する必要がある。パッチを当てていないバージョンだとドライバを何もインストールしていないTowns OS V2.1からの実行も可能だったけど、パッチを当てたバージョンはファイルの読み込みで何かを破壊してしまう模様(クラッシュしている箇所も特定したんだけど、普通のfreadみたいだった)。現時点ではTowns OS V2.1からの起動はできない。というか、どうせTowns OSのドライバが入っているとクラッシュするからがんばってV2.1から起動できるようにする意味はあまり無い。

