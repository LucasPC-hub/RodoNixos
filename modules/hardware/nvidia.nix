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

  # Auto-offload everything to NVIDIA when on AC power
  environment.shellInit = ''
    if [ "$(cat /sys/class/power_supply/AC*/online 2>/dev/null)" = "1" ]; then
      export __NV_PRIME_RENDER_OFFLOAD=1
      export __VK_LAYER_NV_optimus=NVIDIA_only
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
    fi
  '';

  environment.systemPackages = with pkgs; [
    mesa-demos
    nvidia-vaapi-driver
    libva
  ];
}
