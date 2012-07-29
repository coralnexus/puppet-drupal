
define drupal::site (

  $domain                  = $name,
  $aliases                 = $drupal::params::aliases,
  $home                    = $drupal::params::os_home,
  $build_dir               = $drupal::params::os_build_dir,
  $release_dir             = $drupal::params::os_release_dir,
  $use_make                = $drupal::params::use_make,
  $repo_name               = $drupal::params::repo_name,
  $git_home                = $git::params::os_home,
  $git_user                = $git::params::user,
  $git_group               = $git::params::group,
  $source                  = $drupal::params::source,
  $revision                = $drupal::params::revision,
  $make_file               = $drupal::params::make_file,
  $include_repos           = $drupal::params::include_repos,
  $server_user             = $drupal::params::server_user,
  $server_group            = $drupal::params::server_group,
  $site_dir                = $drupal::params::site_dir,
  $site_ip                 = $drupal::params::site_ip,
  $admin_email             = $drupal::params::admin_email,
  $files_dir               = $drupal::params::files_dir,
  $databases               = $drupal::params::databases,
  $base_url                = $drupal::params::base_url,
  $cookie_domain           = $drupal::params::cookie_domain,
  $session_max_lifetime    = $drupal::params::session_max_lifetime,
  $session_cookie_lifetime = $drupal::params::session_cookie_lifetime,
  $pcre_backtrack_limit    = $drupal::params::pcre_backtrack_limit,
  $pcre_recursion_limit    = $drupal::params::pcre_recursion_limit,
  $ini_settings            = $drupal::params::ini_settings,
  $conf                    = $drupal::params::conf,
  $settings_template       = $drupal::params::os_settings_template,

) {

  #-----------------------------------------------------------------------------

  $build_dir_real = $build_dir ? {
    ''      => $home,
    default => $build_dir,
  }

  $repo_dir_real = $use_make ? {
    'true'    => $git_home ? {
      ''        => "${repo_name}.git",
      default   => "${git_home}/${repo_name}.git",
    },
    default => $build_dir_real,
  }

  $repo_name_real = $git_home ? {
    ''      => $repo_dir_real,
    default => "${repo_name}.git",
  }

  #-----------------------------------------------------------------------------
  # Drupal repository (pre processing)

  git::repo { $repo_name_real:
    user     => $git_user,
    group    => $git_group,
    home     => $git_home,
    source   => $source,
    revision => $revision,
    base     => false,
  }

  exec { "check-${domain}":
    path      => [ '/bin', '/usr/bin' ],
    cwd       => $repo_dir_real,
    command   => "git rev-parse HEAD > ${repo_dir_real}/.git/_COMMIT",
    require   => Class['git'],
    subscribe => Git::Repo[$repo_name_real],
  }

  if $use_make {
    #---------------------------------------------------------------------------
    # Distribution releases with drush make

    $date_time_str      = strftime("%F-%R")
    $domain_release_dir = "$release_dir/$date_time_str"

    $test_git_cmd       = "diff ${repo_dir_real}/.git/_COMMIT ${repo_dir_real}/.git/_COMMIT.last"
    $test_release_cmd   = "test -d '${domain_release_dir}'"

    $working_copy = $include_repos ? {
      'true'  => '--working-copy',
      default => '',
    }

    exec { "make-release-${domain}":
      path      => [ '/bin', '/usr/bin' ],
      command   => "drush make ${working_copy} '${repo_dir_real}/${make_file}' '${domain_release_dir}'",
      creates   => $domain_release_dir,
      unless    => $test_git_cmd,
      require   => Class['drupal'],
      subscribe => Exec["check-${domain}"],
    }

    exec { "copy-release-${domain}":
      path        => [ '/bin', '/usr/bin' ],
      command     => "cp -Rf '${repo_dir_real}' '${domain_release_dir}/profiles/${repo_name}'",
      onlyif      => $test_release_cmd,
      subscribe   => Exec["make-release-${domain}"],
    }

    exec { "link-release-${domain}":
      path        => [ '/bin', '/usr/bin' ],
      command     => "rm -f '${home}'; ln -s '${domain_release_dir}' '${home}'",
      onlyif      => $test_release_cmd,
      subscribe   => Exec["copy-release-${domain}"],
    }

    file { "site-${domain}":
      path      => "${home}/sites",
      ensure    => directory,
      owner     => $server_user,
      group     => $server_group,
      recurse   => true,
      ignore    => '.git',
      subscribe => Exec["link-release-${domain}"],
    }

    #---

    Exec["check-${domain}"] ->
    Exec["make-release-${domain}"] ->
    Exec["copy-release-${domain}"] ->
    Exec["link-release-${domain}"] ->
    File["save-${domain}"]
  }
  else {
    #---------------------------------------------------------------------------
    # Git repositories

    file { "site-${domain}":
      path      => $home,
      ensure    => directory,
      owner     => $server_user,
      group     => $server_group,
      recurse   => true,
      ignore    => '.git',
      subscribe => Exec["check-${domain}"],
    }

    #---

    Exec["check-${domain}"] ->
    File["site-${domain}"] ->
    File["save-${domain}"]
  }

  #-----------------------------------------------------------------------------
  # Drupal settings

  file { "config-${domain}":
    path      => "${home}/sites/${site_dir}/settings.php",
    owner     => $server_user,
    group     => $server_group,
    mode      => '0660',
    content   => template($settings_template),
    subscribe => File["site-${domain}"],
  }

  #-----------------------------------------------------------------------------
  # Drupal files

  if $files_dir {
    file { "files-${domain}":
      path      => "${home}/sites/${site_dir}/files",
      ensure    => link,
      target    => $files_dir,
      owner     => $server_user,
      group     => $server_group,
      force     => true,
      subscribe => File["site-${domain}"],
    }
  }
  else {
    file { "files-${domain}":
      path      => "${home}/sites/${site_dir}/files",
      ensure    => directory,
      owner     => $server_user,
      group     => $server_group,
      mode      => '0770',
      subscribe => File["site-${domain}"],
    }
  }

  #-----------------------------------------------------------------------------
  # Drupal repository (post processing)

  file { "save-${domain}":
    path      => "${repo_dir_real}/.git/_COMMIT.last",
    owner     => 'root',
    group     => 'root',
    mode      => '0664',
    source    => "${repo_dir_real}/.git/_COMMIT",
    subscribe => Exec["check-${domain}"],
  }
}
