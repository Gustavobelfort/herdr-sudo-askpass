{
  description = "herdr plugin: ask for sudo passwords in a pane beside the agent";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      forAll =
        f:
        nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ] (
          system: f nixpkgs.legacyPackages.${system}
        );
    in
    {
      # The plugin directory itself, for `herdr plugin link` from a Nix config.
      # Runtime commands are resolved from PATH at run time, as herdr expects.
      packages = forAll (pkgs: {
        default = pkgs.runCommand "herdr-sudo-askpass" { } ''
          mkdir $out
          cp ${./herdr-plugin.toml} $out/herdr-plugin.toml
          cp ${./askpass.sh} ${./prompt.sh} ${./install-shim.sh} $out/
        '';
      });

      devShells = forAll (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            gnumake
            shellcheck
            shfmt
            zizmor
          ];
        };
      });

      checks = forAll (pkgs: {
        default =
          pkgs.runCommand "herdr-sudo-askpass-check"
            {
              nativeBuildInputs = with pkgs; [
                gnumake
                shellcheck
                shfmt
                procps
              ];
            }
            ''
              cp -r ${self} src && chmod -R u+w src && cd src
              patchShebangs .
              make lint fmt-check test
              touch $out
            '';
      });

      formatter = forAll (pkgs: pkgs.nixfmt-rfc-style);
    };
}
