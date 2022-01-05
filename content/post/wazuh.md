---
title: "オープンソースで構築するEDR"
date: 2019-05-18T13:23:09+09:00
# trueにすると公開されない
draft: false
categories:
- security
- edr
tags:
- security
- edr
- elasticsearch
# Googleはmeta keywordsを見ていないので意味がない
#keywords:
#- test
autoThumbnailImage: false
thumbnailImagePosition: "left"
thumbnailImage: /img/security.jpg
metaAlignment: center
---
Elastic Stackをベースにして作られたEndpoint Detection and Response (EDR)であるWazuhを構築してみました。
<!--more-->

[公式のHP](https://wazuh.com/)によるとWazuhの備えている機能は下記の通りです

* Security Analytics
* Intrusion Detection
* Log Data Analysis
* File Integrity Monitoring
* Vulnerability Detection
* Configuration Assessment
* Incident Response
* Regulatory Compliance
* Cloud Security Monitoring

## あらかじめ準備しておく環境
* windows7 (VMでも可)
* DockerがインストールされたLinuxマシン
    * Ubuntu 18.04に構築
    * docker version 18.09.6
    * docker-compose version 1.17.1

## wazuh managerのセットアップ
```bash
$ git clone https://github.com/wazuh/wazuh-docker
$ cd wazuh-docker
$ echo 'vm.max_map_count = 262144' | sudo tee -a /etc/sysctl.conf
$ sudo sysctl -p
$ docker-compose up -d
```
起動が完了したら、コンテナを動かしているホストへブラウザから接続してみます。
私の環境ではコンテナを`192.168.11.30`で実行しているため接続先は下記のようになります

`https://192.168.11.30`

またユーザ名とパスワードを聞かれるので下記のように入力します。
```
user: foo
password: bar
```

![](https://i.imgur.com/tggNUAz.png)

左側サイドバーのWazuhをクリックすると下のような画面が表示されます。こちらが`Wazuh-manager`とよばれる、エンドポイントの管理画面になります。
![](https://i.imgur.com/tJjytLU.png)




## wazuh agentをインストール
wazuh-managerにagentを登録するために、wazuh-agentをインストールします。

### 対応しているagent一覧
https://documentation.wazuh.com/current/installation-guide/packages-list/index.html

今回はwindowsで実行するので
windows版をダウンロードします。

![](https://i.imgur.com/0iwrOr4.png)

ダウンロードが完了したらファイルを実行し、ウィザードに従ってインストールしていきます。
![](https://i.imgur.com/AuEjWe3.png)

Run Agent configuration interfaceにチェックをいれてFinishボタンを押します。
![](https://i.imgur.com/Uc40HDW.png)

次のような画面が表示されたらWindowsのIPアドレスを確認します。
私の環境だと`192.168.11.252`でした。
![](https://i.imgur.com/D6JRjtb.png)

LinuxからRestAPIを使ってAgentを登録を行います。

```bash
curl -u foo:bar -k -X POST -d 'name=NewAgent&ip=192.168.11.252' https://192.168.11.30:55000/agents

{"error":0,"data":{"id":"001","key":"MDAxIE5ld0FnZW50IDE5Mi4xNjguMTEuMjUyIGQzZTgxOWY0YWVkYzQ4MWJmOTcxNDg3OWUwNGM1ZDQwNzE5ZWE5YTcwMmI4ZjllNTdhMTE5YzNiYTgxZGQ2NWQ="}}                                             
```

先程出力されたkeyとwazuh-manager(コンテナを実行しているホスト)のipアドレスを入力し<br/>
saveボタンをクリックします
![](https://i.imgur.com/C1Cdw7l.png)

wazuh-managerのagentsからwindows7のマシンが登録されている確認できます。
![](https://i.imgur.com/P6mTW3w.png)

wazuh-managerの画面左上の`Overview`-> `Security events`と進んでいくと、セキュリティ関連のイベントが確認できます。
![](https://i.imgur.com/VW6YxHC.png)

## 最後に
今回はOSSで手軽にはじめられるEDRの構築を行いました。
次回は実際に攻撃を行い、どのようなログが残るのか検証してみたいと思います。
