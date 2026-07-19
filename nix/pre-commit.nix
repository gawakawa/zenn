_: {
  perSystem =
    { pkgs, ... }:
    let
      textlintWithRules = pkgs.textlint.withPackages [
        pkgs.textlint-rule-preset-ja-technical-writing
        pkgs.textlint-rule-preset-ja-spacing
      ];
    in
    {
      pre-commit.settings.hooks = {
        treefmt.enable = true;
        statix.enable = true;
        deadnix.enable = true;
        actionlint.enable = true;
        zizmor = {
          enable = true;
          args = [ "--offline" ];
        };
        workflow-timeout = {
          enable = true;
          name = "Check workflow timeout-minutes";
          package = pkgs.check-jsonschema;
          entry = "${pkgs.check-jsonschema}/bin/check-jsonschema --builtin-schema github-workflows-require-timeout";
          files = "\\.github/workflows/.*\\.ya?ml$";
        };
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
    };
}
