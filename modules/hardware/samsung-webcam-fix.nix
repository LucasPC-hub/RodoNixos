{ pkgs, lib, ... }:

# Webcam do Galaxy Book4 Ultra (IPU6 Meteor Lake + sensor OV02C10).
# Port declarativo do webcam-fix-libcamera de
# https://github.com/Andycodeman/samsung-galaxy-book-linux-fixes
#
# O kernel já tem os drivers (intel-ipu6, ov02c10), mas:
#  1. O sensor não vincula sem os módulos IVSC carregados antes (-EPROBE_DEFER);
#  2. Os nós V4L2 crus do IPU6 só entregam bayer — nenhum app usa direto.
#     Quem monta o pipeline é o libcamera (Simple pipeline + Software ISP),
#     exposto aos apps via PipeWire;
#  3. O libcamera 0.7.0 não registra CameraSensorHelper pro OV02C10 (auto-
#     exposição quebrada) nem traz tuning de cor — patch + yaml do repo acima.

let
  # Repo dos fixes, pinado.
  sgbFixes = pkgs.fetchFromGitHub {
    owner = "Andycodeman";
    repo = "samsung-galaxy-book-linux-fixes";
    rev = "a20fe9126781d59bbfbba2a8cd38dbc5d75fed2e";
    hash = "sha256-2ZcZq3FAtLO49hBf3lbWmmCIYIp6Uit2IPLjBf7WwYw=";
  };

  # libcamera com sensor helper do OV02C10 (ganho linear = valor/16, mesmo
  # patch que o installer do repo aplica) + tuning file no datadir do IPA.
  # Sem o helper o IPASoft cai num default genérico e não sai frame usável;
  # sem o tuning cai no uncalibrated.yaml (imagem lavada/esverdeada).
  libcameraPatched = pkgs.libcamera.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      HELPER_FILE=""
      for candidate in src/ipa/libipa/camera_sensor_helper.cpp \
                       src/libcamera/sensor/camera_sensor_helper.cpp; do
        if [ -f "$candidate" ]; then
          HELPER_FILE="$candidate"
          break
        fi
      done
      if [ -n "$HELPER_FILE" ] && ! grep -q 'CameraSensorHelperOv02c10' "$HELPER_FILE"; then
        sed -i '/#endif.*__DOXYGEN__/i\
      class CameraSensorHelperOv02c10 : public CameraSensorHelper\
      {\
      public:\
      \tCameraSensorHelperOv02c10()\
      \t{\
      \t\tgain_ = AnalogueGainLinear{ 1, 0, 0, 16 };\
      \t}\
      };\
      REGISTER_CAMERA_SENSOR_HELPER("ov02c10", CameraSensorHelperOv02c10)\
      ' "$HELPER_FILE"
      fi
    '';
    postInstall = (old.postInstall or "") + ''
      install -Dm644 ${sgbFixes}/webcam-fix-libcamera/ov02c10.yaml \
        $out/share/libcamera/ipa/simple/ov02c10.yaml
    '';
  });

  # Só o daemon PipeWire/WirePlumber usam o libcamera patchado — overlay
  # global rebuildaria firefox/OBS/electron do zero (horas de compilação).
  # Apps clientes falam o protocolo PipeWire, não linkam libcamera.
  pipewirePatched = pkgs.pipewire.override { libcamera = libcameraPatched; };
  wireplumberPatched = pkgs.wireplumber.override { pipewire = pipewirePatched; };

  # Relay on-demand libcamera -> v4l2loopback pra apps sem suporte a câmera
  # PipeWire (Zoom, OBS, VLC). CPU ~zero quando ocioso.
  cameraRelayMonitor = pkgs.stdenv.mkDerivation {
    pname = "camera-relay-monitor";
    version = "1.0";
    src = "${sgbFixes}/camera-relay";
    dontConfigure = true;
    dontFixup = true;
    buildPhase = ''
      gcc -O2 -Wall -o camera-relay-monitor camera-relay-monitor.c
    '';
    installPhase = ''
      install -Dm755 camera-relay-monitor $out/bin/camera-relay-monitor
    '';
  };

  cameraRelay = pkgs.stdenvNoCC.mkDerivation {
    pname = "camera-relay";
    version = "1.0";
    src = "${sgbFixes}/camera-relay";
    nativeBuildInputs = [ pkgs.makeWrapper ];
    dontConfigure = true;
    dontFixup = true;
    installPhase = ''
      install -Dm755 camera-relay $out/share/camera-relay/camera-relay

      substituteInPlace $out/share/camera-relay/camera-relay \
        --replace "/usr/local/bin/camera-relay-monitor" "${cameraRelayMonitor}/bin/camera-relay-monitor" \
        --replace "/usr/local/bin/camera-relay" "$out/bin/camera-relay"

      mkdir -p $out/bin
      makeWrapper $out/share/camera-relay/camera-relay $out/bin/camera-relay \
        --prefix PATH : ${lib.makeBinPath [
          pkgs.bash
          pkgs.coreutils
          pkgs.findutils
          pkgs.gawk
          pkgs.gnugrep
          pkgs.gnused
          pkgs.kmod
          pkgs.procps
          pkgs.systemd
          pkgs.util-linux
          libcameraPatched
          pkgs.gst_all_1.gstreamer
          pkgs.gst_all_1.gst-plugins-base
          pkgs.gst_all_1.gst-plugins-good
          pkgs.gst_all_1.gst-plugins-bad
        ]} \
        --set LIBCAMERA_IPA_MODULE_PATH ${libcameraPatched}/lib/libcamera/ipa \
        --prefix GST_PLUGIN_PATH : ${lib.makeSearchPath "lib/gstreamer-1.0" [ libcameraPatched ]} \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libcameraPatched ]}
    '';
  };

  relayEnvironment = {
    LIBCAMERA_IPA_MODULE_PATH = "${libcameraPatched}/lib/libcamera/ipa";
    GST_PLUGIN_PATH = lib.makeSearchPath "lib/gstreamer-1.0" [ libcameraPatched ];
    LD_LIBRARY_PATH = lib.makeLibraryPath [ libcameraPatched ];
    # GPU debayer (EGL) é incompatível com o driver NVIDIA proprietário e em
    # híbridas o EGL pode escolher a NVIDIA mesmo com a iGPU ativa → frame
    # preto. Força debayer na CPU (issue #50 do repo).
    LIBCAMERA_SOFTISP_MODE = "cpu";
  };
