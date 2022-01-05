---
title: "Dockerを使ってElasticsearch7.0のクラスタを作ってみる"
date: 2019-05-12T15:42:36+09:00
draft: false
categories:
- elasticsearch
- docker
tags:
- docker
- docker-compose
- elasticsearch
- kibana
keywords:
- docker
- docker-compose
- elasticsearch7
- kibana7
- elasticsearch
- kibana
autoThumbnailImage: false
thumbnailImagePosition: "left"
thumbnailImage: /img/docker.jpg
metaAlignment: center
---
Elasticsearch 7.0がリリースされたそうなので早速Dockerで動かしてみました。

<!--more-->

## docker-composeファイルの作成
はじめに`docker-compose.yml`という名前のファイルを下記の内容で作成します。<br>
同じイメージを使って複数のノードを生成するため、Yamlが冗長化しないように<br>
アンカーとエイリアスを用いた記述を行っています。

elastic stack(x-pack)を利用する場合は`-oss:7.0.0`を`:7.0.0`に置き換える必要があります。

```yaml
version: '3.4'

x-es7-common: &es7-common
    image: docker.elastic.co/elasticsearch/elasticsearch-oss:7.0.0
    ulimits:
      memlock:
        soft: -1
        hard: -1

x-es7-option: &es7-option
      # クラスタ名
      cluster.name: 'docker-cluster'
      # ノードあたりの割当メモリ
      ES_JAVA_OPTS: '-Xms512m -Xmx512m'
      # スワップ無効化
      bootstrap.memory_lock: 'true'

# Dataノード
x-es7-node: &es7-node
    <<: *es7-common
    environment:
      <<: *es7-option
      node.master: "false"
      node.data: "true"
      node.ingest: "false"
      discovery.seed_hosts: "elasticsearch"

# Masterノード
x-es7-master: &es7-master
    <<: *es7-common
    environment:
      <<: *es7-option
      node.master: "true"
      node.data: "false"
      node.ingest: "false"
      cluster.initial_master_nodes: "elasticsearch"
      node.name: "elasticsearch"
    # ノード数に応じて変更する
    depends_on: 
      - "elasticsearch-data1"
      - "elasticsearch-data2"
      - "elasticsearch-data3"

# ノード数に応じて変更する
volumes:
  es7-master1:
  es7-data1:
  es7-data2:
  es7-data3:

services:

  kibana:
    image: docker.elastic.co/kibana/kibana-oss:7.0.0
    ports: [ '5601:5601']
    depends_on: [ 'elasticsearch' ]
    environment:
      ELASTICSEARCH_URL: http://elasticsearch:9200

  elasticsearch:
    ports:
      - "9200:9200"
    volumes: [ 'es7-master1:/usr/share/elasticsearch/data' ]
    <<: *es7-master

  # ノード数に応じて変更する
  elasticsearch-data1:
    volumes: [ 'es7-data1:/usr/share/elasticsearch/data' ]
    <<: *es7-node

  elasticsearch-data2:
    volumes: [ 'es7-data2:/usr/share/elasticsearch/data' ]
    <<: *es7-node

  elasticsearch-data3:
    volumes: [ 'es7-data3:/usr/share/elasticsearch/data' ]
    <<: *es7-node

```

## 動作確認
dockerを起動します。
```bash
$ docker-compose up -d
```

`{"message": "started"}`というメッセージが表示されるまで待ちます。
```bash
$ docker-compose logs -f elasticsearch
...
elasticsearch_1        | {"type": "server", "timestamp": "2019-05-12T15:14:17,587+0000", "level": "INFO", "component": "o.e.n.Node", "cluster.name": "docker-cluster", "node.name": "elasticsearch", "cluster.uuid": "9AIA4GPNTXegM81GvGx9yw", "node.id": "Sze63DhdRDus_m4dsjLFGQ",  "message": "started"  }
```

起動が確認できたらCtrl+cで抜けてクラスタの状態を確認します。
```bash
$ curl http://127.0.0.1:9200/_cat/nodes
172.25.0.5 30 98 62 9.31 5.48 3.14 m * elasticsearch
172.25.0.3 22 98 64 9.31 5.48 3.14 d - 34a1ac655be6
172.25.0.4 27 98 59 9.31 5.48 3.14 d - 4b8e00827181
172.25.0.2 26 98 64 9.31 5.48 3.14 d - ca4945863dee
```

## ブラウザからKibanaにアクセスしてみる

dockerを動作させているマシンのブラウザから[http://127.0.0.1:5601](http://127.0.0.1:5601)にアクセスすると、Kibanaの画面が表示されます。

![kibana](/img/es7/kibana.png)

サンプルデータが必要ない場合は`Explore on my own`をクリックすると利用が開始します。
