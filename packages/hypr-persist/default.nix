{ pkgs, src }:

pkgs.rustPlatform.buildRustPackage {
    pname = "hypr-persist";
    version = "0.1.2";
    inherit src;

    cargoLock.lockFile = "${src}/Cargo.lock";

    # Upstream forces mold, which is absent from Nix's Rust build environment.
    postPatch = ''
        substituteInPlace .cargo/config.toml \
            --replace-fail '-fuse-ld=mold' '-fuse-ld=bfd'
    '';

    meta = with pkgs.lib; {
        description = "Save and restore Hyprland windows and workspaces";
        homepage = "https://github.com/ngamber/hypr-persist";
        license = licenses.bsd3;
        mainProgram = "hypr-persist";
        platforms = platforms.linux;
    };
}
