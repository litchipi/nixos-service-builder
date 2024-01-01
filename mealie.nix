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
    # TODO host
    # TODO port
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
        PRODUCTION = "true";

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
        ExecStartPre = "${backend.interpreter} ${backend}/lib/${backend.python.libPrefix}/site-packages/mealie/db/init_db.py";

  # TODO  FIXME  Alembic config file not found
  #   File "/nix/store/smng9jxnqqm9s4gcxzdswwn5wi3ym5iz-python3.10-mealie-v1.0.0-RC2/lib/python3.10/site-packages/mealie/db/init_db.py", line 47, in db_is_at_head
  #     directory = script.ScriptDirectory.from_config(alembic_cfg)
  #   File "/nix/store/ca6gj26yjk7dwqxv236gm2s27grc24xv-python3.10-alembic-1.12.0/lib/python3.10/site-packages/alembic/script/base.py", line 162, in from_config
  #     script_location = config.get_main_option("script_location")
  #   File "/nix/store/ca6gj26yjk7dwqxv236gm2s27grc24xv-python3.10-alembic-1.12.0/lib/python3.10/site-packages/alembic/config.py", line 332, in get_main_option
  #     return self.get_section_option(self.config_ini_section, name, default)
  #   File "/nix/store/ca6gj26yjk7dwqxv236gm2s27grc24xv-python3.10-alembic-1.12.0/lib/python3.10/site-packages/alembic/config.py", line 305, in get_section_option
  #     raise util.CommandError(
  #        alembic.util.exc.CommandError: No config file '/nix/store/smng9jxnqqm9s4gcxzdswwn5wi3ym5iz-python3.10-mealie-v1.0.0-RC2/lib/python3.10/site-packages/alembic.ini' found>
        
        ExecStart = "${backend.pythonpkg.gunicorn}/bin/gunicorn -b 0.0.0.0:9000 -k uvicorn.workers.UvicornWorker mealie.app:app";
        StateDirectory = "mealie";
      };
    };
  };
}
