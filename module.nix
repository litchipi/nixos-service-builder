{config, pkgs, lib, ...}: {
  services.firefly-iii = {
    enable = true;
    settings.APP_KEY_FILE = "/appkeyfile";
  };

  system.activationScripts.setup_keyfile = ''
    echo "mysecretpassword" > /appkeyfile
    chown firefly-iii:firefly-iii /appkeyfile
  '';
}
