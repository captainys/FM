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

This patch fixes following bugs and issues.

(1) Opening BGM Crash
If the game is started in FAST mode, the opening movie finishes before the music. The program then attempts to load the "Main Theme" while the opening music is still playing, causing an audio interrupt handler crash. While the game "miraculously" continues to run, the audio remains broken. This patch ensures the music transitions correctly.

(2) Interrogation Scene Logic Error
During the movie scene where the Rocket Ranger and Jane are interrogated, making the wrong choices would abruptly warp the player to the destination/SOS screen without explanation. This created a narrative plot hole, as a prisoner of war should not have access to a rocket pack or radio.  The original code correctly loaded the "Captured" message ID into the EAX register, but the programmer forgot to call the function to display that text and wait for a button press. This patch restores the missing dialogue and transition.

(3) Fort Dix Theme Loop
In the original FM Towns release, the Fort Dix main theme would play only once during the entire game. If the player returned to the base later, the scene would be silent. To match the Amiga version’s behavior, this patch ensures the theme plays every time the Rocket Ranger returns to Fort Dix.

(4) Boss Battle Background Restoration
In the FM Towns version, the boss battle took place against a blank, black background. Interestingly, the bitmap data for the background existed in the executable and was even being rendered for exactly one frame before disappearing. This patch fixes the draw calls so the background remains visible throughout the entire battle, bringing it in line with the Amiga version’s visuals.







But, takeoff was too difficult in this game....




Usage

patch.cをコンパイルしたら、コマンドラインから以下のようにタイプすることでパッチを適用できます。

./patch.exe RocketRanger.iso



Compile patch.c, and apply patch from the terminal as:

./patch.exe RocketRanger.iso



