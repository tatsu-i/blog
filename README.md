# tatsu-i.github.io
[![CircleCI](https://circleci.com/gh/tatsu-i/blog/tree/master.svg?style=svg&circle-token=a993774821afc32ab989cfdd3b83324411a79298)](https://circleci.com/gh/tatsu-i/blog/tree/master)

[github tatsu-i.github.io](https://github.com/tatsu-i/tatsu-i.github.io)

# 新規記事の作成
```
hugo new post/hello.md
```

# 記事のbuildと確認
```
docker run --rm -it -v "$(pwd):/data" --net=host cibuilds/hugo bash
```
