{pkgs, lib, ...}: let
  version = "6.8.0";
  lib_deps = with pkgs; [
    openssl.out
    openssl.dev
    curl.dev
    zlib.dev
    zlib.out
    sqlite.dev
    sqlite.out
    libxml2.dev
    libz.dev
    libz.out
    libvncserver.dev
    libvncserver.out
    libnsl
    libjpeg.out
    libjpeg.dev
    gnutls.dev
    gnutls.out
    libpng.out
    libpng.dev
  ];

  INCLUDE_FLAGS = builtins.concatStringsSep " " (
    builtins.map (inc: "-I${inc}/include") lib_deps
  );

  LIB_FLAGS = builtins.concatStringsSep " " (
    builtins.map (inc: "-L${inc}/lib") lib_deps
  );

in pkgs.stdenv.mkDerivation {
  name = "one";
  inherit version;
  src = pkgs.fetchFromGitHub {
    owner = "OpenNebula";
    repo = "one";
    rev = "release-${version}";
    sha256 = "sha256-GsSIh1tzS9kbMRKmc+jYSdJthCKXtz8xnSc0HT2a8fY=";
  };

  patches = [
    ./svncterm_server_scons.patch
    ./install_remove_chown.patch
  ];

  buildInputs = with pkgs; [
    pkg-config
    scons
    ruby
    xmlrpc_c
    libxml2.dev
  ];

  PKG_CONFIG_PATH = lib.makeLibraryPath lib_deps;
  CFLAGS = INCLUDE_FLAGS + " " + LIB_FLAGS;
  CXXFLAGS = INCLUDE_FLAGS + " " + LIB_FLAGS;
  LDFLAGS = INCLUDE_FLAGS + " " + LIB_FLAGS;
  LINKFLAGS = INCLUDE_FLAGS + " " + LIB_FLAGS;

  buildPhase = let
    scons_args = builtins.concatStringsSep " " [
      "new_xmlrpc=yes"
      "gitversion=release-${version}"
      # "docker_machine=yes"
    ];
  in ''
    patchShebangs ./share

    cd src/svncterm_server/
    scons -j $(nproc)

    cd ../../
    scons ${scons_args} -j $(nproc)
  '';

  # TODO  FIXME   Install phase
  installPhase = ''
    patchShebangs ./install.sh
    mkdir -p $out/bin $out/sbin $out/lib $out/etc $out/var
    ./install.sh -u one -g one -d $out
  '';
}
