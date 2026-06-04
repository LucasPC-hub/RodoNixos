{ stdenv, lib, kernel, fetchFromGitHub }:

stdenv.mkDerivation {
  pname = "max98390-hda";
  version = "1.0-${kernel.version}";

  src = fetchFromGitHub {
    owner = "Andycodeman";
    repo = "samsung-galaxy-book4-linux-fixes";
    rev = "15888d2111f8235b18f50f2615074e328523c47a";
    hash = "sha256-FXbLOJG6P7oUFv3Orbah5R8i/CapfopItsvonvK13Gg=";
  };

  sourceRoot = "source/speaker-fix/src";

  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags = [
    "KVER=${kernel.modDirVersion}"
    "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  ];

  installPhase = ''
    install -D snd-hda-scodec-max98390.ko $out/lib/modules/${kernel.modDirVersion}/extra/snd-hda-scodec-max98390.ko
    install -D snd-hda-scodec-max98390-i2c.ko $out/lib/modules/${kernel.modDirVersion}/extra/snd-hda-scodec-max98390-i2c.ko
  '';

  meta = with lib; {
    description = "MAX98390 HDA speaker amplifier driver for Samsung Galaxy Book4";
    license = licenses.gpl2Only;
    platforms = platforms.linux;
  };
}
