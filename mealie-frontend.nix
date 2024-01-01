{ pkgs, lib, src, version, ...}:
(pkgs.mkYarnPackage {
  name = "mealie-frontend";
  src = "${src}/frontend";
  packageJSON = "${src}/frontend/package.json";
  yarnLock = "${src}/frontend/yarn.lock";
}).overrideAttrs (oldAttrs: let
  pname = oldAttrs.pname;
in
  {
    doDist = false;

    buildPhase = ''
      runHook preBuild
      shopt -s dotglob

      rm deps/${pname}/node_modules
      mkdir deps/${pname}/node_modules
      pushd deps/${pname}/node_modules
      ln -s ../../../node_modules/* .
      popd
      export NUXT_TELEMETRY_DISABLED=1
      yarn --offline --non-interactive --production=false build
      yarn --offline --non-interactive --produciton=false generate
      runHook postBuild
    '';

    installPhase = let
      dirname = "dist";
    in ''
      runHook preInstall
      ls -lh deps/${pname}/
      mv deps/${pname}/${dirname} $out
      runHook postInstall
    '';
  })
