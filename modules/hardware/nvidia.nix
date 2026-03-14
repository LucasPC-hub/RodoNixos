{ config, pkgs, ... }:

{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      vulkan-loader
      vulkan-tools
    ];
  };

  services.xserver.videoDrivers = [ "modesetting" "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";

      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
    };
  };

  # Nvidia suspend/hibernate
  systemd.services = {
    nvidia-suspend.wantedBy = [ "suspend.target" ];
    nvidia-hibernate.wantedBy = [ "hibernate.target" ];
    nvidia-resume.wantedBy = [ "suspend.target" ];
  };

  environment.systemPackages = with pkgs; [
    mesa-demos
    nvidia-vaapi-driver
    libva
  ];
}
