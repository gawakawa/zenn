---
title: "mcp-servers-nix を導入してみた"
emoji: "❄️"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: []
published: false
---

## はじめに

MCP サーバーの設定を [mcp-servers-nix](https://github.com/natsukium/mcp-servers-nix) というツールを用いて Nix で管理できるようにしました。mcp-servers-nix については、作者の natsukium さんが[記事](https://zenn.dev/natsukium/articles/f010c1ec1c51b2)をあげているので、詳しくはそちらをご覧ください。

## 動機

MCP サーバーの実行形式はまちまちです。例えば、GitHub MCP, Serena MCP, NixOS MCP の 3 つを使う場合、.mcp.json は以下のようになります。

```json

```

uv, docker, nix, command など様々な形式が入り乱れていますね。

## 設定方法

mcp=servers-nix を使った flake.nix を見ていきます。

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    mcp-servers-nix.url = "github:natsukium/mcp-servers-nix";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      imports = [ inputs.treefmt-nix.flakeModule ];

      perSystem =
        {
          pkgs,
          system,
          ...
        }:
        let
          mcpConfig = inputs.mcp-servers-nix.lib.mkConfig pkgs {
            programs = {
              nixos.enable = true;
            };
          };
        in
        {
          packages = {
            mcp-config = mcpConfig;
          };

          devShells.default = pkgs.mkShell {
            buildInputs = with pkgs; [
              zenn-cli
            ];

            shellHook = ''
              cat ${mcpConfig} > .mcp.json
              echo "Generated .mcp.json"
            '';
          };
        };
    };
}
```

これだけで。
