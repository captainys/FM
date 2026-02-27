Rocket Ranger for FM TOWNS BGM bug-fix Patch by CaptainYS


Introduction

ロケットレンジャーは、ゲーム史に名を残すべき傑作ゲームであり、FM TOWNSに移植されたことはFM TOWNSユーザーとしては非常に喜ぶべきことだと思ってますが、残念ながらFM TOWNS版はバグってます。

高速モードでロケットレンジャーを起動した場合、オープニングBGMに対して動画が速く進み過ぎる結果、まだ最初のBGMが終わってないのに、メインテーマのBGMをロードしようとしてクラッシュします。

ところが、クラッシュに寄ってPICのIn-Service Registerが立ったままの状態になるため、奇跡的にBGM無しでゲームは進行します。

このバグを知らなかった僕は、199x年当時 (多分1993年だったと思う)、「ロケットレンジャーはBGMも無くて静かなゲームだなあ」と思った記憶があります。

し・か・し！

ロケットレンジャーがゲーム史に名を残すべき理由のひとつは、ゲームミュージック史上相当上位に食い込むと思われる秀逸なBGMにあります。なんと、僕は、ロケットレンジャーにそんな優れたBGMがついていたことを2025年まで知りませんでした。

だから、他にもFM TOWNS II HR以降を使ってた人でロケットレンジャーやったけどBGMの存在を知らないままだったという人がいるかもしれません。そういう人は、今からでもロケットレンジャーのCDイメージにこのパッチを適用してFM TOWNS実機あるいはFM TOWNSエミュレータ津軽を使ってプレイしてみましょう。このパッチを当てると高速モードでも上の問題が発生しないので、非常に印象的なBGMを聞くことができます。

でも、このゲーム離陸が難し過ぎたよね。



Rocket Ranger is one of the games that should be permanently remembered as a game that impacted the history of the video game.  And, it was very lucky for FM TOWNS users that the game was available for the platform.  However, FM TOWNS port was bugged.

If you start Rocket Ranger in the FAST mode, the opening movie runs too fast relative to the BGM.  Then, the program tries to load the main-theme music while the intro BGM is still playing, and the program crashes.

However, miraculously the game program continues.  But, In-Service Regiser of PIC is not cleared.  Therefore, once crashed, the game continues without music.

I didn't know about it in 199x (I think it was 1993 when I tried it for the first time).  I felt that Rocket Ranger was a silent game because I did not hear music.

One of the reasons why Rocket Ranger should be remembered is its superb music.  I didn't know it had such a nice music until 2025.

Maybe other FM TOWNS users did not know there Rocket Ranger had a music.  If you are one of such FM TOWNS and Rocket Ranger users, try this patch, and play again on the real hardware or FM TOWNS emulator Tsugaru.  Now you can listen to one of the greates game music in history.

But, takeoff was too difficult.




Usage

patch.cをコンパイルしたら、コマンドラインから以下のようにタイプすることでパッチを適用できます。

./patch.exe RocketRanger.iso



Compile patch.c, and apply patch from the terminal as:

./patch.exe RocketRanger.iso



