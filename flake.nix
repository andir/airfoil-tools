{
  inputs = {
    xoptofoil2 = {
      url = "github:andir/Xoptfoil2/fix-build";
      flake = false;
    };

    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = { self, flake-parts, ... }@inputs: flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [ "x86_64-linux" ];
    perSystem = { self', pkgs, ... }: let
      allPackages = [ self'.packages.xoptofoil2 pkgs.xflr5 ];
    in {
      packages = {
        xoptofoil2 = pkgs.stdenv.mkDerivation {
          pname = "Xoptofoil2";
          version = "git";
          src = inputs.xoptofoil2;
          nativeBuildInputs = [ pkgs.cmake pkgs.gfortran ];
          cmakeFlags = [
            "-DCMAKE_INSTALL_PREFIX:PATH=${placeholder "out"}"
          ];
          makeFlags = [ "VERBOSE=1" ];
          postInstall = ''
            mkdir -p $out/share/xoptofoil2
            cp -rv $src/examples $out/share/xoptofoil2/examples
          '';
        };

        release = pkgs.symlinkJoin {
          name = "release";
          paths = allPackages;
        };
      };
      devShells.default = pkgs.mkShell {
        packages = [] ++ allPackages;
      };
    };
  } // {
    hydraJobs.release = self.packages.x86_64-linux.release;
  };
}
