{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    terraform
    talosctl
    fluxcd
    sops
    age
    jq
    git
    gitleaks
    pre-commit
    tflint
    terraform-docs
  ];
}
