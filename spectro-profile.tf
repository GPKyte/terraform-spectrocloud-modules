locals {
  infra_profile_names = [for v in local.clusters : v.profiles.infra.name]

  addon_profile_names = flatten([
    for v in local.clusters : [
      for k in try(v.profiles.addons, []) : k.name
  ]])

  profile_names = toset(concat(local.infra_profile_names, local.addon_profile_names))

  profile_map = { //profiles is map of profile name and complete cluster profile object
    for k, v in data.spectrocloud_cluster_profile.this :
    v.name => v
  }

  cluster-profile-pack = flatten([
    for k, v in data.spectrocloud_cluster_profile.this : [
      for p in v.pack : { format("%s-%s", k, p.name) = p }
  ]])


  cluster-profile-pack-map = {
    for x in flatten([
      for k, v in data.spectrocloud_cluster_profile.this : [
        for p in v.pack : { name = format("%s-%s", k, p.name), pack = p }
    ]]) :
    x.name => x.pack
  }

  cluster_infra_profiles_map = {
    for v in local.clusters :
    v.name => v.profiles.infra
  }

  cluster_addon_profiles_map = {
    for v in local.clusters :
    v.name => try(v.profiles.addons, [])
  }

  cluster_profile_pack_manifests = { for v in flatten([
    for v in var.profiles : [
      for p in v.packs : {
        name  = format("%s-%s", v.name, p.name)
        value = try(p.manifests, [])
      }
    ]
    ]) : v.name => v.value
  }

  packs         = flatten([for v in local.profiles : [for vv in v.packs : vv if can(vv.version)]])
  pack_names    = [for v in local.packs : v.name]
  pack_versions = [for v in local.packs : v.version]

  count     = length(local.pack_names)
  pack_uids = [for index, v in local.packs : data.spectrocloud_pack.data_packs[index].id]
  pack_mapping = zipmap(
    [for i, v in local.packs : join("", [v.name, "-", v.version])],
    [for v in local.pack_uids : v]
  )

  cluster_profiles_map = {
  for v in local.profiles :
    v.name => v
  }

  //simple flat map structure
  /*

  {
  "<cp-name>-<pack-name>": "name: small-app
        spec: small-app"
  }

  */

/*

      - name: install-application
        is_manifest_pack: true
        manifest_name: install-app-crd
        override_type: params
        params: # cluster profile pack value/manifest content will be repeated as many times map of params is specified
          - PROFILE_NAME: small-app
            PROFILE_SPEC_NAME: small-app


        manifest
        ----
        name: small-app
        spec: small-app

*/
  cluster_profiles-params-replaced = { for v in flatten([
  for k, v in local.cluster_profiles_map : [ // k is cp name , v is cp
  for p in try(v.packs, []) : { //getting all packs from one cp
    name = format("%s-%s", k, p.name) //
    value = join("\n", [
    for line in split("\n", try(p.is_manifest_pack, false) ?
    element([for x in local.cluster_profiles_map[format("%s-%s", v.name, p.name)].manifest : x.content if x.name == p.manifest_name], 0) : //only if it is manifest pack
    local.cluster_profiles_map[format("%s-%s", v.name, p.name)].values) : //only if it is normal pack
    format(
    replace(line, "/%(${join("|", keys(p.params))})%/", "%s"),
    [
    for value in flatten(regexall("%(${join("|", keys(p.params))})%", line)) :
    lookup(p.params, value)
    ]...
    )
    ])
  } if p.override_type == "params"
  ]]) : v.name => v.value
  }
}

data "spectrocloud_pack" "data_packs" {
  count = length(local.pack_names)

  name    = local.pack_names[count.index]
  version = local.pack_versions[count.index]
}

data "spectrocloud_cluster_profile" "this" {
  for_each = local.profile_names

  name = each.value
}

resource "spectrocloud_cluster_profile" "profile_resource" {
  for_each    = local.profiles
  name        = each.value.name
  description = each.value.description
  cloud       = "eks"
  type        = each.value.type

  dynamic "pack" {
    for_each = each.value.packs
    content {
      name   = pack.value.name
      type   = try(pack.value.type, "spectro")
      tag    = try(pack.value.version, "")
      uid    = lookup(local.pack_mapping, join("", [pack.value.name, "-", try(pack.value.version, "")]), "uid")
      values = try(pack.value.values, "")

      dynamic "manifest" {
        for_each = toset(try(local.cluster_profile_pack_manifests[format("%s-%s", each.value.name, pack.value.name)], []))
        content {
          name    = manifest.value.name
          content = manifest.value.content
        }
      }
    }
  }
}
