{
  stdenv,
  cmake,
  gnumake,
  gcc-arm-embedded,
  bash,
  buildtype ? "debug",
  lib,
}:

assert buildtype == "debug" || buildtype == "release";

stdenv.mkDerivation rec {
  inherit buildtype;

  pname = "firmware";
  version = lib.fileContents ./VERSION;
  src = ./.;

  buildInputs = [
    gcc-arm-embedded
    cmake
    gnumake
  ];

  dontFixup = true; # if you use fixupPhase (do something after build), remove this
  dontStrip = true;
  dontPatchELF = true;

  # Firmware/device info
  device = "STM32F407VG";
  binary = "${pname}${buildtype}-${version}-.bin";
  executable = "${pname}-${buildtype}-${version}.elf";

  # cmake
  cmakeFlags = [
    "-DPROJECT_VERSION=${version}"
    "-DCMAKE_BUILD_TYPE=${buildtype}"
    "-DDUMP_ASM=OFF"
  ];

  patchPhase = ''
    substituteInPlace glob.sh \
      --replace '/usr/bin/env bash' ${bash}/bin/bash
  '';

  # "save" outputs
  installPhase = ''
    mkdir -p $out/bin
    cp *.bin *.elf *.s $out/bin
    cp compile_commands.json $out
  '';
}
