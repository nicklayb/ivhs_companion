{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    let
      nixosModule = import ./nixosModule.nix {
        inherit self;
      };
    in
    (flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        erlangPackages = pkgs.beam29Packages;
        erlang = erlangPackages.erlang;
        elixir = erlangPackages.elixir_1_20;
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            erlang
            elixir
            erlangPackages.expert
            pkgs.direnv
            pkgs.just
          ];

          shellHook = ''
            export MIX_HOME=$PWD/.nix-mix
            export HEX_HOME=$PWD/.nix-hex

            eval "$(direnv hook bash)"
            direnv allow
            mix deps.get
          '';
        };
        packages.default =
          let
            version = "0.1.0";
            src = ./.;
            mixNixDeps = pkgs.callPackages ./deps.nix { };
          in
          erlangPackages.mixRelease {
            inherit version src mixNixDeps;
            pname = "ivhs-companion";
            buildInputs = [ ];
          };
      }
    ))
    // {
      nixosModules.default = nixosModule;
    };
}
