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
    networking.firewall.allowedTCPPorts = [ cfg.port ];

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

        MEALIE_LOG_FILE = "/var/log/mealie/mealie.log";
        ALEMBIC_CONFIG_FPATH="/var/lib/mealie/alembic.ini";

        DEFAULT_GROUP="Home";
        DEFAULT_EMAIL="changeme@example.com";
        DEFAULT_PASSWORD="MyPassword";
        PRODUCTION = "true";
        API_DOCS = "False";
        DB_ENGINE = "sqlite";
        TOKEN_TIME="24";

        LOG_LEVEL = cfg.log_level;
        API_PORT = builtins.toString cfg.port;
        BASE_URL = "${cfg.protocol}://${cfg.host}:${builtins.toString cfg.port}";

        # TODO  Additionnal config
        # ALLOW_SIGNUP = cfg.allow_signup;
        # POSTGRES_USER=mealie
        # POSTGRES_PASSWORD=mealie
        # POSTGRES_SERVER=postgres
        # POSTGRES_PORT=5432
        # POSTGRES_DB=mealie
        # LDAP_AUTH_ENABLED=False
        # LDAP_SERVER_URL=""
        # LDAP_TLS_INSECURE=False
        # LDAP_TLS_CACERTFILE=
        # LDAP_ENABLE_STARTTLS=False
        # LDAP_BASE_DN=""
        # LDAP_QUERY_BIND=""
        # LDAP_QUERY_PASSWORD=""
        # LDAP_USER_FILTER="(&(|({id_attribute}={input})({mail_attribute}={input}))(objectClass=person))"

        # LDAP_ADMIN_FILTER=""
        # LDAP_ID_ATTRIBUTE=uid
        # LDAP_NAME_ATTRIBUTE=name
        # LDAP_MAIL_ATTRIBUTE=mail
      };

      serviceConfig = {
        DynamicUser = true;
        User = "mealie";
        ExecStartPre = let
          exec = pkgs.writeShellScript "startup-mealie.sh" ''
            ${pkgs.toybox}/bin/sed 's+script_location = alembic+script_location = ${src}/alembic+g' ${src}/alembic.ini > $ALEMBIC_CONFIG_FPATH
            ${backend.interpreter} ${backend}/lib/${backend.python.libPrefix}/site-packages/mealie/db/init_db.py
          '';
        in "${exec}";
        ExecStart = "${backend.pythonpkg.gunicorn}/bin/gunicorn -b 0.0.0.0:${builtins.toString cfg.port} -k uvicorn.workers.UvicornWorker mealie.app:app";
        StateDirectory = "mealie";
        LogsDirectory = "mealie";
      };
    };
  };
}
