locals {
  accounts_params = { ACCOUNT_DEV_NAME = "dev-030", ACCOUNT_PROD_NAME = "prod-004" }
  bsl_params      = { BSL_NAME = "qa-sharma" }
  profile_params = {
    SPECTRO_REPO_URL       = "https://registry.spectrocloud.com",
    REPO_URL               = "593235963820.dkr.ecr.us-west-2.amazonaws.com",
    OIDC_CLIENT_ID         = "5ajs8pq0gatbgpjejld96fldrn",
    OIDC_ISSUER_URL        = "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_ajvPoziaS",
    RABBITMQ_PACK_VERSION  = "8.15.2",
    string                 = "$${string}",
    ADDON_SPECTRO_REPO_URL = "https://addon-registry.gehc.spectrocloud.com",
  }
  projects_params = {}

  clusters = {
    for k in fileset("config/cluster", "cluster-eks-*.yaml"):
    trimsuffix(k, ".yaml") => yamldecode(file("config/cluster/${k}"))
  }

  clusters_params = {
  for k in local.clusters :
  k.name => {
      VPC_ID       = module.core["core-${k.env}"].aws_vpc_main_id
#      AZ_SUBNETS = {
#      for k in keys(module.core["core-${k.env}"].aws_public_zone_subnets):
#        k => join(",", concat(tolist([lookup(module.core["core-${k.env}"].aws_public_zone_subnets, k, "")]), tolist([lookup(module.core["core-${k.env}"].aws_private_zone_subnets, k, "")])))
#      }
      PUBLIC_ZONE_SUBNETS = module.core["core-${k.env}"].aws_public_zone_subnets
      PRIVATE_ZONE_SUBNETS = module.core["core-${k.env}"].aws_private_zone_subnets
      FARGATE_ZONE_SUBNETS = values(module.core["core-${k.env}"].aws_private_zone_subnets)
    }
  }

#  clusters_params = {
#  for k in local.clusters :
#  k.name => {
#
##    cluster = merge(k, {
##      managedControlPlane: merge(local.k8s_values_map.managedControlPlane, {
##        // oidcIdentityProvider: merge(local.k8s_values_map.managedControlPlane.oidcIdentityProvider, lookup(local.oidc_config, "oidcIdentityProvider", local.default_oidc))
##        oidcIdentityProvider: merge(local.k8s_values_map.managedControlPlane.oidcIdentityProvider, local.oidc_config.oidcIdentityProvider)
##      })
##    })
#
#
#    VPC_ID       = module.core["core-${k.env}"].aws_vpc_main_id
#    AZ_SUBNETS = {
#    for k in keys(module.core["core-${k.env}"].aws_public_zone_subnets) :
#    k => join(",", concat(tolist([lookup(module.core["core-${k.env}"].aws_public_zone_subnets, k, "")]), tolist([lookup(module.core["core-${k.env}"].aws_private_zone_subnets, k, "")])))
#    }
#    PUBLIC_ZONE_SUBNETS = module.core["core-${k.env}"].aws_public_zone_subnets
#    PRIVATE_ZONE_SUBNETS = module.core["core-${k.env}"].aws_private_zone_subnets
#    FARGATE_ZONE_SUBNETS = values(module.core["core-${k.env}"].aws_private_zone_subnets)
#  }
#  }

#
#  clusters_params = {
#    VPC_ID       = module.core["core-${each.value.env}"].aws_vpc_main_id
#    AZ_SUBNETS = {
#      for k in keys(module.core["core-${each.value.env}"].aws_public_zone_subnets) :
#      k => join(",", concat(tolist([lookup(module.core["core-${each.value.env}"].aws_public_zone_subnets, k, "")]), tolist([lookup(module.core["core-${each.value.env}"].aws_private_zone_subnets, k, "")])))
#    }
#    PUBLIC_ZONE_SUBNETS = module.core["core-${each.value.env}"].aws_public_zone_subnets
#    PRIVATE_ZONE_SUBNETS = module.core["core-${each.value.env}"].aws_private_zone_subnets
#    FARGATE_ZONE_SUBNETS = values(module.core["core-${each.value.env}"].aws_private_zone_subnets)
#  }
}

#module "SpectroOrg" {
#  source = "github.com/spectrocloud/terraform-spectrocloud-modules"
#
#  accounts = {
#    for k in fileset("config/account", "account-*.yaml") :
#    trimsuffix(k, ".yaml") => yamldecode(templatefile("config/account/${k}", local.accounts_params))
#  }
#
#  bsls = {
#    for k in fileset("config/bsl", "bsl-*.yaml") :
#    trimsuffix(k, ".yaml") => yamldecode(templatefile("config/bsl/${k}", local.bsl_params))
#  }
#
#  profiles = {
#    for k in fileset("config/profile", "profile-*.yaml") :
#    trimsuffix(k, ".yaml") => yamldecode(templatefile("config/profile/${k}", local.profile_params))
#  }
#
#  projects = {
#    for k in fileset("config/project", "project-*.yaml") :
#    trimsuffix(k, ".yaml") => yamldecode(templatefile("config/project/${k}", local.projects_params))
#  }
#
#  teams = {
#    for k in fileset("config/project", "team-*.yaml") :
#    trimsuffix(k, ".yaml") => yamldecode(templatefile("config/project/${k}", {}))
#  }
#
#  registries = {
#    for k in fileset("config/registry", "registry-*.yaml") :
#    trimsuffix(k, ".yaml") => yamldecode(templatefile("config/registry/${k}", {}))
#  }
#}

#module "SpectroProject" {
#  //depends_on = [module.SpectroOrg]
#  source = "github.com/spectrocloud/terraform-spectrocloud-modules"
#
#  clusters = {
#    for k in fileset("config/cluster", "cluster-eks-*.yaml") :
#    trimsuffix(k, ".yaml") => yamldecode(templatefile("config/cluster/${k}", local.accounts_params))
#  }
#}