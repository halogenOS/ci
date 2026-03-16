{
  applyHomeManagerShared,
  pkgs,
  foundrixPkgs,
  ...
}:
{
  home-manager = applyHomeManagerShared {
    home.language = rec {
      base = "en_US.UTF-8";
      measurement = base;
      monetary = base;
      name = base;
      paper = base;
      time = base;
    };
    home.packages = with pkgs; [
      jq
      pv
      socat
      git
      curl
      dig
      unzip
      file
      zstd
      tree
      bat
      fd
      btop
      rsync
      foundrixPkgs.git-aliases
    ];
  };
}
