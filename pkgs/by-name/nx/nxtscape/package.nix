# nxtscape/package.nix
{
  lib,
  stdenv,
  makeWrapper,
  callPackage,
  # package customization
  commandLineArgs ? "",
  ...
} @ args:

let
  nxtscape-unwrapped = callPackage ./common.nix args;
in
stdenv.mkDerivation {
  pname = "nxtscape";
  version = nxtscape-unwrapped.version;

  src = nxtscape-unwrapped.src;

  nativeBuildInputs = [
    makeWrapper
  ];

  buildInputs = nxtscape-unwrapped.buildInputs;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -R ${nxtscape-unwrapped}/. $out/

    ${if stdenv.isDarwin then ''
      # Create command-line wrapper for macOS
      makeWrapper $out/Applications/Nxtscape.app/Contents/MacOS/Nxtscape $out/bin/nxtscape \
        --add-flags "--use-mock-keychain" \
        --add-flags ${lib.escapeShellArg commandLineArgs}
    '' else ''
      # Create command-line wrapper for Linux
      makeWrapper $out/bin/nxtscape $out/bin/nxtscape-wrapped \
        --add-flags ${lib.escapeShellArg commandLineArgs} \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}"

      mv $out/bin/nxtscape-wrapped $out/bin/nxtscape
    ''}

    runHook postInstall
  '';

  meta = nxtscape-unwrapped.meta // {
    # The `unwrapped` derivation is not meant to be used directly
    # so we move the description to the wrapper.
    description = "Nxtscape - AI-enhanced Chromium-based browser";
  };
}
