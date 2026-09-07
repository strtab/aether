inputs:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.aether;
in
{
  config = lib.mkIf cfg.enable {
    systemd.user = {
      enable = true;
      services = {
        aether = {
          Unit = {
            Description = "Aether Quickshell desktop shell";
          };
          Service = {
            ExecStart = "${pkgs.writeShellScript "aether-start" ''
              exec qs -c aether
            ''}";
            Restart = "on-failure";
            RestartSec = 1;

            KillMode = "control-group";
            KillSignal = "SIGTERM";
            TimeoutStopSec = 5;

            SendSIGKILL = true;
          };
        };
      };
    };
  };
}