in
{
  services.pipewire.package = pipewirePatched;
  services.pipewire.wireplumber.package = wireplumberPatched;

  # Módulos IVSC (Intel Visual Sensing Controller) precisam estar de pé antes
  # do ov02c10 sondar, senão o sensor fica em -EPROBE_DEFER e nunca vincula.
  # No initrd pra eliminar a corrida de boot (mesma coisa que o installer faz
  # via initramfs).
  boot.initrd.kernelModules = [ "mei-vsc" "mei-vsc-hw" "ivsc-ace" "ivsc-csi" ];
  boot.kernelModules = [ "mei-vsc" "mei-vsc-hw" "ivsc-ace" "ivsc-csi" ];
  boot.extraModprobeConfig = ''
    softdep ov02c10 pre: mei-vsc mei-vsc-hw ivsc-ace ivsc-csi

    # Dois loopbacks rotulados: um pro DroidCam (que já era usado antes) e um
    # pro relay da câmera — o relay acha o dele pelo label "Camera Relay" e
    # ignora o do DroidCam.
    options v4l2loopback devices=2 card_label="Droidcam,Camera Relay"
  '';

  # Tira o uaccess dos nós V4L2 crus do IPU6 (bayer inutilizável) pra apps de
  # sessão não os enxergarem; o libcamera continua acessando via grupo video.
  services.udev.extraRules = ''
    SUBSYSTEM=="video4linux", KERNEL=="video*", ATTR{name}=="Intel IPU6 ISYS Capture*", TAG-="uaccess"
    SUBSYSTEM=="video4linux", KERNEL=="video*", ATTR{name}=="Intel IPU6 CSI2*", TAG-="uaccess"
  '';

  # Esconde os ~48 nós "ipu6" crus da lista de câmeras dos apps PipeWire.
  # A câmera de verdade aparece via monitor libcamera.
  services.pipewire.wireplumber.extraConfig."50-disable-ipu6-v4l2" = {
    "monitor.v4l2.rules" = [
      {
        matches = [ { "node.name" = "~v4l2_input.pci-0000_00_05*"; } ];
        actions.update-props."node.disabled" = true;
      }
    ];
  };

  # Mesmo motivo do LIBCAMERA_SOFTISP_MODE do relay, mas pro caminho
  # PipeWire-direto (Firefox/apps nativos) — o nó libcamera roda no
  # WirePlumber/PipeWire.
  environment.sessionVariables.LIBCAMERA_SOFTISP_MODE = "cpu";
  systemd.user.services.pipewire.environment.LIBCAMERA_SOFTISP_MODE = "cpu";
  systemd.user.services.wireplumber.environment.LIBCAMERA_SOFTISP_MODE = "cpu";

  environment.systemPackages = [
    cameraRelay
    libcameraPatched # `cam -l` pra debug
  ];

  systemd.user.services.camera-relay = {
    description = "Camera Relay (libcamera -> v4l2loopback on-demand)";
    after = [ "pipewire.service" "wireplumber.service" ];
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${cameraRelay}/bin/camera-relay start --on-demand";
      ExecStop = "${cameraRelay}/bin/camera-relay stop";
      Restart = "on-failure";
      RestartSec = 5;
    };
    environment = relayEnvironment;
  };
}
