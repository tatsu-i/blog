---
title: "自宅ではじめるディスクフォレンジック②"
date: 2019-05-22T22:18:10+09:00
# trueにすると公開されない
draft: false
categories:
- security
- forensic
- elasticsearch
- docker
tags:
- security
- forensic
- elasticsearch
- docker
# Googleはmeta keywordsを見ていないので意味がない
#keywords:
#- test
autoThumbnailImage: false
thumbnailImagePosition: "left"
thumbnailImage: /img/cyber2.jpg
metaAlignment: center
---
コンピュータフォレンジックの中でHDDやSSDなどのディスクに対するフォレンジックを
`ディスクフォレンジック`と呼びます。
ディスクフォレンジックは大まかに下記のような手順で行われます

1. 調査対象の選定
1. 調査媒体の保全
1. フォレンジック調査

今回は[前回の記事](/2019/05/infectionmonkey/)で作成した感染マシンを使ってフォレンジック調査をやってみたいと思います。

<!--more-->

## 準備するもの
* Windowsのディスクイメージ
    * 感染したマシンは前回の記事で作成したものを利用
    * ディスクイメージはOSFCloneで作成しました(作り方は[こちら](/2019/05/diskforensic/))
* DockerがインストールされたLinuxマシン
    * Ubuntu 18.04に構築
    * docker version 18.09.6
    * docker-compose version 1.17.1

## Dockerイメージのビルド
```bash
$ git clone https://github.com/tatsu-i/docker-forensic
$ cd docker-forensic
$ docker-compose build
```

## スレッド数の上限を設定
```bash
$ echo 'vm.max_map_count = 262144' | sudo tee -a /etc/sysctl.conf
$ sudo sysctl -p
```

## ElasticSearchとKibanaのコンテナを起動
```bash
$ docker-compose up -d kibana
```

## ディスクイメージファイルの準備
OSFCloneで作成したイメージを格納しているディスク(/dev/sdc1)をマウントします。

```bash
$ mkdir -p evidence
$ sudo mount /dev/sdc1 ./evidence
```

## Plasoを使ってイメージを変換
```bash
$ docker-compose up -d plaso
$ docker-compose logs -f plaso
plaso - psort version 20190331

Storage file		: /data/output.plaso
Processing time		: 00:16:51

Events:         Total
                1699331

Identifier              PID     Status          Memory          Events          Tags            Reports
Main                    72      exporting       1.4 GiB         1699331 (0)     0 (0)           0 (0)

Processing completed.

******************************** Export results ********************************
        Events processed : 1699331
     Events MACB grouped : 1694908
Duplicate events removed : 249
         Events filtered : 0
  Events from time slice : 0
--------------------------------------------------------------------------------
dockerforensic_plaso_1 exited with code 0

```
私の環境では100Gのディスクを解析するのに1時間程度かかりました。
以下マシンスペックです。
```
cpu : Intel(R) Core(TM) i7-6850K CPU @ 3.60GHz 4 Core
memory : 32G
disk: 1TB SSD

```

処理が遅いと感じる場合は`WORKER_NUM`を増やしてみてください。
例えば16個のWorkerを使う場合、Workerあたりのメモリ上限は2Gであるため最大で32Gのメモリが必要になります。
```diff
diff --git a/docker-compose.yml b/docker-compose.yml
index 63f5727..c8de702 100644
--- a/docker-compose.yml
+++ b/docker-compose.yml
@@ -10,7 +10,7 @@ services:
     volumes:
       - ./evidence:/data
     environment:
-      WORKER_NUM: 2
+      WORKER_NUM: 16
 
   logstash:
     build: logstash
```

## Kibanaを使って分析

ログを可視化するためにダッシュボードをKibanaにインポートします。
私の環境ではコンテナを起動したホストのIPアドレスが`192.168.11.30`なので
下記のようなコマンドでインポートしました。
```
$ curl -XPOST http://192.168.11.30:5601/api/kibana/dashboards/import \ 
   -H 'kbn-xsrf:true' -H 'Content-type:application/json' \
   -d @dashboard-plaso.json
```
ダッシュボードのインポートが完了したら、ブラウザから`http://192.168.11.30:5601`へ接続します。
画面左側のサイドバーの`Dashboard`をクリックしたあと`plaso`をクリックすると下記のようなダッシュボードが表示されます。
![](https://i.imgur.com/hpuq4WA.png)

ダッシュボードの中にはテーブルがたくさんあるのですが、タイトル`Path`のテーブルに注目です。
1ずつ確認してみると`monkey.exe`が見つかりました。

![](https://i.imgur.com/RxmPXXN.png)

ダッシュボード画面上部の検索窓に`monkey.exe`と入力しフィルターを行うと、下記のような結果が出力されました。
![](https://i.imgur.com/rj1QsGf.png)

sha256 hashというタイトルのテーブルに表示されてるハッシュ値をGoogleで検索すると、
Infection MonkeyのAgentであることがわかります。
ハッシュ値: `77ac4264715a6e7d238f8b67ed04ee75cf75c07d360a4b649ca6e31c83ce7b21`

![](https://i.imgur.com/qxH064V.png)

## 最後に
今回は模擬マルウェアに感染させたディスクイメージのフォレンジック調査を行いました。
答えがわかっているということもあり、侵害の起点を簡単に探すことができました。

本当に感染してしまったマシンのディスクを解析する場合は、ここまで簡単に侵害の起点を見つける事は難しいでしょう。
そのような場合は下記のようなサービスを使って悪意のあるファイルのハッシュ値がないか確認してみましょう。<br><br>

* https://www.virustotal.com/
* https://www.hybrid-analysis.com/
