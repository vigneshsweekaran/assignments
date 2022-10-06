resource "kubernetes_namespace" "gitlab-runner" {
  metadata {
    name = "gitlab-runner"
  }
}

resource "helm_release" "gitlab-runner" {
  name       = "gitlab-runner"
  repository = "https://charts.gitlab.io"
  chart      = "gitlab-runner"
  version    = var.runner_version

  namespace  = "gitlab-runner"

  values = [
    templatefile("${path.module}/gitlab-runner-values.yaml", { runner_tag = "${var.runner_tag}" })
  ]

  set_sensitive {
    name  = "runnerRegistrationToken"
    value = var.runner_token
  }

  depends_on = [
    kubernetes_namespace.gitlab-runner
  ]

}