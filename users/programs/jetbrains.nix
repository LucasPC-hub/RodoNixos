{ pkgs }:

{
  # Wrap a JetBrains IDE so it picks the NVIDIA GPU via PRIME offload
  # and uses the Wayland Java toolkit.
  withJetbrainsWrapper = pkg: pkgs.symlinkJoin {
    name = "${pkg.pname or pkg.name}-wrapped";
    paths = [ pkg ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      for bin in $out/bin/*; do
        wrapProgram "$bin" \
          --set __NV_PRIME_RENDER_OFFLOAD 1 \
          --set __GLX_VENDOR_LIBRARY_NAME nvidia \
          --set __VK_LAYER_NV_optimus NVIDIA_only \
          --set _JAVA_AWT_WM_NONREPARENTING 1 \
          --set _JAVA_OPTIONS "-Dawt.toolkit.name=WLToolkit"
      done
    '';
  };
}
