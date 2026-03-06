{
  description = "Deotonic — Deontic logic framework in Haskell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      ghc = pkgs.haskell.compiler.ghc967;
      hpkgs = pkgs.haskell.packages.ghc967;
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          ghc
          hpkgs.cabal-install
          hpkgs.hspec-discover
          hpkgs.haskell-language-server
          pkgs.overmind
          pkgs.tmux
        ];
      };
    };
}
