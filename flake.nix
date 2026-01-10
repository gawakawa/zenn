{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    mcp-servers-nix.url = "github:natsukium/mcp-servers-nix";
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      imports = [
        inputs.treefmt-nix.flakeModule
        inputs.git-hooks-nix.flakeModule
      ];

      perSystem =
        {
          config,
          pkgs,
          system,
          ...
        }:
        let
          textlintWithRules = pkgs.textlint.withPackages [
            pkgs.textlint-rule-preset-ja-technical-writing
            pkgs.textlint-rule-preset-ja-spacing
          ];

          ciPackages = [
            pkgs.zenn-cli
            pkgs.markdownlint-cli2
            textlintWithRules
          ];

          devPackages = ciPackages ++ config.pre-commit.settings.enabledPackages;

          mcpConfig = inputs.mcp-servers-nix.lib.mkConfig (import inputs.mcp-servers-nix.inputs.nixpkgs {
            inherit system;
          }) { programs.nixos.enable = true; };
        in
        {
          packages = {
            ci = pkgs.buildEnv {
              name = "ci";
              paths = ciPackages;
            };

            mcp-config = mcpConfig;
          };

          pre-commit.settings.hooks = {
            treefmt.enable = true;
            statix.enable = true;
            deadnix.enable = true;
            actionlint.enable = true;
            markdownlint = {
              enable = true;
              files = "^(README\\.md|articles/.*\\.md|books/.*\\.md)$";
              entry = "${pkgs.markdownlint-cli2}/bin/markdownlint-cli2";
            };
            textlint = {
              enable = true;
              files = "^(articles/.*\\.md|books/.*\\.md)$";
              entry = "${textlintWithRules}/bin/textlint";
            };
          };

          devShells.default = pkgs.mkShell {
            buildInputs = devPackages;

            shellHook = ''
              ${config.pre-commit.shellHook}
              cat ${mcpConfig} > .mcp.json
              echo "Generated .mcp.json"
            '';
          };

          treefmt = {
            programs = {
              nixfmt = {
                enable = true;
                includes = [ "*.nix" ];
              };
            };
          };
        };
    };
}
