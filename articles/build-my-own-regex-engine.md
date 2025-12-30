---
title: "正規表現の微分を使って正規表現エンジンを自作した"
emoji: "🧩"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: [正規表現]
published: false
---

## はじめに

## 正規表現の微分

今回は正規表現の微分を使って正規表現エンジンを作成します。
正規表現の微分とは、正規表現 $R$ の接頭辞 $u$ を除いたときの言語 $S$ を計算するもので、Brzozowski によって提唱されました[^1]。
実装にあたっては、より実装に即したアルゴリズムを提案している Owens らの論文を参考にしています[^2]。

## 実装

そこまで長いコードでもないのですべてここにのせます。
特にひねったことはせず Brzozowski 微分をそのまま実装に落とし込んでいます。
言語は Lean を使ったのですが、これは証明つきの正規表現エンジンを自作するという目標があるからです。
ゆくゆくは証明つきの正規表現エンジンを作りたいのですが、この実装に Lean で証明をつけられるのかはよくわかっていないので、実装方針自体は変わる可能性があります。
リポジトリは以下です。
https://github.com/gawakawa/regex-engine

### 正規表現の定義

$$
\begin{aligned}
r, s ::= \quad & \emptyset & \text{(empty set)} \\
& \varepsilon & \text{(empty string)} \\
& a & (a \in \Sigma) \\
& r \cdot s & \text{(concatenation)} \\
& r^* & \text{(Kleene closure)} \\
& r \mid s & \text{(or)} \\
& r \mathbin{\&} s & \text{(and)} \\
& \lnot r & \text{(complement)}
\end{aligned}
$$

```lean
inductive Regex : Type where
  | emptySet : Regex
  | epsilon : Regex
  | char : Char → Regex
  | concat : Regex → Regex → Regex
  | star : Regex → Regex
  | or : Regex → Regex → Regex
  | and : Regex → Regex → Regex
  | compl : Regex → Regex
```

視認性のためにエイリアスを張っておきます。

```lean
notation "∅" => Regex.emptySet
notation "ε" => Regex.epsilon
infixl:70 " <> " => Regex.concat
infixl:60 " + " => Regex.or
infixl:65 " & " => Regex.and
postfix:max "*" => Regex.star
prefix:75 "¬" => Regex.compl
```

### 正規表現が空文字列 $\varepsilon$ にマッチするかを判定する関数を定義する

$$
\begin{aligned}
\nu(\varepsilon) &= \text{true} \\
\nu(a) &= \text{false} \\
\nu(\emptyset) &= \text{false} \\
\nu(r \cdot s) &= \nu(r) \land \nu(s) \\
\nu(r \mid s) &= \nu(r) \lor \nu(s) \\
\nu(r^*) &= \text{true} \\
\nu(r \mathbin{\&} s) &= \nu(r) \land \nu(s) \\
\nu(\lnot r) &= \lnot \nu(r)
\end{aligned}
$$

```lean
def nullable (r : Regex) : Bool :=
  match r with
  | .epsilon => true
  | .char _ => false
  | .emptySet => false
  | .concat r₁ r₂ => nullable r₁ && nullable r₂
  | .or r₁ r₂ => nullable r₁ || nullable r₂
  | .star _ => true
  | .and r₁ r₂ => nullable r₁ && nullable r₂
  | .compl r' => !nullable r'
```

### Brzozowski 微分を定義する

$$
\begin{aligned}
\partial_a \varepsilon &= \emptyset \\
\partial_a a &= \varepsilon \\
\partial_a b &= \emptyset \quad (b \neq a) \\
\partial_a \emptyset &= \emptyset \\
\partial_a (r \cdot s) &= \partial_a r \cdot s + \nu(r) \cdot \partial_a s \\
\partial_a (r^*) &= \partial_a r \cdot r^* \\
\partial_a (r \mid s) &= \partial_a r \mid \partial_a s \\
\partial_a (r \mathbin{\&} s) &= \partial_a r \mathbin{\&} \partial_a s \\
\partial_a (\lnot r) &= \lnot (\partial_a r)
\end{aligned}
$$

```lean
def derivative (c : Char) (r : Regex) : Regex :=
  match r with
  | .epsilon => ∅
  | .char c' => if c == c' then ε else ∅
  | .emptySet => ∅
  | .concat r₁ r₂ =>
      let d := derivative c r₁ <> r₂
      if nullable r₁ then d + derivative c r₂ else d
  | .star r' => derivative c r' <> r'*
  | .or r₁ r₂ => derivative c r₁ + derivative c r₂
  | .and r₁ r₂ => derivative c r₁ & derivative c r₂
  | .compl r' => ¬(derivative c r')
```

### 文字列が正規表現にマッチするかを判定する関数を定義する

$$
\begin{aligned}
r \sim \varepsilon &\Leftrightarrow \nu(r) = \text{true} \\
r \sim a \cdot w &\Leftrightarrow \partial_a r \sim w
\end{aligned}
$$

```lean
def accept (r : Regex) (s : String) : Bool :=
  nullable $ s.foldl (flip derivative) r
```

## まとめ

## 余談

Brzozowski 微分は正規表現の NFA を手書きで構築するときに結構便利です。
言語処理系の定期試験で裏技的に使えるので、学生の方はぜひ使ってみてください。

[^1]: https://dl.acm.org/doi/10.1145/321239.321249
[^2]: https://www.cambridge.org/core/journals/journal-of-functional-programming/article/regularexpression-derivatives-reexamined/E5734B86DEB96C61C69E5CF3C4FB0AFA#article
