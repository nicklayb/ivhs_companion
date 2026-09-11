{ self }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.ivhs-companion;
  user = "ivhs-companion";
  releaseName = "companion";
  package = self.packages.${pkgs.system}.default;
in
{
  options.services.ivhs-companion = {
    enable = lib.mkEnableOption "Enables IVHS Companion app";
    releaseCookie = lib.mkOption {
      type = lib.types.str;
      description = "Erlang release cookie";
      default = "ivhscompanion";
    };
    loggerLevel = lib.mkOption {
      type = lib.types.enum [
        "info"
        "debug"
      ];
      default = "info";
      description = "Logger level";
    };
    device = {
      vendorId = lib.mkOption {
        type = lib.types.str;
        description = "Device's vendor id";
      };
      productId = lib.mkOption {
        type = lib.types.str;
        description = "Device's product id";
      };
      baudRate = lib.mkOption {
        type = lib.types.int;
        description = "Baud rate of the USB device";
        default = 115200;
      };
    };
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.device.vendorId != "";
        message = "USB Device vendor ID must be provided";
      }
      {
        assertion = cfg.device.productId != "";
        message = "USB Device product ID must be provided";
      }
    ];

    environment.systemPackages = [ package ];

    users.users.${user} = {
      isSystemUser = true;
      group = user;
    };
    users.groups.${user} = { };

    services.udev.extraRules = ''
      SUBSYSTEM=="tty", ATTRS{idVendor}=="${cfg.device.vendorId}", ATTRS{idProduct}=="${cfg.device.productId}", MODE="0666", GROUP="${user}"
    '';
    systemd.services = {
      ivhs-companion =
        let
          buildScript = body: ''
            export RELEASE_COOKIE="${cfg.releaseCookie}"
            export RELEASE_NODE=ivhs_companion@127.0.0.1
            export RELEASE_DISTRIBUTION=name
            export LOGGER_LEVEL=${cfg.loggerLevel}

            ${body}
          '';
        in
        {
          description = "Start IVHS Companion service";
          wantedBy = [ "multi-user.target" ];
          script = buildScript ''
            ${package}/bin/${releaseName} start
          '';
          serviceConfig = {
            User = user;
            Group = user;
            ExecStop = buildScript ''
              ${package}/bin/${releaseName} stop
            '';
            ExecReload = buildScript ''
              ${package}/bin/${releaseName} restart
            '';
          };

          environment = {
            TTY_DEVICE = "${cfg.device.vendorId}:${cfg.device.productId}";
            TTY_BAUD_RATE = "${toString cfg.device.baudRate}";
          };
        };
    };
  };
}
