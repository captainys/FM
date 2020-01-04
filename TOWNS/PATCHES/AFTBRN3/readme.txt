Afterburner 3 YSSCSICD.SYS Patch

Usage:

Compile patch.c, and apply patch as:

patch.exe AB3.EXP AB3PATCH.EXP

Or, if you run PATCH.EXP you can apply patch on FM TOWNS (real hardware or emulator).  AB3.EXP is the executable in the CD-ROM of Afterburner 3 for FM TOWNS.

The patched executable can run from Towns OS V1.1.  It most likely crash if you start from V2.1.

To run the patched executable, do the following:

run386 -callbufs 24 AB3PATCH.EXP

If you omit -callbufs 24, it will not have adequate buffer size for calling real-mode BIOS, and most likely crash in the middle.





使い方:

patch.cをコンパイル後、

patch.exe AB3.EXP AB3PATCH.EXP

としてパッチを当てる。あるいは、PATCH.EXPを使うとFM TOWNS上(実機でもエミュレータでも)でパッチを当てることができる。AB3.EXPはFM TOWNS用Afterburner 3のCD-ROM上の実行ファイル。

この実行ファイルはTowns OS V1.1から起動が可能。V2.1だと途中でクラッシュする可能性が高い。

実行は、

run386 -callbufs 24 AB3PATCH.EXP

のようにする。-callbufsオプションを省略するとCD-ROMを読み込むときのリアルモード呼び出し用バッファが足りなくてクラッシュする。

