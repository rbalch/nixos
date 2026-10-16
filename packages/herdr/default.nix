{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
}:

let
  # Upstream also ships linux-aarch64 and macos-x86_64; add their hashes here
  # if a host ever needs them.
  sources = {
    x86_64-linux = {
      asset = "herdr-linux-x86_64";
      hash = "sha256-l2FQoU1JDJSyQ+ouGn6y37Z/EuNrGC25CTb2co5q7PQ=";
    };
    aarch64-darwin = {
      asset = "herdr-macos-aarch64";
      hash = "sha256-pdT01QTYswnJH4EQUFWTAPq6MSWEJfU8UIUvyW9q5XQ=";
    };
  };
  source = sources.${stdenv.hostPlatform.system}
    or (throw "herdr: no prebuilt binary pinned for ${stdenv.hostPlatform.system}");
in
stdenvNoCC.mkDerivation rec {
  pname = "herdr";
  version = "0.8.2";

  src = fetchurl {
    url = "https://github.com/herdrdev/herdr/releases/download/v${version}/${source.asset}";
    inherit (source) hash;
  };

  dontUnpack = true;
  # The Linux binary needs its loader patched; the macOS one links system libs.
  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  installPhase = ''
    runHook preInstall
    install -Dm755 "$src" "$out/bin/herdr"
    runHook postInstall
  '';

  meta = {
    description = "Terminal workspace manager for AI coding agents";
    homepage = "https://herdr.dev";
    license = lib.licenses.asl20;
    mainProgram = "herdr";
    platforms = builtins.attrNames sources;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
