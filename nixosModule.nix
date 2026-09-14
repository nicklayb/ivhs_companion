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

  mkOption =
    type: description: default:
    lib.mkOption {
      description = description;
      type = type;
      default = default;
    };
  mkStrOption = mkOption lib.types.str;
  mkIntOption = mkOption lib.types.int;
  mkEnumOption = options: mkOption (lib.types.enum options);

in
{
  options.services.ivhs-companion = {
    enable = lib.mkEnableOption "Enables IVHS Companion app";
    releaseCookie = mkStrOption "Erlang release cookie" "ivhscompanion";
    loggerLevel = mkEnumOption [ "info" "debug" ] "Logger level" "info";
    device = {
      vendorId = mkStrOption "Device's vendor id" "";
      productId = mkStrOption "Device's product id" "";
      baudRate = mkIntOption "Baud rate of the USB device" 115200;
    };
    mqtt = {
      host = mkStrOption "MQTT Broker hostname" "localhost";
      port = mkIntOption "MQTT Broker port" 1883;
      clientId = mkStrOption "IVHS Broker client id on MQTT broker" "ivhs-companion";
      username = mkStrOption "MQTT Broker username" "ivhs";
      password = mkStrOption "MQTT Broker password" "ivhs";
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
      SUBSYSTEM=="tty", ATTRS{idVendor}=="${cfg.device.vendorId}", ATTRS{idProduct}=="${cfg.device.productId}", MODE="0666"
    '';
    systemd.services = {
      ivhs-companion =
        let
          buildScript = body: ''
            export RELEASE_COOKIE="${cfg.releaseCookie}"
            export RELEASE_NODE=ivhs_companion@127.0.0.1
            export RELEASE_DISTRIBUTION=name

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
            TTY_BAUD_RATE = toString cfg.device.baudRate;

            LOGGER_LEVEL = cfg.loggerLevel;

            MQTT_HOST = cfg.mqtt.host;
            MQTT_PORT = toString cfg.mqtt.port;
            MQTT_CLIENT_ID = cfg.mqtt.clientId;
            MQTT_USERNAME = cfg.mqtt.username;
            MQTT_PASSWORD = cfg.mqtt.password;
          };
        };
    };
  };
}
