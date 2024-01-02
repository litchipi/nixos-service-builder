{config, ...}: {
  services.mealie = {
    enable = true;
    port = 8080;
    log_level = "DEBUG";
  };

  virtualisation.forwardPorts = [
    { from = "host"; guest.port = config.services.mealie.port; host.port = config.services.mealie.port; }
  ];
}
