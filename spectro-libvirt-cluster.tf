resource "spectrocloud_cluster_libvirt" "this" {
  for_each = { for x in local.libvirt_clusters: x.name => x }
  name     = each.value.name

  cloud_config {
    ssh_key = each.value.cloud_config.ssh_key
    vip = each.value.cloud_config.vip
    # ntp
  }

  #infra profile
  cluster_profile {
    id = local.profile_map[each.value.profiles.infra.name].id

    dynamic "pack" {
      for_each = try(each.value.profiles.infra.packs, [])
      content {
        name   = pack.value.name
        tag    = try(pack.value.version, "")
        type   = (try(pack.value.is_manifest_pack, false)) ? "manifest" : "spectro"
        values = (try(pack.value.is_manifest_pack, false)) ? local.cluster-profile-pack-map[format("%s-%s", each.value.profiles.infra.name, pack.value.name)].values : (pack.value.override_type == "values") ? pack.value.values : (pack.value.override_type == "params" ? local.infra-pack-params-replaced[format("%s-%s-%s", each.value.name, each.value.profiles.infra.name, pack.value.name)] : local.infra-pack-template-params-replaced[format("%s-%s-%s", each.value.name, each.value.profiles.infra.name, pack.value.name)])

        dynamic "manifest" {
          for_each = try([local.infra_pack_manifests[format("%s-%s-%s", each.value.name, each.value.profiles.infra.name, pack.value.name)]], [])
          content {
            name    = manifest.value.name
            content = manifest.value.content
          }
        }
      }
    }
  }

  #system profile
  dynamic "cluster_profile" {
    for_each = try([each.value.profiles.system.name], [])
    content {
      id = local.profile_map[each.value.profiles.system.name].id

      dynamic "pack" {
        for_each = try(each.value.profiles.system.packs, [])
        content {
          name   = pack.value.name
          tag    = try(pack.value.version, "")
          type   = (try(pack.value.is_manifest_pack, false)) ? "manifest" : "spectro"
          values = (try(pack.value.is_manifest_pack, false)) ? local.cluster-profile-pack-map[format("%s-%s", each.value.profiles.system.name, pack.value.name)].values : (pack.value.override_type == "values") ? pack.value.values : (pack.value.override_type == "params" ? local.infra-pack-params-replaced[format("%s-%s-%s", each.value.name, each.value.profiles.system.name, pack.value.name)] : local.infra-pack-template-params-replaced[format("%s-%s-%s", each.value.name, each.value.profiles.system.name, pack.value.name)])

          dynamic "manifest" {
            for_each = try([
              local.infra_pack_manifests[format("%s-%s-%s", each.value.name, each.value.profiles.system.name, pack.value.name)]
            ], [])
            content {
              name    = manifest.value.name
              content = manifest.value.content
            }
          }
        }
      }
    }
  }

  #TODO: add system profile reference 1-1 for libvirt, edge and edge-vsphere.

  dynamic "cluster_profile" {
    for_each = try(each.value.profiles.addons, [])

    content {
      id = local.profile_map[cluster_profile.value.name].id

      dynamic "pack" {
        for_each = try(cluster_profile.value.packs, [])
        content {
          name   = pack.value.name
          tag    = try(pack.value.version, "")
          type   = (try(pack.value.is_manifest_pack, false)) ? "manifest" : "spectro"
          values = (try(pack.value.is_manifest_pack, false)) ? local.cluster-profile-pack-map[format("%s-%s", cluster_profile.value.name, pack.value.name)].values : (pack.value.override_type == "values") ? pack.value.values : (pack.value.override_type == "params" ? local.addon_pack_params_replaced[format("%s-%s-%s", each.value.name, cluster_profile.value.name, pack.value.name)] : local.addon_pack_template_params_replaced[format("%s-%s-%s", each.value.name, cluster_profile.value.name, pack.value.name)])

          dynamic "manifest" {
            for_each = try(local.addon_pack_manifests[format("%s-%s-%s", each.value.name, cluster_profile.value.name, pack.value.name)], [])
            content {
              name    = manifest.value.name
              content = manifest.value.content
            }
          }
        }
      }
    }
  }

  dynamic "machine_pool" {
    for_each = each.value.node_groups
    content {
      name          = machine_pool.value.name
      control_plane           = try(machine_pool.value.control_plane, false)
      control_plane_as_worker = try(machine_pool.value.control_plane_as_worker, false)
      count                   = machine_pool.value.count

      dynamic "placements" {
        for_each = machine_pool.value.placements

        content {
          appliance_id = placements.value.appliance
          network_type = placements.value.network_type
          network_names = placements.value.network_names
          image_storage_pool = placements.value.image_storage_pool
          target_storage_pool = placements.value.target_storage_pool
          data_storage_pool = placements.value.data_storage_pool
          network = placements.value.network
        }
      }

      instance_type {
        disk_size_gb           = machine_pool.value.disk_size_gb
        memory_mb              = machine_pool.value.memory_mb
        cpu                    = machine_pool.value.cpu
        cpus_sets              = machine_pool.value.cpus_sets
        attached_disks_size_gb = machine_pool.value.attached_disks_size_gb
      }
    }
  }

  dynamic "backup_policy" {
    for_each = try(tolist([each.value.backup_policy]), [])
    content {
      schedule                  = backup_policy.value.schedule
      backup_location_id        = local.bsl_map[backup_policy.value.backup_location]
      prefix                    = backup_policy.value.prefix
      expiry_in_hour            = 7200
      include_disks             = true
      include_cluster_resources = true
    }
  }

  dynamic "scan_policy" {
    for_each = try(tolist([each.value.scan_policy]), [])
    content {
      configuration_scan_schedule = scan_policy.value.configuration_scan_schedule
      penetration_scan_schedule   = scan_policy.value.penetration_scan_schedule
      conformance_scan_schedule   = scan_policy.value.conformance_scan_schedule
    }
  }
}
