{
  description = "FreeFEM++ built from source";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f:
        nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      mkFreefem = pkgs: pkgs.stdenv.mkDerivation (finalAttrs: {
        pname = "freefem";
        version = "4.17";

        src = pkgs.fetchFromGitHub {
          owner = "FreeFem";
          repo = "FreeFem-sources";
          rev = "v${finalAttrs.version}";
          hash = "sha256-tfF6eBstV4ac2+ZSQDZxSkGMcEC6ztaehzb9fcvSsAQ=";
        };

        nativeBuildInputs = with pkgs; [
          autoreconfHook
          pkg-config
          bison
          flex
          m4
          perl
          python3
          gfortran
          makeWrapper
          unzip
          cmake
        ];

        buildInputs = with pkgs; [
          blas
          lapack
          arpack
          suitesparse   # UMFPACK
          fftw
          gsl
          hdf5
          zlib
          freeglut      # ffglut (plot window)
          libGL
          libGLU
          libx11
          libxext
        ];

        postPatch = ''
          patchShebangs .
        '';

        configureFlags = [
          "--disable-download"  # no network access in the Nix sandbox
          "--without-mpi"
          "--without-petsc"
          "--enable-generic"    # portable binary, no -march=native
        ];

        # cmake is only a tool FreeFEM checks for; keep the autotools build
        dontUseCmakeConfigure = true;

        enableParallelBuilding = true;
        doCheck = false;  # the full test suite takes a very long time

        # Make sure FreeFem++ can find ffglut even when run via `nix run`
        postInstall = ''
          for prog in $out/bin/FreeFem++*; do
            wrapProgram "$prog" --prefix PATH : "$out/bin"
          done
        '';

        meta = with pkgs.lib; {
          description = "PDE solver using the finite element method";
          homepage = "https://freefem.org";
          license = licenses.lgpl3Plus;
          platforms = platforms.linux;
          mainProgram = "FreeFem++";
        };
      });
    in
    {
      packages = forAllSystems (pkgs: rec {
        freefem = mkFreefem pkgs;
        default = freefem;
      });

      apps = forAllSystems (pkgs: {
        default = {
          type = "app";
          program = "${self.packages.${pkgs.stdenv.hostPlatform.system}.freefem}/bin/FreeFem++";
        };
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [
            self.packages.${pkgs.stdenv.hostPlatform.system}.freefem
            pkgs.gnuplot
          ];
          shellHook = ''
            echo "FreeFEM++ environment ready. Try: FreeFem++ example.edp"
          '';
        };
      });
    };
}
