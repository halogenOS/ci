{ pkgs ? import <nixpkgs> {} }:

let fhs = pkgs.buildFHSUserEnv {
  name = "romboss-env";
  targetPkgs = pkgs: with pkgs; [
      buildkite-agent buildkite-cli gh jdk21 bash
  ];
  multiPkgs = pkgs: with pkgs; [];
  runScript = "bash";
  profile = ''
    export LD_LIBRARY_PATH=/usr/lib:/usr/lib32
  '';
};
in pkgs.stdenv.mkDerivation {
  name = "romboss-shell";
  system = builtins.currentSystem;
  nativeBuildInputs = [ fhs ];
  builder = "${pkgs.bash}/bin/bash";
  args = ["-c" ''
    ${pkgs.coreutils}/bin/ln -s "${pkgs.buildkite-agent}/bin/buildkite-agent" $out
  ''];
  FONTCONFIG_FILE = with pkgs; makeFontsConf { fontDirectories = [ roboto ]; };
}
