_: {
  perSystem = _: {
    treefmt = {
      programs = {
        nixfmt = {
          enable = true;
          includes = [ "*.nix" ];
        };
        oxfmt = {
          enable = true;
          includes = [
            "*.json"
            "*.jsonc"
            "*.json5"
            "*.yaml"
            "*.yml"
          ];
        };
      };
    };
  };
}
