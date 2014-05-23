# Class: drupal
#
#   This module configures Drupal environments and manages Drupal sites.
#
#   Adrian Webb <adrian.webb@coraltech.net>
#   2012-05-22
#
#   Tested platforms:
#    - Ubuntu 12.04
#
# Parameters:
#
#
# Actions:
#
#   Configures Drupal environments and manages sites.
#
#   Provides the drupal::site() definition.
#
# Requires:
#
# Sample Usage:
#
#  include drupal
#
class drupal inherits drupal::params {

  $base_name = $drupal::params::base_name

  #-----------------------------------------------------------------------------
  # Drupal installation

  corl::package { $base_name:
    resources => {
      drush => {
        name     => $drupal::params::drush_package,
        ensure   => $drupal::params::drush_ensure,
        provider => pear,
        source   => $drupal::params::drush_source
      }
    }
  }

  #-----------------------------------------------------------------------------
  # Drupal setup

  corl::file { $base_name:
    resources => {
      drupal-releases => {
        path    => $drupal::params::release_dir,
        ensure  => directory,
        mode    => $drupal::params::release_mode
      }
    }
  }

  #---

  corl::exec { $base_name:
    resources => {
      drush_init => {
        command     => 'drush help',
        user        => $drupal::params::drush_root,
        refreshonly => true,
        subscribe   => Package["${base_name}_drush"]
      }
    }
  }
}
