{ pkgs, packageIndex }:

let
  inherit (pkgs) lib;

  parseLine = line:
    let
      match = builtins.match "([^:]+): (.*)" line;
    in
    if match == null then null else {
      name = builtins.elemAt match 0;
      value = builtins.elemAt match 1;
    };

  parseStanza = stanza:
    builtins.listToAttrs (
      builtins.filter (field: field != null) (
        map parseLine (lib.splitString "\n" stanza)
      )
    );

  releases = builtins.filter
    (release: (release.Package or null) == "claude-desktop")
    (map parseStanza (lib.splitString "\n\n" (builtins.readFile packageIndex)));

  latest = lib.last (
    lib.sort
      (older: newer: lib.versionOlder older.Version newer.Version)
      releases
  );

  deb = pkgs.fetchurl {
    url = "https://downloads.claude.ai/claude-desktop/apt/stable/${latest.Filename}";
    sha256 = latest.SHA256;
  };

  unwrapped = pkgs.stdenv.mkDerivation {
    pname = "claude-desktop-unwrapped";
    version = latest.Version;

    src = deb;
    nativeBuildInputs = [ pkgs.dpkg pkgs.gnutar ];
    dontUnpack = true;

    installPhase = ''
      runHook preInstall

      mkdir -p unpacked "$out"
      dpkg-deb --fsys-tarfile "$src" \
        | tar --extract --directory=unpacked --no-same-owner --no-same-permissions
      cp -a unpacked/usr/. "$out/"
      rm -rf "$out/share/doc" "$out/share/lintian"

      runHook postInstall
    '';
  };

  launcher = pkgs.writeShellScript "claude-desktop-launcher" ''
    exec ${unwrapped}/bin/claude-desktop \
      --ozone-platform=wayland \
      --password-store=gnome-libsecret \
      "$@"
  '';
in
pkgs.buildFHSEnv {
  pname = "claude-desktop";
  version = latest.Version;
  runScript = launcher;

  targetPkgs = p: with p; [
    glib
    nspr
    nss
    atk
    at-spi2-atk
    cups
    dbus
    cairo
    gtk3
    pango
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libgbm
    expat
    libxcb
    libxkbcommon
    systemd
    alsa-lib
    libsecret
    libnotify
    libdrm
    libxtst
    util-linux
    xdg-utils
    trash-cli
    libayatana-appindicator
    qemu_kvm
    OVMF.fd
    virtiofsd
  ];

  extraInstallCommands = ''
    mkdir -p "$out/share"
    cp -a ${unwrapped}/share/applications "$out/share/"
    cp -a ${unwrapped}/share/icons "$out/share/"
  '';

  meta = {
    description = "Desktop application for Claude.ai";
    homepage = "https://claude.ai";
    license = lib.licenses.unfree;
    mainProgram = "claude-desktop";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
