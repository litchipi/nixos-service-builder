{config, pkgs, lib, ...}: let
# https://github.com/mealie-recipes/mealie/blob/mealie-next/docker/Dockerfile
  version = "v1.0.0-RC2";
  mealie_src = pkgs.fetchFromGitHub {
    repo = "mealie";
    owner = "mealie-recipes";
    rev = version;
    sha256 = lib.fakeSha256;
  };

  frontend = pkgs.dockerTools.buildImage {
    name = "mealie-frontend";
    fromImage = pkgs.dockerTools.pullImage {
    };
    runAsRoot = ''
      #!${pkgs.runtimeShell}
      cp -r ${mealie_src}/frontend ./
      yarn install \
        --prefer-offline \
        --frozen-lockfile \
        --non-interactive \
        --production=false \
        # https://github.com/docker/build-push-action/issues/471
        --network-timeout 1000000
    '';
  };

  oci-image = pkgs.dockerTools.buildImage {
    name = "mealie";
    tag = version;
    runAsRoot = ''
      #!${pkgs.runtimeShell}
    '';
    # config = {
    #   Cmd = [ "/bin/redis-server" ];
    #   WorkingDir = "/data";
    #   Volumes = { "/data" = { }; };
    # };
  };
in {
  virtualisation.oci-containers.containers.mealy = {
  };
}
