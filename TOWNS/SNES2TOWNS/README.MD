# SNES Controller to FM TOWNS Adapter / スーパーファミコンのコントローラをFM TOWNSに接続するアダプタ

by CaptainYS (http://www.ysflight.com)

## Introduction はじめに

This Arduino source code (SNES2TOWNS.ino) is for connecting a Super Nintendo (SNES) controller to FM TOWNS and use it as CAPCOM Power Stick Fighter (CPSF), or Fujitsu 6-button Game Pad, or FM TOWNS Game Pad (standard 2-button plus RUN and SELECT buttons).

The KiCAD schematic and PCB for Arduino NANO can be found in the directory one level up from here, then KiCAD/SNES2TOWNS.  I have tested it the schematic on a solderless breadboard, and confirmed to work with a CPSF with SNES adapter cable, and an original SNES controller, with my FM TOWNS 2MX.

6-button joystick works same way in X68K games, so I suppose it should work with X68K. I haven't confirmed yet though.

このArduinoソースコードは、スーパーファミコン用コントローラをFM TOWNS実機に接続して、CAPCOM Power Stick Fighter (CPSF), 富士通純正6ボタンゲームパッド, またはFM TOWNS用ゲームパッド(MSX用2ボタン＋RUN/SELECTボタン)として使うためのものです。

KiCAD用回路図とArduino NANO用PCBは、このドキュメントのひとつ上のディレクトリのKiCAD/SNES2TOWNSディレクトリにあります。このソースコードと回路図を使って、プロトタイプ用ブレッドボードでテストして、CPSF＋スーファミ用ケーブル、および、オリジナルのスーファミコントローラを実機FM TOWNS 2MXが認識できることを確認しました。

X68000の6ボタンジョイスティックも同様とのことなので、多分X68000実機でも使えると思いますが確認してません。


## Usage 使い方

First upload this Arduino program to your Arduino.  I you go with my PCB design, it would be NANO or NANO EVERY.  But, if you design a shield for your Arduino UNO, it should work fine, too.

Then, connect your Arduino to the board.  Beware of misalignment and careful about the orientation.

Then, select how FM TOWNS needs to see your SNES controller.  The board can present your game pad to FM TOWNS as (1) Fujitsu 6-button game pad, (2) CAPCOM CPSF, or (3) FM TOWNS Game Pad.  Select which one to go with the slide switch.

Then, connect your SNES game controller, and connect the converter to FM TOWNS, and you are good to go.

まず、このプログラムをArduinoにアップロードしてください。もしも、このレポジトリにあるPCBデザインそのまま使ったのであればArduino NANO Everyを使っていることと思います。が、ピンさえ間違えなければArduino UNO用にデザインを変更するのは簡単です。

次に、Arduinoを回路に接続してください。このとき、向きやズレに注意してください。

次に、スライドスイッチで、ゲームパッドをFM TOWNSが、富士通純正6ボタンパッドとして認識するか、CAPCOM CPSFとして認識するか、普通のTOWNSゲームパッドとして認識するか選んでください。

あとはつなげば使えます。


## Research 研究

I developed this SNES to FM TOWNS converter mainly to use my CAPCOM Power Stick Fighter joystick.  It had a 14-pin (something like D-SUB 15 minus pin 12) connector, so my initial guess was one button was assigned to one pin, and two pins are for +5V and GND.  

If my guess was correct, then all I needed to make was something like a schematic shown in the following URL.

Ref1 https://gamesx.com/wiki/doku.php?id=controls:x686button

By the way, I have positively confirmed that the bottom 74LS157's pins 2-3 and 5-6 are reversed in the schematic.  A button goes to pin 2, L to pin3, B to pin 5, and START to pin 6.  That way, when COM output is low, the joystick works just as a conventional 2-button joystick.

However, the explanation about CPSF I found in the following URL didn't really make sense.  What?  The FM TOWNS/X68K adapter used only five pins?  How come?

Ref2 https://yesterware.blogspot.com/2020/12/fm-towns-and-capcom-power-stick-fighter.html

By the way, the figure in the middle, has a critical mistake.  The figure is showing pin 12 is +5V, and pin 9 is GND.  But, pins 12 and 9 are opposite.  pin 12 is GND, and pin 9 is +5V.  It is clearly the author's mistake because the table at the bottom of the above blog post has correct pin assignments.  The picture in the middle was a mistake.

So what's clock and latch?  Then I talked to one of the most reliable guy about retro hardware, and he told me it's serial.  It needed a micro-controller to read button states.

If so, things made sense.  And, it was not like a asynchronous serial connection, it was rather an old-school shift register.  Therefore, it should not be timing sensitive, as long as I am not banging pulses too fast.

But, the bad news was I only had a CPSF to NES adapter cable.  Not a CPSF to SNES adapter cable.  But, the same guy told me there was a CPSF to SNES cable on eBay.  I bought it.  Now the problem was reduced to reading button states from a SNES controller, and then send to FM TOWNS via a 9-pin game port.

It was a two-part problem.  One was reading button states, and the other was sending signal to FM TOWNS.  To read button states, I needed to send a latch pulse to the latch pin, and then read one button state, send a pulse to clock pin, and repeat for 12 buttons.  Easily be done by an Arduino.  To send the button states to FM TOWNS, I just need a schematic shown in [ref1](https://gamesx.com/wiki/doku.php?id=controls:x686button).  Actually I have also verified the logic by reading disassembly of Super Street Fighter 2 for FM TOWNS while I was adding support for CPSF emulation in my [FM TOWNS Emulator Tsugaru](http://ysflight.in.coocan.jp/FM/towns/Tsugaru/e.html).

The original plan was to use my surplus Arduino UNO, but that raised a question.  Can FM TOWNS's game port supply enough current to drive Arduino UNO?  FM TOWNS's game port is compatible with a MSX game port.  The google search came back with all variety of answers.  My goal was to use my CPSF in this year's Demosplash (https://demosplash.org), but I didn't want to carry any more power source when I deply my FM computers.  So, just in case, I ordered Arduino NANO EVERY, which should consume less power.

While waiting for CPSF to SNES cable and Arduino NANO EVERY, I tested my design on a breadboard with my CPSF to NES cable.  The protocol should be the same.  It worked very well, except I could use only two buttons.  That's expected because NES only used two buttons.  According to [Ref2](https://yesterware.blogspot.com/2020/12/fm-towns-and-capcom-power-stick-fighter.html) I need to somehow short pins 11 and 13 of CPSF, which I could not come up with a solution.  Instead of destroying my CPSF, I waited until my CPSF to SNES cable arrived.  Only solution I could think of was to make a CPSF connector with 3D printer, but it would cost too much.

Also, FM TOWNS's game port was able to supply enough current to drive Arduino UNO.  Arduino NANO Every should be even easier.

Then finally, all cables, and parts arrived, and confirmed to work!



