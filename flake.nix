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

      # Build Haskell packages with haddock
      deontic-core = hpkgs.callCabal2nix "deontic-core" ./deontic-core {};
      deontic-kr-civil = hpkgs.callCabal2nix "deontic-kr-civil" ./deontic-kr-civil {
        inherit deontic-core;
      };
      deontic-de-bgb = hpkgs.callCabal2nix "deontic-de-bgb" ./deontic-de-bgb {
        inherit deontic-core;
      };

      mkdocs-env = pkgs.python3.withPackages (ps: [
        ps.mkdocs
        ps.mkdocs-material
        ps.pymdown-extensions
      ]);

      # Nix derivation: build complete static site (mkdocs + haddock)
      mkdocs-site = pkgs.stdenv.mkDerivation {
        pname = "deontic-docs";
        version = "0.2.0";
        src = pkgs.lib.sourceByRegex ./. [
          "mkdocs.yml"
          "docs"
          "docs/.*"
          "docs/.*/.*"
        ];
        nativeBuildInputs = [ mkdocs-env ];
        buildPhase = ''
          ${mkdocs-env}/bin/mkdocs build -d _site
        '';
        installPhase = ''
          mv _site $out

          # Copy haddock docs
          mkdir -p $out/reference/haddock
          ${pkgs.lib.concatMapStringsSep "\n" (drv:
            let name = drv.pname; in ''
              docdir=$(find "${drv.doc}/share/doc" -maxdepth 1 -type d -name "${name}*" | head -1)
              if [ -n "$docdir" ] && [ -d "$docdir/html" ]; then
                cp -r "$docdir/html" "$out/reference/haddock/${name}"
                echo "Copied haddock for ${name} from $docdir"
              else
                echo "Warning: haddock output not found for ${name}"
                find "${drv.doc}" -name "*.html" | head -5 || true
              fi
            ''
          ) [ deontic-core deontic-kr-civil deontic-de-bgb ]}
        '';
      };
    in
    {
      packages.${system} = {
        inherit deontic-core deontic-kr-civil deontic-de-bgb;
        mkdocs = mkdocs-site;
        default = mkdocs-site;
      };

      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          ghc
          hpkgs.cabal-install
          hpkgs.hspec-discover
          hpkgs.haskell-language-server
          mkdocs-env
          pkgs.overmind
          pkgs.tmux
        ];
      };
    };
}
