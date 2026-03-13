{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    openfortivpn
  ];

  environment.etc."openfortivpn/config" = {
    text = ''
      host = 131.108.172.203
      port = 10443
      username = 92366507.lucasp
      trusted-cert = 031e84163b3df6242d30dcec263ea1c293ca8ac27e1e92c5332eaed25bd9cdd9

      set-routes = 1
      set-dns = 1
      pppd-use-peerdns = 1
    '';
    mode = "0600";
  };
}
