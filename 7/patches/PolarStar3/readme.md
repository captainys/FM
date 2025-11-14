# Polar Star III (Carry Lab) Joystick Patch
# ポーラースターIII (Carry Lab) ジョイスティック対応パッチ

## Introduction
With this patch, you can start the game and control your fighter with a joystick connected to the game port in the Carry Lab's masterpiece Polar Star III.

このパッチは、キャリーラボの名作、ポーラースターIIIをゲームポートに接続したジョイスティックに対応させます。



## Application
## 適用方法

Just concatenate the tape image polar3_patch.t77 included in this repository and the tape image of Polar Star III using any binary editor.

To start the game, start FM-7 with no disks inserted and the created tape image mounted, like by RS232C Tape BIOS redirector or you can convert T77 to WAV and record to a real tape, and type:
```
RUN""
```
and return key.

簡単に適用するには、同じディレクトリにあるpolar3_patch.t77とポーラースターIIIのテープイメージをバイナリエディタなどでつなげるだけです。

起動するには、ディスクを入れないでFM-7の電源を入れ、作成したテープイメージをマウントして(テープBIOSリダイレクタを使うとか、WAVに変換して本物のテープに録音するとか)、
```
RUN""
```
とタイプして、リターンキーを押します。



## Technical
## 解説

The source code is available in patch_tape.asm.  You can read it.  What was difficult was that Polar Star III used pretty much entire main RAM, and could not easily find where I could install the joystick reader code.

It turned out, the sub-CPU code was not used after it is transferred to sub-CPU memory space.  My patch applier transfers the coe to sub-CPU instead of Polar Star III main code, NOPPed the original sub-CPU transfer code, and placed the patch where the sub-CPU code was residing.

ソースは、patch_tape.asmにあるので、詳しくはそれを見てください。何が難しかったかって、ほとんどメインRAM全部使い切っているのでパッチの置き場が見つからなかったのですが、サブCPU用コードは転送してしまえばあとは使ってなかったので、ポーラースター3の代わりにパッチ適用プログラムがサブCPU空間への転送まで面倒を見て、もともとの転送コードをNOP化して、空いたサブCPUコードの領域にジョイスティック対応パッチを置くことで解決しました。