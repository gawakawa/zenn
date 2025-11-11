---
title: "SolidJS のチュートリアルをさらってみた"
emoji: "🚦"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: []
published: false
---

## はじめに
SolidJS というフレームワークのチュートリアルを一通りさらってみたので、現時点での理解や不明点、感じたことなどを書いていきます。

## 動機
signal という言葉を聞いたことはあったのですが、どんなものなのかよくわかっていなかったので、実際に signal を使ったコードを書いてみて理解を深めようと思いました。軽く調べた感じ、 signal を使うフレームワークは SolidJS の他にも preact や Qwik 等があるようでしたが、一番 signal を全面に押し出しているように見えたので SolidJS に決めました。

## SolidJS とは
React や Vue.js のような JavaScript の Web フレームワークです (React はライブラリですが ) 。signal を用いたきめ細やかなリアクティビティを特徴としています。

## Signal
Solid のリアクティビティの根幹をなすものです。 React の state に使用感は近いですが、基本的には別物です ( signal は state よりさらに primitive な概念として捉えるのが良さそう？ ) 。`createSignal()` 関数によって作成され、`createSignale` が返す getter, setter によってアクセスや更新ができます。 React の `useState()` とは異なり、 1 つ目の返り値は関数であることに注意が必要です。

```ts
const [count, setCound] = createSignal(0);

console.log(count()); // 0 を返す
setCound(1);          // signal の値を 1 に更新
console.log(ocunt()); // 1 を返す

```

## Subscribers

## JSX
Solid も React と同様 JSX を用います。

## fine-grained reactivity
Solid の大きな特徴はこの fine-grained reactivity です。

## 同期的更新

## 非同期的更新

## 良いなと思ったところ
- store に見られる fine-grained reactivity により、最小限の記述で必要最小限の変更を行える
- React と違いレンダリングがデフォルトで同期的なので、 UI への変更の反映タイミングについて頭を悩ませることが減りそう
- リアクティビティはすべて一貫して signal が担うというコンセプトがシンプルでわかりやすい

## わからないところ
- 個人的にはコードのトラッキングを行う上で immutablity は捨てたくないです。fine-grained reactivity と pure なロジックを、パフォーマンスを失うことなく実現する夢みたいな方法はないのかなと思いました。

## まとめ
SolidJS のチュートリアルを読み、理解したことと感じたことをまとめました。現時点では、 signal のシンプルさと、仮想 DOM を使わないことによる同期的な更新が SolidJS の魅力であると感じています。まだチュートリアルを読んだだけなので、これから簡単なアプリを作って色々試していきたいです。
