---
title: "KibanaでWindowsイベントログを可視化してみる"
date: 2019-05-04T12:16:08+09:00
# trueにすると公開されない
draft: false
categories:
- elasticsearch
- windows
tags:
- elasticsearch
- windows
# Googleはmeta keywordsを見ていないので意味がない
#keywords:
#- test
autoThumbnailImage: false
thumbnailImagePosition: "left"
thumbnailImage: /img/analysis1.jpg
metaAlignment: center
---
本記事では下記のテーマについて解説したいと思います。

* elasticsearchとkibanaの構築
* winlogbeatのインストール
* kibanaダッシュボードの作成

<!--more-->

はじめにElasticSearchとKibanaを用意します。
docker-compose.ymlという名前のファイルを下記の内容で作成します。

```
version: '3.4'

volumes:
  es-data:      # elasticsearch data

services:

  kibana:
    image: docker.elastic.co/kibana/kibana:7.0.0
    ports: [ '5601:5601']
    depends_on: [ 'elasticsearch' ]
    environment:
      ELASTICSEARCH_HOST: http://elasticsearch:9200

  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.0.0
    volumes: [ 'es-data:/usr/share/elasticsearch/data' ]
    ports: [ '9200:9200']
    environment:
      discovery.type: 'single-node'
      bootstrap.memory_lock: 'true'
      ES_JAVA_OPTS: '-Xms1G -Xmx1G'
    ulimits:
      memlock:
        soft: -1
        hard: -1

```

## ElasticSearch & Kibanaの起動
dockerを起動します。
```bash
$ docker-compose up -d
```
{"message": "started"}というメッセージが表示されるまで待ちます。
```bash
$ docker-compose logs -f elasticsearch
...
elasticsearch_1        | {"type": "server", "timestamp": "2019-05-12T15:14:17,587+0000", "level": "INFO", "component": "o.e.n.Node", "cluster.name": "docker-cluster", "node.name": "elasticsearch", "cluster.uuid": "9AIA4GPNTXegM81GvGx9yw", "node.id": "Sze63DhdRDus_m4dsjLFGQ",  "message": "started"  }
```
起動が確認できたらCtrl+cで抜けてクラスタの状態を確認します。

## Sysmonのインストール
下記のサイトからSysmonをダウンロードします。
https://docs.microsoft.com/ja-jp/sysinternals/downloads/sysmon
コマンドプロンプトを管理者権限で実行し下記のコマンドを実行します
```shell
sysmon -accepteula –i –h md5,sha256 –n
```

## Winlogbeatのインストール
winlogbeatをダウンロードします
https://www.elastic.co/jp/downloads/beats/winlogbeat

ダウンロードしたzipファイルを`C:\winlogbeat`へ展開します

![](https://i.imgur.com/PFJbMWJ.png)

展開したファイルの中にある`winlogbeat.yml`の中身を以下のように書き換えます。
```
output.elasticsearch:
  hosts: ["192.168.11.30:9200"]

setup.kibana:
  host: "192.168.11.30:5601"
```


次に管理者権限でコマンドプロンプトを立ち上げ下記のコマンドを実行します。
```
cd C:\winlogbeat
PowerShell.exe -ExecutionPolicy UnRestricted -File .\install-service-winlogbeat.ps1
```

サービス一覧に登録されているか確認する
スタートメニューからローカルサービスの表示をクリックします。
![](https://i.imgur.com/wL3rgZZ.png)
`winlogbeat`というサービス名を探すと、開始していないので
右クリックメニューから開始をクリックします。
![](https://i.imgur.com/PcKzOdn.png)


## Kibana ダッシュボードの準備
Windows のPowershellを起動し下記のコマンドを実行します。
```
cd C:\winlogbeat
.\winlogbeat.exe setup --dashboards
```
実行結果が
```
Loading dashboards (Kibana must be running and reachable)
Loaded dashboards

```
と表示されればOKです。


ブラウザからkibanaへアクセスし、左側サイドバーの`Dashboard`をクリックします。
![](https://i.imgur.com/N1k9lLE.png)

`Winlogbeat Dashboard ECS`をクリックすると、イベントログのダッシュボードが表示されます。
![](https://i.imgur.com/3D4SX1h.png)
