---
title: "ブログ環境について"
date: 2019-05-01T17:34:44+09:00
# trueにすると公開されない
draft: false
categories:
- hugo
- blog
tags:
- hugo
- blog
# Googleはmeta keywordsを見ていないので意味がない
#keywords:
#- test
autoThumbnailImage: false
thumbnailImagePosition: "left"
thumbnailImage: /img/cyber-s.jpg
metaAlignment: center
---

本サイトはMarkdownで記事を書いた後に[Hugo](https://gohugo.io/)でHTMLを生成し、Github Pagesデプロイしています。
テーマは[Tranquilpeak](https://github.com/kakawait/hugo-tranquilpeak-theme)を使用しています。

他にもブログを公開するために下記のサービスを利用しています。

* https://github.com/tatsu-i/tatsu-i.github.io (Github Pages)
* https://github.com/tatsu-i/blog (privateリポジトリ)
* https://circleci.com/ (CI/CD)
* https://www.onamae.com (CNAMEでgithub pagesのドメインを変更)
* https://hackmd.io (記事の下書き用)

<!--more-->

## 記事の公開手順

* はじめに記事の下書きはhackmd.ioに書いておきます
* 記事が出来上がったら、blogリポジトリにmarkdownを追加します

```bash
$ git clone https://github.com/tatsu-i/blog
$ hugo new post/new.md
$ vim post/new.md (hackmd.io)の下書きをコピペ
$ git add post/new.md
$ git commit -m "new post"
$ git push origin master
```

* MasterブランチへpushされるとCirclCIが起動し、Github Pageリポジトリが更新されます

![](https://i.imgur.com/2meGAOy.png)

以下CirclCIの設定ファイルです。

`config.yml`
```yaml
version: 2
jobs:
  build:
    branches:
      only:
        - master
    docker:
      - image: cibuilds/hugo:0.55.6

    working_directory: /hugo
    steps:
      - run:
          name: Update enviroment
          command: apk update && apk add git
      - checkout
      - run:
          name: Building blog pages
          command: hugo -v
      - add_ssh_keys:
          fingerprints:
            - "git ssh deploy key fingerprint"
      - deploy:
          name: Deploy to GitHub Pages
          command: ./.circleci/deploy.sh

```

`deploy.sh`
```bash
#!/bin/bash -e

# gitの設定
git config --global push.default simple
git config --global user.email $(git --no-pager show -s --format='%ae' HEAD)
git config --global user.name $CIRCLE_USERNAME

# Github Pages 用リポジトリのクローン
git clone git@github.com:tatsu-i/tatsu-i.github.io.git deploy

# rsyncでhugoで生成したHTMLをコピー
rsync -arv --delete public/* ./deploy/
cp ./CNAME ./deploy/
cd ./deploy

git add -f .
git commit -m "Deploy #$CIRCLE_BUILD_NUM $(date)" || true
git push -f
```
