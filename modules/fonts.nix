inputs:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  googlesans = pkgs.stdenv.mkDerivation {
    pname = "Google-Sans-Flex";
    version = "1.0";
    src = pkgs.fetchFromGitHub {
      owner = "strtab";
      repo = "google-sans";
      rev = "98c460d5c1d7a7c7b7ed2c66be64fc5c71fa1f75";
      hash = "sha256-bbOZFjme2RgtOO+BtxRsrlRBQT0Ig/LvGo/N4PHPcWE=";
    };
    nativeBuildInputs = [ pkgs.unzip ];
    unpackPhase = ''
      cp -r $src/* .
    '';
    installPhase = ''
      mkdir -p $out/share/fonts/truetype
      for zip in *.zip; do
        ${pkgs.unzip}/bin/unzip -o "$zip"
      done
      find . -name "*.ttf" -o -name "*.otf" | xargs -I{} cp {} $out/share/fonts/truetype/
    '';
  };
  cfg = config.programs.aether;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      googlesans
      material-symbols
      nerd-fonts.jetbrains-mono
      twemoji-color-font # ttf-twemoji
      inter
    ];
  };
}
