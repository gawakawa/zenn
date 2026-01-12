---
title: "Claude Code のユーザー設定を Home Manager で管理する"
emoji: "🏠"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: [nix, claudecode, claude]
published: true
---

## はじめに

Claude Code のユーザー設定を Home Manager で宣言的に管理する方法を紹介します。他の dotfiles 管理にも応用できるので参考にしてみてください。

## 前提知識

### Claude Code のスコープシステム

Claude Code の設定ファイルには複数のスコープがあります。例えば設定ファイルを `~/.claude/` に配置すると全プロジェクトにその設定が適用され、`<project-root>/.claude/` に配置するとそのプロジェクトにのみ適用されます。
本記事では前者のユーザースコープの設定を Home Manager で管理します。

### Home Manager

Home Manager は Nix を使ってユーザー環境を宣言的に管理するツールです。パッケージのインストールや dotfiles の配置を Nix の設定ファイルで一元管理できます。
本記事では Home Manager の `home.file` オプションを使い、Claude Code の設定ファイルをホームディレクトリ配下にシンボリックリンクとして配置します。

## 設定

本記事では Home Manager が導入済みであることを前提とします。まだ導入していない方は以下の記事を参考に設定してみてください。
https://zenn.dev/asa1984/articles/nixos-is-the-best#home-manager
また、上記記事にならって Home Manager の設定は `home.nix` で管理しているものとして話を進めます。

前節で紹介した `home.file` オプションを使って、Claude Code の設定ファイルを `~/.claude/` 配下にシンボリックリンクとして配置します。完成形のディレクトリ構造のイメージは以下のようになります。

```bash
.
├── home.nix        # Home Manager のエントリーポイント
└── claude/         # Claude Code 設定ファイル群
    ├── default.nix # Claude Code 設定用モジュール
    ├── settings.json
    ├── CLAUDE.md
    ├── statusline.sh
    ├── agents/
    ├── skills/
    ├── rules/
    └── commands/
```

`claude/default.nix` で `home.file` を使い、ソースファイルと配置先のマッピングを定義します。

```nix:claude/default.nix
{
  home.file = {
    ".claude/settings.json".source = ./settings.json;
    ".claude/CLAUDE.md".source = ./CLAUDE.md;
    ".claude/agents" = {
      source = ./agents;
      recursive = true;
    };
    ".claude/skills" = {
      source = ./skills;
      recursive = true;
    };
    ".claude/rules" = {
      source = ./rules;
      recursive = true;
    };
    ".claude/commands" = {
      source = ./commands;
      recursive = true;
    };
    ".claude/statusline.sh" = {
      source = ./statusline.sh;
      executable = true;
    };
  };
}
```

ディレクトリの場合は `recursive = true` で中身を再帰的にリンクし、スクリプトには `executable = true` で実行権限を付与します。

`home.nix` でこのモジュールを import すれば設定完了です。

```nix:home.nix
{ ... }:
{
  imports = [
    ./claude
  ];
}
```

`home-manager switch` を実行すると、`~/.claude/` 配下に設定ファイルがシンボリックリンクとして配置されます。

## まとめ

Home Manager の `home.file` を使って Claude Code のユーザー設定を管理する方法を紹介しました。`.claude/` 以外の dotfiles もこの方法を使ってどんどん Nix で設定していきましょう。良い Nix ライフを！

## 参考

- Claude Code の設定方法の公式マニュアル

https://code.claude.com/docs/en/settings

- Home Manager の `home.file` についてのマニュアル

https://nix-community.github.io/home-manager/options.xhtml#opt-home.file

- Home Manager の設定方法について書かれているユーザー記事

https://zenn.dev/trifolium/articles/642043cbae5f21
https://zenn.dev/kuu/articles/20250204_introduce-home-manager
https://zenn.dev/asa1984/articles/nixos-is-the-best
