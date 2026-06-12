{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    opentofu
    talosctl
    fluxcd
    sops
    age
    jq
    git
    gitleaks
    pre-commit
  ];
}
