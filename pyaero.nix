{ src
, runCommand
, python
, writeShellScriptBin
}:
let
  pythonEnv = python.withPackages (p: with p; [ pyside6 scipy numpy meshio distutils ]);
  patchedSrc = runCommand "pyaero-src" { inherit src; } ''
    mkdir $out
    cp -rv $src/* $out
    chmod +rw -R $out
    sed -e 's/^OUTPUTDATA = .*/OUTPUTDATA = os.getenv("PYAEROOUTPUT")/' -i $out/src/Settings.py
    sed -e 's/^LOGDATA = .*/LOGDATA = os.getenv("PYAEROLOGDATA")/' -i $out/src/Settings.py
  '';
in 
(writeShellScriptBin "pyaero" ''
  export PATH="${pythonEnv}/bin/:$PATH"
  export PYAEROPATH="${patchedSrc}"
  export PYAEROOUTPUT="$PWD"
  export PYAEROLOGDATA="$PWD"
  exec python $PYAEROPATH/src/PyAero.py
'')
