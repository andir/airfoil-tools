{
  inputs = {
    xoptofoil2 = {
      url = "github:jxjo/Xoptfoil2";
      flake = false;
    };

    airfoileditor = {
      url = "github:jxjo/AirfoilEditor";
      flake = false;
    };

    planformcreator2 = {
      url = "github:jxjo/PlanformCreator2?submodules=1";
      flake = false;
    };

    openvsp = {
      url = "github:OpenVSP/OpenVSP";
      flake = false;
    };

    pyaero = {
      url = "github:chiefenne/PyAero";
      flake = false;
    };

    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = { self, flake-parts, ... }@inputs: flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [ "x86_64-linux" ];
    imports = [
      inputs.flake-parts.flakeModules.easyOverlay
    ];

    perSystem = { self', pkgs, config, ... }: let
      allPackages = [ self'.packages.xoptfoil2 pkgs.xflr5 self'.packages.airfoileditor self'.packages.planformcreator2 self'.packages.openvsp self'.packages.pyaero ];
    in {
      overlayAttrs = {
        inherit (config.packages) xoptfoil2 airfoileditor planformcreator2;
        inherit (pkgs) xflr5;
      };
      packages = let
        mkAirfoilEditor = src: let
          pythonEnv = pkgs.python3.withPackages (p: with p; [
            numpy
            matplotlib
            customtkinter
            termcolor
            colorama
            ezdxf
            pyqt6
            pyqtgraph
          ]);
        in pkgs.writeShellScriptBin "airfoileditor" ''
          exec ${pythonEnv}/bin/python ${src}/AirfoilEditor.py "$@"
        '';
 
      in {
        pyaero = pkgs.python3Packages.callPackage ./pyaero.nix { src = inputs.pyaero; };
        openvsp = pkgs.callPackage ./openvsp.nix { src = inputs.openvsp; };
        xoptfoil2 = pkgs.stdenv.mkDerivation {
          pname = "Xoptfoil2";
          version = "git";
          src = inputs.xoptofoil2;
          nativeBuildInputs = [ pkgs.cmake pkgs.gfortran ];
          env.XOPTFOIL_VERSION = "1.0.5";
          cmakeFlags = [
            "-DCMAKE_INSTALL_PREFIX:PATH=${placeholder "out"}"
          ];
          makeFlags = [ "VERBOSE=1" ];
          postInstall = ''
            mkdir -p $out/share/xoptfoil2
            cp -rv $src/examples $out/share/xoptfoil2/examples
            mv $out/bin/Worker $out/bin/Xoptfoil2_Worker
          '';
        };
        airfoileditor = mkAirfoilEditor inputs.airfoileditor;

        pc2_airfoileditor = let
          src = inputs.planformcreator2 + "/AirfoilEditor_subtree/";
        in mkAirfoilEditor src;
        planformcreator2 = let
          worker = pkgs.writeShellScriptBin "Worker" ''
            exec ${self'.packages.xoptfoil2}/bin/Xoptfoil2_Worker "$@"
          '';
          
          src =  pkgs.applyPatches {
            name = "planformcreator2-v3";
            src = inputs.planformcreator2;
            patches = [ /* ./pc2.patch */ ];
          };
          pythonEnv = pkgs.python3.withPackages (p: with p; [
            pyqt6
            pyqtgraph
            numpy
            matplotlib
            customtkinter
            termcolor
            colorama
            ezdxf
          ]);
        in pkgs.writeShellScriptBin "planformcreator2" ''
          export PATH="${worker}/bin:$PATH"
          exec ${pythonEnv}/bin/python ${src}/PlanformCreator2.py "$@"
        '';

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
