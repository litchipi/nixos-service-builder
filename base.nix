{...}: let
  username = "op";
  stateVersion = "23.11";
  col_user = [204 158 133];
  col_wdir = [133 204 158];
  term_size = [53 210];
in {
  networking.hostName = "srv-builder";

  users.users.${username} = {
    password = username;
    isNormalUser = true;
    group = username;
    extraGroups = ["wheel"];
  };
  users.groups.${username} = {};

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${username} = {
      home.stateVersion = stateVersion;
      programs.bash = {
        enable = true;
        sessionVariables = {
          COLORTERM = "truecolor";
          TERM = "xterm-256color";
        };
        initExtra = let
          to_col = col: builtins.concatStringsSep ";" (builtins.map builtins.toString ([38 2] ++ col));
          add_col = prefix: col: "\\[\\033[0m${prefix}\\033[${to_col col}m\\]";
        in ''
          export PS1="${add_col "\\033[1m" col_user}\u ${add_col "" col_wdir}\w \[\033[0m\]$ ";
          stty columns ${builtins.toString (builtins.elemAt term_size 1)}
          stty rows ${builtins.toString (builtins.elemAt term_size 0)}
        '';
      };
    };
  };

  system.stateVersion = stateVersion;
}
