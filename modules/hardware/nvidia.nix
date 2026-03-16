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
  # udev triggers a systemd service on AC plug/unplug
  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", RUN+="${pkgs.systemd}/bin/systemctl start nvidia-prime-ac-update.service"
  '';

  systemd.services.nvidia-prime-ac-update = {
    description = "Update NVIDIA PRIME offload env based on AC power";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "nvidia-prime-ac-update" ''
        online=$(cat /sys/class/power_supply/ADP1/online 2>/dev/null || echo 0)
        for user in $(${pkgs.systemd}/bin/loginctl list-users --no-legend | ${pkgs.gawk}/bin/awk '{print $2}'); do
          if [ "$online" = "1" ]; then
            mkdir -p /run/nvidia-offload
            touch /run/nvidia-offload/env
            ${pkgs.systemd}/bin/busctl call \
              --user --machine="$user@" \
              org.freedesktop.systemd1 \
              /org/freedesktop/systemd1 \
              org.freedesktop.systemd1.Manager \
              SetEnvironment as 3 \
              "__NV_PRIME_RENDER_OFFLOAD=1" \
              "__VK_LAYER_NV_optimus=NVIDIA_only" \
              "__GLX_VENDOR_LIBRARY_NAME=nvidia"
          else
            rm -f /run/nvidia-offload/env
            ${pkgs.systemd}/bin/busctl call \
              --user --machine="$user@" \
              org.freedesktop.systemd1 \
              /org/freedesktop/systemd1 \
              org.freedesktop.systemd1.Manager \
              UnsetEnvironment as 3 \
              "__NV_PRIME_RENDER_OFFLOAD" \
              "__VK_LAYER_NV_optimus" \
              "__GLX_VENDOR_LIBRARY_NAME"
          fi
        done
      '';
    };
  };

  # Fallback for shells opened before udev fires
  environment.shellInit = ''
    if [ -f /run/nvidia-offload/env ]; then
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
