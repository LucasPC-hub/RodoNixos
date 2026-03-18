{ pkgs, ... }:

{
  # SOF firmware for Intel audio (includes mic support)
  hardware.firmware = [ pkgs.sof-firmware ];

  # Force SOF driver (dsp_driver=3) instead of default
  boot.extraModprobeConfig = ''
    options snd-intel-dspcfg dsp_driver=3
  '';
}
