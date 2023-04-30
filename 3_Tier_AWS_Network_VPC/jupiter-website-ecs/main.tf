# provider
provider "aws" {
  region = var.region
}

# create vpc

module "vpc" {
  source                       = "../modules/VPC"
  region                       = var.region
  vpc_cidr                     = var.vpc_cidr
  project_name                 = var.project_name
  public_subnet_az1_cidr       = var.public_subnet_az1_cidr
  public_subnet_az2_cidr       = var.public_subnet_az2_cidr
  private_app_subnet_az1_cidr  = var.private_app_subnet_az1_cidr
  private_app_subnet_az2_cidr  = var.private_app_subnet_az2_cidr
  private_data_subnet_az1_cidr = var.private_data_subnet_az1_cidr
  private_data_subnet_az2_cidr = var.private_data_subnet_az2_cidr

}

module "nat_gateway" {
  source                     = "../modules/nat-gateway"
  public_subnet_az1_id       = module.vpc.public_subnet_az1_id
  internet_gateway           = module.vpc.internet_gateway
  public_subnet_az2_id       = module.vpc.public_subnet_az2_id
  vpc_id                     = module.vpc.vpc_id
  private_app_subnet_az1_id  = module.vpc.private_app_subnet_az1_id
  private_data_subnet_az1_id = module.vpc.private_data_subnet_az1_id
  private_app_subnet_az2_id  = module.vpc.private_app_subnet_az2_id
  private_data_subnet_az2_id = module.vpc.private_data_subnet_az2_id
}

module "security_groups" {
  source = "../modules/security-groups"
  vpc_id = module.vpc.vpc_id
}

module "ecs_task_execution_role" {
  source       = "../modules/ecs-task-execution-role"
  project_name = module.vpc.project_name
}

module "acm" {
  source            = "../modules/acm"
  domain_name       = var.domain_name
  alternative_names = var.alternative_names
}

module "alb" {
  source                = "../modules/alb"
  project_name          = module.vpc.project_name
  alb_security_group_id = module.security_groups.alb_security_group_id
  public_subnet_az1_id  = module.vpc.public_subnet_az1_id
  public_subnet_az2_id  = module.vpc.public_subnet_az2_id
  vpc_id                = module.vpc.vpc_id
  certificate_arn       = module.acm.certificate_arn
}

module "ecs" {
  source                      = "../modules/ecs"
  project_name                = module.vpc.project_name
  ecs_task_execution_role_arn = module.ecs_task_execution_role.ecs_task_execution_role_arn
  container_image             = var.container_image
  region                      = module.vpc.region
  private_app_subnet_az1_id   = module.vpc.private_app_subnet_az1_id
  private_app_subnet_az2_id   = module.vpc.private_app_subnet_az2_id
  ecs_security_group_id       = module.security_groups.ecs_security_group_id
  alb_target_group_arn        = module.alb.alb_target_group_arn
}