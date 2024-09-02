{
  inputs = {
    xoptofoil2 = {
      url = "github:jxjo/Xoptfoil2";
      flake = false;
    };

    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = { flake-parts, ... }@inputs: flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [ "x86_64-linux" ];
    perSystem = { self', pkgs, ... }: {
      packages = {
        xoptofoil2 = pkgs.stdenv.mkDerivation {
          pname = "Xoptofoil2";
          version = "git";
          src = inputs.xoptofoil2;
          patches = [ ./xoptofoil2-cmake.diff ];
          postPatch = ''
            find src -type f -name '*.F90' -exec sh -c 'mv "$0" "''${0%.F90}.f90"' {} \;
          '';
          nativeBuildInputs = [ pkgs.cmake pkgs.gfortran ];
          #buildInputs = [ pkgs.mpi ];
          cmakeFlags = [
            "-DCMAKE_INSTALL_PREFIX:PATH=${placeholder "out"}"
            "-DCMAKE_BUILD_TYPE:STRING=Release"
          ];
          makeFlags = [ "VERBOSE=1" ];
        };
      };
      devShells.default = pkgs.mkShell {
        packages = [
          self'.packages.xoptofoil2
          pkgs.xflr5
        ];
      };
    };
  };
}
