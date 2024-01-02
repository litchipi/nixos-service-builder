{...}: {
  services.mealie = {
    enable = true;
    port = 8080;
    log_level = "DEBUG";
  };
}
