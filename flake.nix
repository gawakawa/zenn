{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix.url = "github:numtide/treefmt-nix";
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

          checks = {
            statix =
              pkgs.runCommandLocal "statix"
                {
                  src = ./.;
                  nativeBuildInputs = [ pkgs.statix ];
                }
                ''
                  cd $src
                  statix check .
                  mkdir "$out"
                '';

            deadnix =
              pkgs.runCommandLocal "deadnix"
                {
                  src = ./.;
                  nativeBuildInputs = [ pkgs.deadnix ];
                }
                ''
                  cd $src
                  deadnix --fail .
                  mkdir "$out"
                '';

            markdownlint =
              pkgs.runCommandLocal "markdownlint"
                {
                  src = ./.;
                  nativeBuildInputs = [ pkgs.markdownlint-cli2 ];
                }
                ''
                  cd $src
                  markdownlint-cli2 "articles/**/*.md" "books/**/*.md"
                  mkdir "$out"
                '';
          };

          treefmt = {
            programs = {
              nixfmt.enable = true;
            };
          };
        };
    };
}
