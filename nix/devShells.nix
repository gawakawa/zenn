{ inputs, ... }:
{
  perSystem =
    {
      config,
      pkgs,
      system,
      ...
    }:
    let
      devPackages =
        config.ciPackages
        ++ config.pre-commit.settings.enabledPackages
        ++ (with pkgs; [
          # Additional development tools can be added here
        ]);

      mcpConfig =
        inputs.mcp-servers-nix.lib.mkConfig
          (import inputs.mcp-servers-nix.inputs.nixpkgs { inherit system; })
          {
            programs.nixos.enable = true;
          };
    in
    {
      packages.mcp-config = mcpConfig;

      devShells.default = pkgs.mkShell {
        buildInputs = devPackages;

        shellHook = ''
          ${config.pre-commit.shellHook}
          cat ${mcpConfig} > .mcp.json
          echo "Generated .mcp.json"
        '';
      };
    };
}
