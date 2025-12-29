---
title: "Lean の Unicode 入力を Neovim で再現する"
emoji: "⌨️"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: [neovim, nix, lean4]
published: true
---

## はじめに

Lean の Unicode 入力って便利ですよね。`\vdash` と入力すると `⊢` に変換されるあれです。Lean 以外でもプログラミング中にこのような補完が効くとうれしいかなと思ったので、Neovim の設定で入れました。

## 実現したいこと

- トリガーを入力すると Unicode 文字に即時展開される
  - 例：`\vdash` → `⊢`
- 補完メニューからも選択できる
- Lean と同じような操作感にする

## 実装

実装の概要について順を追って説明します。より良い実装があればコメントで教えてくださるとうれしいです。

### 0. 前提

最初に私の Neovim の設定について軽く説明します。

- Nix で設定を管理
- スニペットエンジンとして LuaSnip を使用
- LuaSnip を nvim-cmp と連携させて補完にも使用

ちなみに Nix で Neovim を管理する方法については、以下を参考にしました。プラグインの依存関係の管理が非常に楽になるのでおすすめです。

https://zenn.dev/natsukium/articles/b4899d7b1e6a9a
https://github.com/asa1984/asa1984.nvim

### 1. 置換を入れてみる

まず LuaSnip の autosnippet 機能を使って、スニペットの即時展開を実装します。Lean の挙動に合わせてスペースで展開が確定するようにしました。これにより、`\vdash` を入力しようとしたとき `\v` のスニペットが意図せず展開されてしまうようなことを防げます。

```lua:luasnip.lua
local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node

ls.config.setup({
  enable_autosnippets = true,
})

-- \vdash + スペースで ⊢ に展開
ls.add_snippets("all", {
  s({ trig = "\\vdash ", snippetType = "autosnippet" }, { t("⊢") }),
})
```

### 2. 補完メニューにも対応する

autosnippet だけでなく snippets にも登録することで、補完メニューからも選択できるようにします。

```lua:luasnip.lua
local snippets = {}
local autosnippets = {}

-- Regular snippet（補完メニューに表示）
table.insert(snippets, s({ trig = "\\vdash", desc = "⊢" }, { t("⊢") }))
-- Autosnippet（スペースで即時展開）
table.insert(autosnippets,
  s({ trig = "\\vdash ", snippetType = "autosnippet" }, { t("⊢") }))

ls.add_snippets("all", snippets)
ls.add_snippets("all", autosnippets)
```

### 3. abbreviations テーブルで対応を管理する

複数の abbreviation を追加するため、置換をテーブルで管理します。

```lua:luasnip.lua
local abbreviations = {
  ["\\vdash"] = "⊢",
  ["\\alpha"] = "α",
  ["\\Rightarrow"] = "⇒",
  -- ... 追加したいものを列挙
}

for trigger, symbol in pairs(abbreviations) do
  table.insert(snippets, s({ trig = trigger, desc = symbol }, { t(symbol) }))
  table.insert(autosnippets, s({ trig = trigger .. " ", snippetType = "autosnippet" }, { t(symbol) }))
end
```

### 4. abbreviations テーブルを Lean の実装に依存させる

ここまででも良いのですが、せっかくなら Lean と全く同じ挙動を再現しようと思い、abbreviations テーブルの定義を Lean の実装へ依存させることにしました。Lean の abbreviation は以下のファイルで定義されています。

https://github.com/leanprover/vscode-lean4/blob/master/lean4-unicode-input/src/abbreviations.json

これを flake の input に追加し、ビルド時に JSON を Lua テーブルに変換します。まず flake.nix の inputs に vscode-lean4 を追加します。

```nix:flake.nix
inputs = {
  # ... 他の inputs ...
  vscode-lean4 = {
    url = "github:leanprover/vscode-lean4";
    flake = false;
  };
};
```

次に、Neovim のラッパーを作成する derivation 内で JSON を Lua テーブルに変換します。私の設定では `make-neovim-wrapper.nix` というファイルで Neovim パッケージを構築しています。

```nix:make-neovim-wrapper.nix
leanAbbreviations = pkgs.stdenv.mkDerivation {
  name = "lean-abbreviations";
  src = "${vscode-lean4}/lean4-unicode-input/src/abbreviations.json";

  nativeBuildInputs = [ pkgs.jq ];
  dontUnpack = true;

  buildPhase = ''
    ${pkgs.jq}/bin/jq -r '
      to_entries
      | map("  [" + ("\\"+.key | @json) + "] = " + (.value | @json))
      | "return {\n" + join(",\n") + "\n}"
    ' < $src > lean_abbreviations.lua
  '';

  installPhase = ''
    mkdir -p $out
    cp lean_abbreviations.lua $out/
  '';
};
```

これで `nix flake update` を実行して flake.lock を更新し、再ビルドすると最新の abbreviations が適用されるようになります。

```lua:luasnip.lua
local ok, abbreviations = pcall(require, "data.lean_abbreviations")
if not ok then
  vim.notify("Failed to load Lean abbreviations", vim.log.levels.WARN)
  return
end

for trigger, symbol in pairs(abbreviations) do
  table.insert(snippets, s({ trig = trigger, desc = symbol }, { t(symbol) }))
  table.insert(autosnippets, s({ trig = trigger .. " ", snippetType = "autosnippet" }, { t(symbol) }))
end
```

### 5. `$CURSOR` に対応する

ここまでの実装では 1 つ問題があります。`$CURSOR` を含むエントリの取り扱いです。

```json:abbreviations.json
{
  "<>": "⟨$CURSOR⟩",
  "floor": "⌊$CURSOR⌋"
}
```

これは VSCode 拡張で使われる記法であり、展開後にカーソルを配置したい位置を示します。例えば `\<>` と入力すると `⟨⟩` に展開され、カーソルが括弧の間に配置されます。`$CURSOR` を LuaSnip の `insert_node` へ変換すれば、展開後のカーソルが括弧内へ配置されるようになります。

```lua:luasnip.lua
local i = ls.insert_node

local function make_nodes(symbol)
  local prefix, suffix = symbol:match("^(.-)%$CURSOR(.*)$")
  if prefix then
    return { t(prefix), i(1), t(suffix) }
  else
    return { t(symbol) }
  end
end

for trigger, symbol in pairs(abbreviations) do
  table.insert(snippets, s({ trig = trigger, desc = symbol }, make_nodes(symbol)))
  table.insert(autosnippets, s({ trig = trigger .. " ", snippetType = "autosnippet" }, make_nodes(symbol)))
end
```

## まとめ

Lean の abbreviations を Neovim でも使えるようにしました。コメントで論理記号を書くときやギリシャ文字を入力したいときに便利なので、ぜひ使ってみてください。実装の全体は以下のリポジトリを参照してください。

https://github.com/gawakawa/nvim
