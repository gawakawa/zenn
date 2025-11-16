---
title: "正規表現エンジンを自作した"
emoji: "🧩"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: [正規表現]
published: false
---

## はじめに

## 正規表現の微分
今回は正規表現の微分を使って正規表現エンジンを作成します。
正規表現の微分とは、 正規表現 $R$ の接頭辞 $u$ を除いたときの言語 $S$ を計算するもので、 Brzozowski によって提唱されました^[https://dl.acm.org/doi/10.1145/321239.321249]。
実装にあたっては、より実装に即したアルゴリズムを提案している Owens ら^[https://www.cambridge.org/core/journals/journal-of-functional-programming/article/regularexpression-derivatives-reexamined/E5734B86DEB96C61C69E5CF3C4FB0AFA#article]の論文を参考にしています。

## 実装
そこまで長いコードでもないのですべてここにのせてしまおうと思います。
特にひねったことはせず Brzozowski 微分をそのまま実装に落とし込んでいます。
言語は Lean を使ったのですが、これは証明つきの正規表現エンジンを自作するという目標があるからです。
ゆくゆくは証明つきの正規表現エンジンを作りたいと思っているのですが、この実装に Lean で証明をつけられるのかはよくわかっていないので、実装方針自体は変わるかもしれません。
リポジトリは https://github.com/gawakawa/regex-engine です。

### 微分の定義

```lean
/--
Definition of Regular Expressions

r, s ::= ∅     empty set
         ε     empty string
         a     a ∈ Σ
         r · s concatenation
         r*    Kleene-closure
         r | s logical or
         r & s logical and
         ¬r    complement
-/
inductive Regex : Type where
  | emptySet : Regex
  | epsilon : Regex
  | char : Char → Regex
  | concat : Regex → Regex → Regex
  | star : Regex → Regex
  | or : Regex → Regex → Regex
  | and : Regex → Regex → Regex
  | compl : Regex → Regex
  deriving DecidableEq

notation "∅" => Regex.emptySet
notation "ε" => Regex.epsilon
infixl:70 " <> " => Regex.concat
infixl:60 " + " => Regex.or
infixl:65 " & " => Regex.and
postfix:max "*" => Regex.star
prefix:75 "¬" => Regex.compl

/--
Check if a regex accepts the empty string

ν(ε)     = true
ν(a)     = false
ν(∅)     = false
ν(r · s) = ν(r) ∧ ν(s)
ν(r | s) = ν(r) ∨ ν(s)
ν(r*)    = true
ν(r & s) = ν(r) ∧ ν(s)
ν(¬r)    = ¬ν(r)
-/
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

/--
Brzozowski Derivative

∂ₐε       = ∅
∂ₐa       = ε
∂ₐb       = ∅ for b ≠ a
∂ₐ∅       = ∅
∂ₐ(r · s) = ∂ₐr · s + ν(r) · ∂ₐs
∂ₐ(r*)    = ∂ₐr · r*
∂ₐ(r | s) = ∂ₐr | ∂ₐs
∂ₐ(r & s) = ∂ₐr & ∂ₐs
∂ₐ(¬r)    = ¬(∂ₐr)
-/
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

/--
Check if regex r matches string s

r ∼ ε ↔ ν(r) = true
r ∼ a · w ↔ ∂ₐr ∼ w
-/
def accept (r : Regex) (s : String) : Bool :=
  nullable $ s.foldl (flip derivative) r
```

## まとめ

## 余談
Brzozowski 微分は正規表現の NFA を手書きで構築するときに結構便利です。
言語処理系の定期試験で裏技的に使えるので、学生の方はぜひ使ってみてください。
