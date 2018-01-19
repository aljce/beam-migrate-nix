{ package ? "beam-migrate-nix", allow-shell ? true }:
let
  fetchNixpkgs = import ./nix/fetchNixpkgs.nix;
  nixpkgs-src = fetchNixpkgs {
    rev = "5c73ee1a9375d225a66a4fd469fc82e59a2d7414";
    sha256 = "1x577rg8q4zlxd77kpyppbx87d47j1q165yz1ps7d7894gcy7nb5";
  };
  nixpkgs = import nixpkgs-src { config = {}; };
  beam-commit = builtins.fromJSON (builtins.readFile ./nix/beam.json);
  beam = nixpkgs.fetchFromGitHub {
    owner = "tathougies";
    repo  = "beam";
    inherit (beam-commit) rev sha256;
  };
  overrides = nixpkgs.haskellPackages.override {
    overrides = self: super: with nixpkgs.haskell.lib; {
      # Deps
      beam-core = self.callCabal2nix "beam-core" (builtins.toPath "${beam}/beam-core") {};
      beam-migrate = self.callCabal2nix "beam-migrate" (builtins.toPath "${beam}/beam-migrate") {};
      beam-migrate-cli = self.callCabal2nix "beam-migrate-cli" (builtins.toPath "${beam}/beam-migrate-cli") {};
      beam-postgres = self.callCabal2nix "beam-postgres" (builtins.toPath "${beam}/beam-postgres") {};
      # This project
      beam-migrate-nix = self.callCabal2nix "beam-migrate-nix" ./. {};
    };
  };
  drv = overrides.${package};
in
if allow-shell && nixpkgs.lib.inNixShell then
  drv.env
else
  drv
