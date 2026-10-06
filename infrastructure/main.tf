module "dns" {
  source = "./modules/aws-dns"
}

module "frankfurt" {
  source = "./modules/aws-network"
}

module "ecr" {
  source = "./modules/aws-ecr"
}

module "app_cluster" {
  source       = "./modules/aws-eks"
  cluster_name = "Main"
}

module "bastion" {
  source = "./modules/aws-bastion"
}
