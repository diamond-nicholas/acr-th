locals {
  common_tags = merge(
    var.tags,
    {
      workload    = "container-registry"
      managed_by  = "terraform"
      environment = var.environment
    }
  )
}
