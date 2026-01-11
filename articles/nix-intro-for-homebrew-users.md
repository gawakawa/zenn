---
title: "Homebrew ユーザーのための Nix 入門"
emoji: "🍺"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: [nix, homebrew, mac]
published: false
---

## はじめに

Nix に興味はあるものの難しそうでなかなか手が出せないという人は多いでしょう。本記事ではそんな思いを持つ Mac ユーザー、とりわけ Homebrew を使ってパッケージを管理している方々のために、**Homebrew を Nix で管理する**方法をご紹介します。この方法であれば Homebrew によるパッケージ管理を継続しつつ Nix に手軽に入門できます。

## 対象読者

- [x] Nix に今すぐ移行するつもりはないが、ちょっと試してみたい人
- [x] Homebrew を使っている Mac ユーザー
- [x] Nix を触ったことがない人
- [ ] Windows / Linux ユーザー
- [ ] すでに自分で Nix の設定をしたことがある人

## 今回紹介する方法の特徴

- Homebrew の管理は継続
- 既存の設定には一切影響なし
- Nix のメリットは薄め[^1]

## 動作環境

- Macbook Air (Apple M2)
- macOS Tahoe 26.2

## やり方

### 1. Lix で Nix をインストールする

[公式サイト](https://lix.systems/)にしたがって Nix をインストールします。

```bash
curl -sSf -L https://install.lix.systems/lix | sh -s -- install
```

インストール中に Flake を有効化するか聞かれますが、Yes と回答してください。Flake は `flake.lock` で依存関係を固定し、環境の再現性を保証する機能です。experimental feature ですが、デファクトスタンダードになっているので有効化しておきましょう。
インストールが完了したら、別ターミナルを立ち上げて確認します。

```bash
nix --version
```

エラーが出なければ、Nix のインストールは完了です。

### 2. nix-darwin を導入する

次に、nix-darwin のインストールを行います。nix-darwin は macOS を宣言的に管理するためのツールです。
こちらも [nix-darwin の公式リポジトリ](https://github.com/nix-darwin/nix-darwin?tab=readme-ov-file#getting-started)の説明に沿って設定を進めてください。なお、ここでも Flake ベースの設定と Channel ベースの設定の 2 通りが書かれていますが、Flake ベースの設定を選択しましょう。

#### 1. `flake.nix` を作成する

```bash
sudo mkdir -p /etc/nix-darwin
sudo chown $(id -nu):$(id -ng) /etc/nix-darwin
cd /etc/nix-darwin

nix flake init -t nix-darwin/master

sed -i '' "s/simple/$(scutil --get LocalHostName)/" flake.nix
```

#### 2. `nix-darwin` をインストールする

```bash
sudo nix run "nix-darwin/master#darwin-rebuild" -- switch
```

:::message
zsh を使っている場合 `#` が特殊文字として扱われるので `nix-darwin/master#darwin-rebuild` をダブルクォーテーションで囲ってください。nix-darwin の README に記載されているコマンドをコピペして実行するとエラーになるので気をつけてください。
:::

#### 3. nix-darwin の設定をシステムに適用する

これまでの変更をシステムに反映させます。

```bash
sudo darwin-rebuild switch
```

次に、`configuration.nix` を作成し、`flake.nix` を編集して、flake の `inputs` を設定ファイルで利用できるようにします。

`/etc/nix-darwin/configuration.nix` を作成し、以下の内容を記述します。

```nix
# in /etc/nix-darwin/configuration.nix
{ pkgs, lib, inputs, ... }:
# inputs.self, inputs.nix-darwin, inputs.nixpkgs にここからアクセスできる
{
  # ここに設定を記述していく
}
```

次に `/etc/nix-darwin/flake.nix` を編集して、`specialArgs` を追加します。

```nix
# in /etc/nix-darwin/flake.nix
nix-darwin.lib.darwinSystem {
  modules = [ ./configuration.nix ];
  specialArgs = { inherit inputs; };
}
```

### 3. 設定ファイルをユーザーディレクトリにコピーする ( オプション )

せっかく宣言的なパッケージ管理をするのですから git 管理でバージョン管理したいです。しかし `/etc/` にあるファイルを git 管理したくはないのでホームディレクトリ以下に設定ファイルを移行します。なお、 `/etc/nix-darwin/` で設定しても特に問題はないのでこの手順はスキップしても構いません。

```bash
mkdir -p ~/.config
cp -r /etc/nix-darwin ~/.config
cd ~/.config/nix-darwin
git init
```

リポジトリの初期化ができたら GitHub にでもあげておけば、突然 Mac が壊れても安心です。

以降は `flake` オプションで絶対パスを指定した `darwin-rebuild switch --flake ~/.config/nix-darwin` コマンドを実行することで設定を適用できます。

### 4. `configuration.nix` を編集して Homebrew を Nix で管理する

`configuration.nix` を開いて、以下の内容を貼り付けてください。ユーザー名に mac で設定しているユーザー名を指定し、`brews`, `casks` に Homebrew で管理しているパッケージを列挙していきます。

```nix
# in configuration.nix
{ pkgs, lib, ... }:
{
  system = {
    stateVersion = 6;
    # mac のユーザー名
    # `whoami` で確認可能
    primaryUser = "<ユーザー名>";
  };

  nixpkgs = {
    config.allowUnfree = true;
    hostPlatform = "aarch64-darwin";
  };

  homebrew = {
    enable = true;
    onActivation.cleanup = "none";
    # `brew tap` で確認可能
    taps = [ ];
    # `brew list --formula` で確認可能
    brews = [
      "git"
      "gnu-time"
    ];
    # `brew list --cask` で確認可能
    casks = [
      "claude"
      "visual-studio-code"
    ];
  };
}
```

:::message alert
**`onActivation.cleanup` について**

この設定は `darwin-rebuild switch` 実行時に、`configuration.nix` に書かれていないパッケージをどう扱うかを制御します。

- `"none"` (デフォルト): Nix で管理していないパッケージはそのまま残る
- `"uninstall"`: `configuration.nix` に書かれていないパッケージを削除
- `"zap"`: 削除に加え、cask 関連の全ファイルも削除

宣言性を維持したい場合は `"uninstall"` に設定すると、`configuration.nix` に書かれたものだけがインストールされた状態を保証できます。ただしこの設定にしておくと誤って homebrew で管理されたパッケージを削除してしまう可能性があるので注意が必要です。例えば、すでに `python` と `docker` が Homebrew でインストール済みの状態で `configuration.nix` に `git` だけが書かれているような状況を仮定します。この状態で rebuild すると、Homebrew から `python` と `docker` は削除され、`git` だけがインストールされた状態になってしまいます。

まず `"none"` で運用し、全ての既存パッケージを `configuration.nix` に記述したのを確認してから `"uninstall"` に変更することをお勧めします。

リファレンス : https://mynixos.com/nix-darwin/option/homebrew.onActivation.cleanup
:::

編集が完了したら変更をシステムに反映させます。

```bash
# /etc/nix-darwin/ の設定を反映する場合
sudo darwin-rebuild switch

# ~/.config/nix-darwin/ の設定を反映する場合
sudo darwin-rebuild switch --flake ~/.config/nix-darwin
```

これで、Homebrew が Nix の管理下に入りました。今後は `configuration.nix` の `brews` や `casks` を編集して `sudo darwin-rebuild switch` を実行すれば、パッケージの追加や削除ができます。

なお、従来通り `brew` コマンドでもパッケージの追加や削除は可能ですが、`configuration.nix` に自動でパッケージが追加されることはありません。宣言性を維持したい場合は `configuration.nix` の編集で管理することをお勧めします。

## 次にやること

Homebrew を Nix で管理できるようになったら、次のステップに進んでみましょう。

- Homebrew で管理しているパッケージを nixpkgs に置き換える
- Flake で開発環境を構築する
- dotfiles を Home Manager で管理する

日本語の解説記事も充実してきているので、参考にしてみてください。

https://zenn.dev/asa1984/articles/nixos-is-the-best
https://zenn.dev/comamoca/articles/2025-02-09-start-to-use-nix-flake-by-one-file
https://syu-m-5151.hatenablog.com/entry/2025/12/18/111500

## まとめ

本記事では、Homebrew を Nix で管理する方法を紹介しました。nix-darwin を使えば、既存の Homebrew 環境を維持したまま Nix の宣言的な設定管理を試すことができます。この記事をきっかけに Nix 導入を試してみる Homebrew ユーザーが増えてくれると嬉しいです。

## 参考

https://lix.systems/
https://github.com/nix-darwin/nix-darwin?tab=readme-ov-file
https://mynixos.com/nix-darwin/options/homebrew

[^1]: この方法で実現できるのは、Homebrew の設定を Nix の設定ファイル上に書き起こせることだけです。Nix の掲げる 3 つの特徴 **再現性 (Reproducible)**、**宣言性 (Declarative)**、**信頼性 (Reliable)** のうち、宣言性しか満たせていません。再現性、信頼性も含む Nix の威力を体感したい場合は、さらに設定を進める必要があります。
