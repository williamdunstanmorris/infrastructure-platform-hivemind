module "dns" {
  source = "./modules/aws-dns"
}

module "vpc_frankfurt" {
  source = "./modules/aws-network"
}

module "ecr" {
  source = "./modules/aws-ecr"
}

module "app_cluster" {
  source          = "./modules/aws-eks"
  cluster_name    = "Main"
  hosted_zone_arn = module.dns.zone_arn
  depends_on = [
    module.vpc_frankfurt
  ]
}

module "bastion" {
  source = "./modules/aws-bastion"
  depends_on = [
    module.vpc_frankfurt,
    module.app_cluster
  ]
}
