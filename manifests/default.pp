
class drupal::default {

  case $::operatingsystem {
    debian, ubuntu: {
      $home_dir          = '/var/www'
      $build_dir         = ''
      $release_dir       = "${home_dir}/releases"

      $drush_root        = 'root'

      $settings_template = 'drupal/settings.php.erb'
    }
    default: {
      fail("The drupal module is not currently supported on ${::operatingsystem}")
    }
  }
}
