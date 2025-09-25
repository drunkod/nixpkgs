# nxtscape/common.nix
{
  stdenv,
  lib,
  fetchFromGitHub,
  python3,
  gn,
  ninja,
  pkg-config,
  depot_tools,
  ed,
  gsettings-desktop-schemas,
  glib,
  gtk3,
  gtk4,
  adwaita-icon-theme,
  libva,
  pipewire,
  wayland,
  libkrb5,
  darwin,
  pkgs,

  # package customization
  proprietaryCodecs ? true,
  cupsSupport ? stdenv.isDarwin,
  pulseSupport ? false,
  buildType ? "release", # "debug" or "release"
  ...
}:

let
  # Use LLVM stdenv for better compatibility with Chromium build
  stdenv = if stdenv.isDarwin
    then pkgs.llvmPackages.stdenv
    else pkgs.rustc.llvmPackages.stdenv;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "nxtscape-unwrapped";
  version = "1.0.0"; # Replace with actual Nxtscape version

  src = fetchFromGitHub {
    owner = "nxtscape";  # Replace with actual owner
    repo = "nxtscape";   # Replace with actual repo
    rev = "main";        # Replace with specific commit/tag
    sha256 = lib.fakeSha256; # Replace with actual hash
  };

  nativeBuildInputs = [
    python3
    gn
    ninja
    pkg-config
    depot_tools
    ed
  ] ++ lib.optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [
    Cocoa
    WebKit
    Metal
    MetalKit
    CoreGraphics
    CoreServices
    Foundation
    AppKit
  ]);

  buildInputs = [
    libkrb5
  ] ++ lib.optionals stdenv.isLinux [
    gsettings-desktop-schemas
    glib
    gtk3
    gtk4
    adwaita-icon-theme
    libva
    pipewire
    wayland
  ];

  # Chromium source fetching phase
  prePatch = ''
    # Set up build directory structure as expected by Nxtscape
    mkdir -p build

    # This is where you'd fetch Chromium source
    # In a real implementation, you'd use fetchgit or similar
    # to get the specific Chromium version Nxtscape is based on

    # For now, assuming chromium source is provided separately
    # You might want to make this a separate derivation
  '';

  patches = [
    # Apply Nxtscape patches here
    # These would be the patches from the Nxtscape repository
  ];

  configurePhase = ''
    runHook preConfigure

    # Set up the build environment
    export CHROMIUM_BUILDTOOLS_PATH="${depot_tools}"
    export PATH="${depot_tools}:$PATH"

    # Configure GN args based on build type
    ${if buildType == "debug" then ''
      export GN_ARGS="is_debug=true"
    '' else ''
      export GN_ARGS="is_debug=false is_official_build=true"
    ''}

    ${lib.optionalString stdenv.isDarwin ''
      export GN_ARGS="$GN_ARGS target_os=\"mac\" target_cpu=\"arm64\""
    ''}

    ${lib.optionalString proprietaryCodecs ''
      export GN_ARGS="$GN_ARGS proprietary_codecs=true ffmpeg_branding=\"Chrome\""
    ''}

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    # Use Nxtscape's build script
    python build/build.py --build --build-type ${buildType}

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    ${if stdenv.isDarwin then ''
      mkdir -p $out/Applications
      cp -R out/Default/Nxtscape.app $out/Applications/
      mkdir -p $out/bin
    '' else ''
      mkdir -p $out/bin
      cp out/Default/nxtscape $out/bin/

      # Install desktop files and icons for Linux
      mkdir -p $out/share/applications
      mkdir -p $out/share/icons
    ''}

    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://github.com/nxtscape/nxtscape"; # Replace with actual URL
    license = licenses.bsd3; # Replace with actual license
    maintainers = with maintainers; [ ]; # Add maintainers
    platforms = [ "x86_64-darwin" "aarch64-darwin" "x86_64-linux" ];
  };
})
