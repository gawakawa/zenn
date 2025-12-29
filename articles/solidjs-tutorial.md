---
title: "SolidJS のチュートリアルをさらってみた"
emoji: "🚦"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: [solidjs, javascript, typescript]
published: false
---

## はじめに

SolidJS というフレームワークのチュートリアルを一通りさらってみたので、現時点での理解や不明点、感じたことなどを書いていきます。

## 動機

signal という言葉を聞いたことはあったのですが、どんなものなのかよくわかっていなかったので、実際に signal を使ったコードを書いてみて理解を深めようと思いました。軽く調べた感じ、signal を使うフレームワークは SolidJS の他にも preact や Qwik 等があるようでした。その中でも一番 signal を全面に押し出しているように見えた SolidJS を選びました。

## SolidJS とは

React や Vue.js のような JavaScript の Web フレームワークです (React はライブラリですが ) 。signal を用いたきめ細やかなリアクティビティを特徴としています。

## SolidJS のりアクティビティ

### Signal

Solid のリアクティビティの根幹をなすものです。 React の state に使用感は近いですが別物です。SolidJS ではこの signal を追跡することによって、データが変化したときに DOM の中で変更が必要なノードだけを変更し、 UI を変化させることを可能にしています。
signal を作成するには `createSignal()` 関数を使います。 `createSignal()` は返り値として getter, setter の 2 つの関数を返します。 React の `useState()` とは異なり、 1 つ目の返り値は関数であることに注意が必要です。

```ts
const [count, setCound] = createSignal(0);

console.log(count()); // 0 を返す
setCound(1);          // signal の値を 1 に更新
console.log(ocunt()); // 1 を返す

```

### Effect

Effect は、 signal の更新をトリガーとして実行される関数です。 React の Effect とはだいぶ違いますね。 `createEffect()` で登録できます。

```ts
const [count, setCount] = createSignal(0);

createEffect(() => {
  console.log(count());
});
```

### Subscriber

subscriber は、 signal の変化を監視し、 signal が更新されたときに登録された処理 (effect) をトリガーする役割を持ちます。

### SolidJS のリアクティブシステム

```ts
let currentSubscriber = null;

function createSignal(initialValue) {
  let value = initialValue;
  const subscribers = new Set();

  function getter() {
    if (currentSubscriber) {
      subscribers.add(currentSubscriber);
    }
    return value;
  }

  function setter(newValue) {
    if (value === newValue) return; // if the new value is not different, do not notify dependent effects and memos
    value = newValue;
    for (const subscriber of subscribers) {
      subscriber(); //
    }
  }

  return [getter, setter];
}

// creating an effect
function createEffect(fn) {
  const previousSubscriber = currentSubscriber; // Step 1
  currentSubscriber = fn;
  fn();
  currentSubscriber = previousSubscriber;
}
```

## fine-grained reactivity

Solid の大きな特徴はこの fine-grained reactivity です。

### 同期的更新

### 非同期的更新

## 良いなと思ったところ

- store に見られる fine-grained reactivity により、最小限の記述で必要最小限の変更を行える
- React と違いレンダリングがデフォルトで同期的なので、 UI への変更の反映タイミングについて頭を悩ませることが減りそう
- リアクティビティはすべて一貫して signal が担うというコンセプトがシンプルでわかりやすい

## わからないところ

- 個人的にはコードのトラッキングを行う上で immutablity は捨てたくない。fine-grained reactivity と pure なロジックを、パフォーマンスを失うことなく実現する夢みたいな方法はないのかなと思った。

## まとめ

SolidJS のチュートリアルを読み、理解したことと感じたことをまとめました。現時点では、 signal のシンプルさと、仮想 DOM を使わないことによる同期的な更新が SolidJS の魅力であると感じています。まだチュートリアルを読んだだけなので、これから簡単なアプリを作って色々試していきたいです。
