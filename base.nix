{config, pkgs, lib, ...}: {
  networking.hostName = "srv-builder";

  users.users.op = {
    password = "op";
    isNormalUser = true;
    group = "op";
  };
  users.groups.op = {};

  system.stateVersion = "23.11";
}
