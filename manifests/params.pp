
class drupal::params inherits drupal::default {

  include git::params

  #---

  $base_name               = 'drupal'

  #-----------------------------------------------------------------------------

  $drush_package           = module_param('drush_package', 'drush/drush')
  $drush_ensure            = module_param('drush_ensure', 'present')
  $drush_source            = module_param('drush_source', 'pear.drush.org/drush')

  $drush_root              = module_param('drush_root')

  #---

  $home_dir                = module_param('home_dir')
  $build_dir               = module_param('build_dir')
  $release_dir             = module_param('release_dir')
  $release_mode            = module_param('release_mode', '0775')

  #---

  $settings_template       = module_param('settings_template')

  $aliases                 = module_param('aliases', '')

  $use_make                = module_param('use_make', true)
  $repo_name               = module_param('repo_name', 'panopoly')
  $source                  = module_param('source', 'git://git.drupal.org/project/panopoly.git')
  $revision                = module_param('revision', '7.x-1.x')
  $make_file               = module_param('make_file', 'build-panopoly.make')
  $include_repos           = module_param('include_repos', false)

  $server_user             = module_param('server_user', 'root')
  $server_group            = module_param('server_group', 'root')

  $site_dir                = module_param('site_dir', 'default')
  $site_ip                 = module_param('site_ip', $::ipaddress)

  $admin_email             = module_param('admin_email', '')

  $files_dir               = module_param('files_dir', '')
  $databases               = module_hash('databases', {})

  $dir_mode                = module_param('dir_mode', '0770')
  $site_dir_mode           = module_param('site_dir_mode', '0700')

  $base_url                = module_param('base_url', '')
  $cookie_domain           = module_param('cookie_domain', '')
  $session_max_lifetime    = module_param('session_max_lifetime', '200000')
  $session_cookie_lifetime = module_param('session_cookie_lifetime', '2000000')
  $pcre_backtrack_limit    = module_param('pcre_backtrack_limit', '200000')
  $pcre_recursion_limit    = module_param('pcre_recursion_limit', '200000')

  $ini_settings            = module_hash('ini_settings', {})
  $conf                    = module_hash('conf', {})
}
