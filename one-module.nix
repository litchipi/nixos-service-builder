# Module for open-nebula
# Config taken from the Ubuntu package of Open-nebula
{config, lib, pkgs, ...}: let
  package = import ./one.nix { inherit pkgs lib; };
  cfg = config.services.open-nebula;
in {
  options.services.open-nebula = {
    enable = lib.mkEnableOption { description = "Enable the Open-Nebula service"; };
    user = lib.mkOption {
      default = "one";
      description = "User that uses the OpenNebula project";
      type = lib.types.str;
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.user;
    };
    users.groups.${cfg.user} = {};

    environment.etc."one" = {
      enable = true;
      source = "${package}/etc/";
    };

    # TODO  Setup logrotate + gzip logs on all services

    systemd.services.opennebula = let
      lockdir = "/run/var/lock/one/one";
    in {
      enable = true;
      description = "OpenNebula Cloud Controller Daemon";
      wantedBy = [ "multi-user.target" ];
      after = [
        "syslog.target" "network.target" "remote-fs.target"
        "mariadb.service" "mysql.service"
        "opennebula-ssh-agent.service"
      ];
      wants = [
        "opennebula-scheduler.service" "opennebula-hem.service"
        "opennebula-ssh-agent.service"
        "opennebula-ssh-socks-cleaner.timer"
        "opennebula-showback.timer"
      ];
      path = [ package ];
      serviceConfig = {
        Type = "notify";
        User = cfg.user;
        Group = cfg.user;
        PIDFile = "${lockdir}/one";
        StartLimitInterval = 60;
        StartLimitBurst = 3;
        ExecStartPre = pkgs.writeShellScript "one_pre_cleanup" ''
          if [[ ! -f ${lockdir}/oned.pid && -f ${lockdir}/one ]]; then
              rm ${lockdir}/one
          fi
        '';
        ExecStart = "oned -f";
        Restart="on-failure";
        RestartSec=5;
        SyslogIdentifier="opennebula";
      };
    };

    systemd.services.opennebula-scheduler = {
      enable = true;
      description = "OpenNebula Cloud Scheduler Daemon";
      path = [ package ];
      wantedBy = [ "multi-user.target" ];
      after = ["syslog.target" "network.target" "remote-fs.target" "opennebula.service"];
      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.user;
        StartLimitInterval = 60;
        StartLimitBurst = 3;
        ExecStart = "${package}/bin/mm_sched";
        Restart="on-failure";
        RestartSec=5;
        SyslogIdentifier="opennebula-scheduler";
      };
    };

    systemd.services.opennebula-hem = {
      enable = true;
      description = "OpenNebula Hook Execution Service";
      path = [ package ];
      wantedBy = [ "multi-user.target" ];
      after = ["syslog.target" "network.target" "opennebula.service"];
      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.user;
        ExecStart = "${pkgs.ruby}/bin/ruby ${package}/lib/onehem/onehem-server.rb";
        StartLimitInterval = 60;
        StartLimitBurst = 3;
        Restart="on-failure";
        RestartSec=5;
        SyslogIdentifier="opennebula-hem";
      };
    };

    systemd.services.opennebula-ssh-agent = {
      enable = true;
      description = "OpenNebula SSH agent";
      path = [ package pkgs.openssh ];
      wantedBy = [ "default.target" ];
      after = ["remote-fs.target"];

      script = ''
        export SSH_AUTH_SOCK="/var/run/one/ssh-agent.sock"
        mkdir -p /var/run/one/
        echo SSH_AUTH_SOCK=$SSH_AUTH_SOCK > /var/run/one/ssh-agent.env
        rm -f $SSH_AUTH_SOCK
        ssh-agent -a $SSH_AUTH_SOCK
        ssh-add
        rm -f /var/run/one/ssh-agent.env
      '';

      serviceConfig = {
        Type = "forking";
        User = cfg.user;
        Group = cfg.user;
        StartLimitInterval = 60;
        StartLimitBurst = 3;
        Restart="on-failure";
        RestartSec=5;
        ExecReload = "/usr/bin/ssh-add -D && /usr/bin/ssh-add";
        SuccessExitStatus = 2;
        SyslogIdentifier = "opennebula-ssh-agent";
      };
    };

    systemd.services.opennebula-showback = {
      enable = true;
      description = "OpenNebula's periodic showback calculation";
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        Group = cfg.user;
        ExecStart = "${package}/bin/oneshowback calculate";
        SyslogIdentifier = "opennebula-showback";
      };
    };

    systemd.timers.opennebula-ssh-socks-cleaner = {
      enable = true;
      description = "OpenNebula SSH persistent connection cleaner";
      wantedBy = ["default.target"];
      after = ["remote-fs.target"];
      timerConfig = {
        OnCalendar = [
          "*-*-* *:*:10"
          "*-*-* *:*:40"
        ];
        AccuracySec = "s";
      };
    };

    systemd.timers.opennebula-showback = {
      enable = true;
      description = "OpenNebula's periodic showback calculation";
      wantedBy = ["default.target"];
      after = ["remote-fs.target"];
      timerConfig = {
        OnCalendar = "daily";
        AccuracySec = "1h";
        Persistent = true;
      };
    };
  };
}
