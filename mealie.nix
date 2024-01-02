{ config, lib, pkgs, ...}:
let
  version = "v1.0.0-RC2";
  src = pkgs.fetchFromGitHub {
    owner = "mealie-recipes";
    repo = "mealie";
    rev = version;
    sha256 = "sha256-/sht8s0Nap6TdYxAqamKj/HGGV21/8eYCuYzpWXRJCE=";
  };
  backend = import ./mealie-backend.nix { inherit lib pkgs src version; };
  frontend = import ./mealie-frontend.nix { inherit lib pkgs src version; };

  cfg = config.services.mealie;
in
{
  options.services.mealie = {
    enable = lib.mkEnableOption "Mealie, a recipe manager and meal planner";

    # TODO api_port
    # TODO log_level
    # TODO allow_signup

    host = lib.mkOption {
      type = lib.types.str;
      default = "localhost";
      description = "Host on which creating the URL on the service";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 9000;
      description = "Port on which to serve the Mealie service";
    };

    protocol = lib.mkOption {
      type = lib.types.str;
      default = "http";
      description = "Protocol to use to serve the service";
    };

    log_level = lib.mkOption {
      type = lib.types.str;
      default = "INFO";
      description = "Log level to use for this service";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.mealie = {
      description = "Mealie, a self hosted recipe manager and meal planner";
      after = [
        "network.target"
        "network-online.target"
      ];
      wantedBy = [
        "multi-user.target"
      ];

      environment = {
        PYTHONPATH = "${backend.python_path}:${backend}/lib/${backend.python.libPrefix}/site-packages";
        STATIC_FILES = "${frontend}";
        # ALEMBIC_CONFIG_FPATH = "${src}/alembic.ini";
        PRODUCTION = "true";

        # TODO  Additionnal config
        # See https://github.com/mealie-recipes/mealie/blob/mealie-next/mealie/core/settings/settings.py
        LOG_LEVEL = cfg.log_level;
        # ALLOW_SIGNUP = cfg.allow_signup;
        API_PORT = builtins.toString cfg.port;
        BASE_URL = "${cfg.protocol}://${cfg.host}:${builtins.toString cfg.port}";
        ALEMBIC_CONFIG_FPATH="/var/lib/mealie/alembic.ini";
      };

      serviceConfig = {
        DynamicUser = true;
        User = "mealie";
        ExecStartPre = let
          alembic_scripts_path = "/var/lib/mealie/alembic";
        in pkgs.writeShellScript "startup-mealie.sh" ''
          mkdir -p ${alembic_scripts_path}
          ${pkgs.toybox}/bin/sed 's+script_location = alembic+script_location = ${alembic_scripts_path}+g' ${src}/alembic.ini > $ALEMBIC_CONFIG_FPATH
          ${backend.interpreter} ${backend}/lib/${backend.python.libPrefix}/site-packages/mealie/db/init_db.py
        '';
        ExecStart = "${backend.pythonpkg.gunicorn}/bin/gunicorn -b 0.0.0.0:${builtins.toString cfg.port} -k uvicorn.workers.UvicornWorker mealie.app:app";
        StateDirectory = "mealie";
      };
    };
  };
}
