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

  patchPhase = ''
    patchShebangs ./share
  '';

  buildPhase = let
    scons_args = builtins.concatStringsSep " " [
      "new_xmlrpc=yes"
      "gitversion=release-${version}"
    ];
  in ''
    scons ${scons_args}
  '';
}
