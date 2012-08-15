
class drupal::default {

  $drush_package           = 'drush/drush'
  $drush_ensure            = 'present'
  $drush_source            = 'pear.drush.org/drush'

  $aliases                 = ''

  $build_dir               = ''
  $use_make                = 'true'
  $repo_name               = 'panopoly'
  $source                  = 'git://git.drupal.org/project/panopoly.git'
  $revision                = '7.x-1.x'
  $make_file               = 'build-panopoly.make'
  $include_repos           = 'false'

  $server_user             = 'root'
  $server_group            = 'root'

  $site_dir                = 'default'
  $site_ip                 = $::ipaddress

  $admin_email             = ''

  $files_dir               = ''
  $databases               = ''

  $base_url                = ''
  $cookie_domain           = ''
  $session_max_lifetime    = ''
  $session_cookie_lifetime = ''
  $pcre_backtrack_limit    = ''
  $pcre_recursion_limit    = ''

  $ini_settings            = {}

  $conf                    = {}

  #---

  case $::operatingsystem {
    debian, ubuntu: {
      $home              = '/var/www'
      $build_dir         = ''
      $release_dir       = "${home}/releases"

      $settings_template = 'drupal/settings.php.erb'
    }
    default: {
      fail("The drupal module is not currently supported on ${::operatingsystem}")
    }
  }
}
