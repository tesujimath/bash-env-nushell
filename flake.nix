{
  description = "nu_plugin_bash_env";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    bash-env-json = {
      url = "github:tesujimath/bash-env-json/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, flake-utils, bash-env-json, ... }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };

          inherit (pkgs) lib stdenvNoCC;
          flakePkgs = {
            bash-env-json = bash-env-json.packages.${system}.default;
          };

          bash-env-module-with-bash-env-json = stdenvNoCC.mkDerivation
            {
              name = "bash-env.nu-with-bash-env-json";
              src = ./bash-env.nu;
              dontUnpack = true;
              preferLocalBuild = true;
              allowSubstitutes = false;

              buildPhase = ''
                runHook preBuild
                mkdir -p "$out"
                substitute "$src" "$out/bash-env.nu" --replace-fail ${lib.escapeShellArg "bash-env-json"} ${lib.escapeShellArg "${flakePkgs.bash-env-json}/bin/bash-env-json"}
                runHook postBuild
              '';
            };
        in
        {
          devShells.default =
            let
              inherit (pkgs)
                mkShell
                bashInteractive
                jq
                nushell;
            in

            mkShell {
              nativeBuildInputs = [
                bashInteractive
                jq
                nushell
              ];
            };

          packages = {
            default = bash-env-module-with-bash-env-json;
            module = bash-env-module-with-bash-env-json;
          };
        }
      );
}
