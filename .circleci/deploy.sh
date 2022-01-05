#!/usr/bin/env bash

# エラー時、実行を止める
set -e

# gitの諸々の設定
git config --global push.default simple
git config --global user.email $(git --no-pager show -s --format='%ae' HEAD)
git config --global user.name $CIRCLE_USERNAME

git clone git@github.com:tatsu-i/tatsu-i.github.io.git deploy

# rsyncでhugoで生成したHTMLをコピー
rsync -arv --delete public/* ./deploy/
#cp ./CNAME ./deploy/
cd ./deploy

git add -f .
git commit -m "Deploy #$CIRCLE_BUILD_NUM $(date)" || true
git push -f
