{
  description = "Build sashai-browser-1 from drunkod/nixpkgs fork";

  inputs = {
    # Pull nixpkgs from the fork/branch
    nixpkgs.url = "github:drunkod/nixpkgs/sashai-browser-1";
    # Replace "branch-name" with the actual branch you meant (e.g. "sashai-browser-1").
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in {
      packages.${system} = {
        default = pkgs.callPackage ./default.nix { };
        sashai-browser-1 = pkgs.callPackage ./default.nix { };
      };
    };
}