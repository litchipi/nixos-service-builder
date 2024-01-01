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
    enable = pkgs.mkEnableOption "Mealie, a recipe manager and meal planner";

    # TODO api_port
    # TODO log_level
    # TODO allow_signup
    # TODO host
    # TODO port
  };

  config = pkgs.mkIf cfg.enable {
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
        PYTHONPATH = "${backend.pythonPath}:${backend}/lib/${backend.python3.libPrefix}/site-packages";
        STATIC_FILES = "${frontend}";

        # TODO  Additionnal config
        # See https://github.com/mealie-recipes/mealie/blob/mealie-next/mealie/core/settings/settings.py
        # API_PORT = builtins.toString cfg.api_port;
        # LOG_LEVEL = cfg.log_level;
        # ALLOW_SIGNUP = cfg.allow_signup;
        # BASE_URL = "${cfg.host}:${builtins.toString cfg.port}";
      };

      serviceConfig = {
        DynamicUser = true;
        User = "mealie";
        ExecStartPre = pkgs.writeShellScript "mealie-start-pre" ''
          ${backend.python3.interpreter} ${backend}/lib/${backend.python3.libPrefix}/site-packages/mealie/db/init_db.py
        '';
        ExecStart = "${pkgs.python3Packages.gunicorn}/bin/gunicorn -b 0.0.0.0:9000 -k uvicorn.workers.UvicornWorker mealie.app:app";
        StateDirectory = "mealie";
      };
    };
  };
}
