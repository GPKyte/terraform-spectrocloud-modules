locals {
  clusters = {
  for k in fileset("examples-profile/config/cluster", "cluster-eks-*.yaml"):
    trimsuffix(k, ".yaml") => yamldecode(file("examples-profile/config/cluster/${k}"))
  }

  profiles = {
    for k in fileset("examples-profile/config/profile", "profile-*.yaml"):
    trimsuffix(k, ".yaml") => yamldecode(file("examples-profile/config/profile/${k}"))
  }
}
