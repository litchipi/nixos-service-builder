{config, pkgs, lib, ...}: let
  package = import ./one.nix { inherit pkgs lib; };
in {
  system.activationScripts.copy_one_homedir = ''
    cp -r ${package} /home/op/open-nebula
    chmod -R +w /home/op/open-nebula
    chown -R op:op /home/op/open-nebula
  '';
  services.open-nebula = {
    enable = true;
  };
}
