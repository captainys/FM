Rocket Ranger for FM TOWNS BGM bug-fix Patch by CaptainYS


Introduction

ロケットレンジャーは、ゲーム史に名を残すべき傑作ゲームであり、FM TOWNSに移植されたことはFM TOWNSユーザーとしては非常に喜ぶべきことだと思ってますが、残念ながらFM TOWNS版はバグってます。



1. 高速モードだとオープニングでクラッシュする。
高速モードでロケットレンジャーを起動した場合、オープニングBGMに対して動画が速く進み過ぎる結果、まだ最初のBGMが終わってないのに、メインテーマのBGMをロードしようとしてクラッシュします。

ところが、クラッシュに寄ってPICのIn-Service Registerが立ったままの状態になるため、奇跡的にBGM無しでゲームは進行します。

このバグを知らなかった僕は、199x年当時 (多分1993年だったと思う)、「ロケットレンジャーはBGMも無くて静かなゲームだなあ」と思った記憶があります。

し・か・し！

ロケットレンジャーがゲーム史に名を残すべき理由のひとつは、ゲームミュージック史上相当上位に食い込むと思われる秀逸なBGMにあります。なんと、僕は、ロケットレンジャーにそんな優れたBGMがついていたことを2025年まで知りませんでした。

だから、他にもFM TOWNS II HR以降を使ってた人でロケットレンジャーやったけどBGMの存在を知らないままだったという人がいるかもしれません。そういう人は、今からでもロケットレンジャーのCDイメージにこのパッチを適用してFM TOWNS実機あるいはFM TOWNSエミュレータ津軽を使ってプレイしてみましょう。このパッチを当てると高速モードでも上の問題が発生しないので、非常に印象的なBGMを聞くことができます。



2. Fort DixのBGMが初回しか鳴らない
Amiga版だと、Fort Dixに戻るたびにFort Dixのテーマ曲が流れるのですが、TOWNS版はなぜかゲームを起動してオープニングが終わった直後の一度しか鳴りません。このパッチを当てると、Fort Dixに戻るたびにテーマ曲が流れるようになります。



3. ラスボス戦の背景が無い
Amiga版では、ラスボス戦で、背景にタイムトンネルみたいなのが表示されますが、TOWNS版だとただの黒い背景です。

実はTOWNS版にもタイムトンネルみたいな背景画像はあって、ラスボス戦開始直後の1フレームだけ見えます。

このパッチを当てると、ラスボス戦の背景が見えるようになります。残念ながらAmiga版のようなパレットアニメーションはありません。



4. ジェーンと博士を救出に向かって自分も捕まったシーン
尋問を受けるシーンで、選択肢を間違えると、何の説明もないまま、目的地選択 or SOS信号発信画面に飛ばされます。捕まって尋問を受けてたはずなのに、普通にロケットパックで次の目的地に飛べるのは明らかにおかしいバグです。

この途中に何があったのか、そのストーリーを表示するテキストがなぜか表示されないというバグがあります。どうも、メッセージIDだけEAXレジスタにセットして、メッセージを表示する関数を呼ぶのを忘れたようです。

このパッチにより、その場面のストーリーのテキストを読めるようになります。

ただ、テキストを見ても、捕虜収容所を脱走したまではいいとして、どうやってロケットパックを奪還したのかの説明が無いので、ここはちょっとストーリーの連続性が欠けてるんですが。





でも、このゲーム離陸が難し過ぎたよね。



Rocket Ranger is one of the games that should be permanently remembered as a game that impacted the history of the video game.  And, it was very lucky for FM TOWNS users that the game was available for the platform.  However, FM TOWNS port was bugged.


1. Opening DEMO Crashes if you start in the FAST mode.

If you start Rocket Ranger in the FAST mode, the opening movie runs too fast relative to the BGM.  Then, the program tries to load the main-theme music while the intro BGM is still playing, and the program crashes.

However, miraculously the game program continues.  But, In-Service Regiser of PIC is not cleared.  Therefore, once crashed, the game continues without music.

I didn't know about it in 199x (I think it was 1993 when I tried it for the first time).  I felt that Rocket Ranger was a silent game because I did not hear music.

One of the reasons why Rocket Ranger should be remembered is its superb music.  I didn't know it had such a nice music until 2025.

Maybe other FM TOWNS users did not know there Rocket Ranger had a music.  If you are one of such FM TOWNS and Rocket Ranger users, try this patch, and play again on the real hardware or FM TOWNS emulator Tsugaru.  Now you can listen to one of the greates game music in history.



2. Fort Dix BGM plays only once after the opening demo.

In Amiga version, it plays Fort Dix theme BGM every time you come back to Fort Dix.  But, FM TOWNS version plays only once after the opening demo.

You will hear Fort Dix BGM every time you come back to the home base after this patch.



3. Interrogation scene bug

When you fly for rescue Jane and the doctor and be captured.  You will be interrogated by Colonel Leermeister.  If you make wrong choices, you are tortured and then taken to the prisoner camp, and you eventually escape.

But, in FM TOWNS version, if you make wrong choices, you are suddenly taken to the screen in which you can choose the next destination, or you can send SOS signal.  What's the F**K?  I was in the interrogation room, and all of a sudden, I was free!?  What happened to me?

There is a text explaining what happened in the code, but the programmer who ported it to FM TOWNS was setting the message ID 00000036H in EAX register but apparently forgot calling a function to show it on the screen.

This patch will fix this problem.

But, even the text did not explain how you got back your rocket pack.  There was a discontinuity in the game scenario here anyway.



4. Background during the last-boss battle.

The Amiga version had a background like a time tunnel during the last-boss battle.  FM TOWNS version had no background.

But, FM TOWNS version had a bitmap pattern of the background.  It is shown only for the one frame at the beginning of the last-boss battle.

This patch will make it visible during the last-boss battle.  Unfortunately it does not do palette animation like the Amiga version.





But, takeoff was too difficult in this game....




Usage

patch.cをコンパイルしたら、コマンドラインから以下のようにタイプすることでパッチを適用できます。

./patch.exe RocketRanger.iso



Compile patch.c, and apply patch from the terminal as:

./patch.exe RocketRanger.iso



