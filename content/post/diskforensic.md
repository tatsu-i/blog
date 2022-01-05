---
title: "自宅ではじめるディスクフォレンジック①"
date: 2019-05-17T22:06:29+09:00
# trueにすると公開されない
draft: false
categories:
- security
- forensic
tags:
- security
- forensic
# Googleはmeta keywordsを見ていないので意味がない
#keywords:
#- test
autoThumbnailImage: false
thumbnailImagePosition: "left"
thumbnailImage: /img/security2.jpg
metaAlignment: center
---

コンピュータフォレンジックの中でHDDやSSDなどのディスクに対するフォレンジックを
`ディスクフォレンジック`と呼びます。
ディスクフォレンジックは大まかに下記のような手順で行われます

1. 調査対象の選定
1. 調査媒体の保全
1. フォレンジック調査

今回は既に調査対象が選定されているという前提で、調査媒体の保全作業を行ってみたいと思います。

<!--more-->

## 準備するもの
* 調査対象のマシン
* CD-R (VMイメージがある場合は必要なし)

## ディスクイメージの作成
OSFCloneのISOイメージをダウンロードします。

https://www.osforensics.com/tools/create-disk-images.html

ダウンロードが完了したらISOをCD-Rへ書き込みます。

## 調査媒体の保全
マルウェアに感染したマシンへCD-Rを挿入し起動します。
私の環境では前回の記事で作成したVMイメージにISOファイルをDVDドライブにマウントさせ起動しました。

osfcloneが起動すると次のような画面が表示されます。
![](https://i.imgur.com/ROmD7Fs.png)

ディスクイメージを保存したいので`2`と入力して`Enter`を押します。
![](https://i.imgur.com/qfGYKsk.png)

出力形式は下記の3つから選択できます。

* Raw (dd)
* EWF : Expert Witness Format
* AFF : Advanced Forensic Format

今回は圧縮率が高く取得時間が早いEWFを選択します。
![](https://i.imgur.com/f8vAgpY.png)

続いてイメージ化するディスクを選択します。
![](https://i.imgur.com/czAkecw.png)

適切なデバイスを選択してください。
![](https://i.imgur.com/Y6cMUfC.png)

次にイメージファイルを保存するパーティションを選択します。
![](https://i.imgur.com/bjcpCqE.png)

保存先のパーティションはEXT4でフォーマットしてあります。
![](https://i.imgur.com/ia2kKyu.png)

次にイメージの名前を変更します。
`3`を入力したあとに`Enter`を押します。
![](https://i.imgur.com/USfU3Qr.png)

例えば`windows`という名前をつけて保存してみます。
![](https://i.imgur.com/9Jq6xmX.png)

Parametersを確認してSource,Destination,Image filenameが間違っていないか確認します。
![](https://i.imgur.com/ATxqpiM.png)

問題がなければ`9`を入力し`Enter`を押してください。
![](https://i.imgur.com/olexmiC.png)

色々と質問されますがEnterを押し続けて問題ないです。
質問に回答したらイメージの取得が開始します。
![](https://i.imgur.com/oNhU3GY.png)

進捗率が100%になったらEnterを押してメインメニューへ戻り
shutdownします。
![](https://i.imgur.com/OnkoFW2.png)

## 最後に
今回はCD-Rから起動することでオペレーティングシステム環境にログを残すことなくディスクの内容を別の媒体へコピーしました。
次回は保全したディスクイメージを解析するフォレンジック調査を実践してみたいと思います。
