resource "github_repository" "this" {
  name        = var.github_repository
  description = var.github_repository
  visibility  = "private"
  auto_init   = true # This is extremely important as flux_bootstrap_git will not work without a repository that has been initialised
}

resource "flux_bootstrap_git" "this" {
  depends_on = [github_repository.this]

  path = "clusters/${var.cluster_name}"
}