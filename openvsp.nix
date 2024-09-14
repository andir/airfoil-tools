{ stdenv
, cmake
, libGL
, glew
, libGLU
, xorg
, wayland
, libxkbcommon
, eigen
, blas
, unzip
, makeDesktopItem
, copyDesktopItems
, src }:
stdenv.mkDerivation {
  pname = "openvsp";
  version = "git";

  inherit src;

  preConfigure = "cd SuperProject";

  cmakeFlags = [ "-DOpenGL_GL_PREFERENCE=GLVND" ];

  buildInputs = [ libGL glew libGLU wayland xorg.libX11 libxkbcommon eigen blas ];

  installPhase = ''
    mkdir -p $out/share/openvsp
    install -Dm644 $out/vspIcon.png $out/share/pixmaps/openvsp.png
    mv $out/{vspaero_ex,CustomScripts,LICENSE,README.md,airfoil,help,matlab,scripts,textures,vspIcon.png} $out/share/openvsp
    mkdir $out/bin
    mv $out/{vsp,vspscript,vspaero,vspaero_complex,vspaero_adjoint,vspaero_opt,vspviewer,vsploads} $out/bin
  '';

  desktopItems =[ (makeDesktopItem {
    name = "OpenVSP";
    desktopName = "OpenVSP";
    exec = "vsp";
    icon = "";
  })];
  
  nativeBuildInputs = [ cmake copyDesktopItems ];
}
