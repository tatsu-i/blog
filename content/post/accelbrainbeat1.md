---
title: "バイノーラルビート使用時の脳波を計測してみる"
date: 2022-06-12T11:14:24Z
draft: false
categories:
- mindfulness
- braintech
tags:
- mindfulness
- braintech
- binauralbeat
- healthcare
# Googleはmeta keywordsを見ていないので意味がない
#keywords:
#- test
autoThumbnailImage: false
thumbnailImagePosition: "left"
thumbnailImage: /img/cyber1.jpg
metaAlignment: center
---

かなり久しぶりの投稿になります。  
最近はマインドフルネスにハマっていて瞑想を日課としています。  
はじめは自己流の瞑想方法だったのですが、これでただしいのか？と気になって色々と調べていくうちに  
バイノーラルビートによる誘導瞑想というものに出会いました。  
ある程度効果は感じられるのですが、脳波が本当に誘導されているのかという疑問から実際に計測してみることにしました。  

## 使用したセンサーとアプリケーション

* [Muse2](https://choosemuse.com/muse-2/)
* [Mind Monitor](https://mind-monitor.com/)

![sensor](https://www.researchgate.net/profile/Ran-Liu-48/publication/338967157/figure/fig1/AS:865300069228544@1583315021343/Muse-TM-used-for-EEG-recording-a-Locations-of-electrodes-in-the-Muse-b-Top-down.png)

<!--more-->

## データフォーマット
はじめにMind-monitorで収集したデータを以下の形式のCSVファイルに保存します。  
正しく装着できていない場合のデータを除くために`hsi`へセンサーの状態を保存しています。  
`aux`の値は今回使用しません。  

```
"timestamp", "tp9", "af7", "af8", "tp10", "aux", "hsi"
1652711580.4923728,809.084228515625,818.7545776367188,799.4139404296875,822.7838745117188,736.959716796875,4.0
1652711580.491106,792.5640869140625,817.5457763671875,794.5787353515625,815.93408203125,715.2014770507812,4.0
1652711580.4899936,787.3259887695312,807.87548828125,791.7582397460938,802.2344360351562,707.5457763671875,4.0
1652711580.528648,805.4578857421875,811.90478515625,800.2197875976562,807.4725341796875,618.09521484375,4.0
1652711580.5324516,800.6226806640625,813.113525390625,801.025634765625,793.3699340820312,610.03662109375,4.0
1652711580.5478635,807.4725341796875,819.1575317382812,794.981689453125,805.4578857421875,755.091552734375,4.0
1652711580.5407498,805.054931640625,815.5311279296875,799.8168334960938,794.1758422851562,685.7875366210938,4.0
1652711580.5647519,820.7692260742188,825.2014770507812,795.7875366210938,808.2783813476562,740.989013671875,4.0
1652711580.5914211,798.6080322265625,811.90478515625,790.952392578125,793.7728881835938,687.3992919921875,4.0
1652711580.5734675,820.7692260742188,817.94873046875,797.3992919921875,806.2637329101562,760.7326049804688,4.0

```

## 脳波データをフーリエ変換する

脳波は様々な周波数がブレンドされていて、目視のみで分析するのは非常に難しいです。  
そこでフーリエ変換と呼ばれる処理を行うことで、ブレンドされた波を周波数ごとに分解することができます。  
以下がCSVデータを読み込んで、フーリエ変換表示を行うコードになります。  

```python
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import wavio
import librosa
import librosa.display
ylim = 35

def _plot_spec(df_eeg):
    print("(tp9 tp10 af7 af8)の平均値")
    y = df_eeg.mean(axis=1).values
    D = librosa.stft(y, n_fft=512, hop_length=150)  # STFT
    S, phase = librosa.magphase(D)  # 複素数を強度と位相へ変換
    DB = librosa.amplitude_to_db(S) # 強度をdb単位へ変換

    plt.figure(figsize=(16, 6))
    librosa.display.specshow(DB, sr=150, hop_length=150, x_axis='time', y_axis='linear')
    plt.colorbar(format='%+2.0f dB')
    plt.ylim(0, ylim)
    plt.yticks(np.arange(0, ylim+1, 5))
    plt.show()
    plt.clf()
    plt.close()
    del D, DB, S, phase

def plot_spec_eeg(file_name):
    header = ["ts", "tp9", "af7", "af8", "tp10", "fpz", "hsi"]
    df_eeg = pd.read_csv(file_name, names=header)
    df_eeg = df_eeg.set_index("ts")
    try:
        df_eeg = df_eeg.fillna(0)
        df_eeg = df_eeg[df_eeg["hsi"] <= 4]
        df_eeg.pop("hsi")
    except:
        pass
    df_eeg.pop("fpz")
    _plot_spec(df_eeg)

# CSVファイルの読み込み
file_name="./data/eeg.csv"
plot_spec_eeg(file_name)
```

## 通常状態の脳波
はじめに通常状態の脳波です。  
パソコンを適当に触りながら15分程度計測したデータになります。  

![](/img/abb1/normal.png)

ガンマ波である30Hz付近と1Hz〜10Hzの範囲に脳波が集中しているように見えます。

## デルタ波とベータ波への誘導

誘導音声は[metaWaves](https://github.com/tatsu-i/metaWaves)を使用しています。

![](/img/abb1/delta-beta.png)

* 1分まではピーク差分(誘導脳波)は2Hz, 4Hzで誘導
	* *聞き始めてからしばらくすると脳波が5Hz以下で偏り始めた
* 1分後からピーク差分(誘導脳波)は14Hz, 23Hzで誘導
	* 1分18秒あたりから脳波が全体的に活性化している。

## まとめ

今回は自作したバイノーラルビートで脳波を誘導するという検証を行い、ある程度脳波の誘導がされているという結果を確認することができました。  

さらに詳しい検証結果は[こちら](https://github.com/tatsu-i/MetaMind/blob/main/notebook/hemi_sync.ipynb)に公開していますので、  
みなさんも市販の特殊音響等で同様の結果が得られるかどうかなど試してみてはいかがでしょうか。
