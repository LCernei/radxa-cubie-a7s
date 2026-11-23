{
  description = "Tools for managing the Radxa Cubie A7S print/scan server";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in
    {
      devShells.x86_64-linux.default = pkgs.mkShell {
        packages = with pkgs; [
          ansible
          ansible-lint
          e2fsprogs
          mtools
          qemu
          sshpass
          shellcheck
          shfmt
          xz
        ];
      };
      formatter.x86_64-linux = pkgs.nixfmt;
    };
}
