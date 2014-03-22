
define drupal::site (

  $domain                  = $name,
  $aliases                 = $drupal::params::aliases,
  $home_dir                = $drupal::params::home_dir,
  $build_dir               = $drupal::params::build_dir,
  $release_dir             = $drupal::params::release_dir,
  $use_make                = $drupal::params::use_make,
  $dir_mode                = $drupal::params::dir_mode,
  $file_mode               = $drupal::params::file_mode,
  $repo_name               = $drupal::params::repo_name,
  $git_home                = $git::params::home_dir,
  $git_user                = $git::params::user,
  $git_group               = $git::params::group,
  $source                  = $drupal::params::source,
  $revision                = $drupal::params::revision,
  $make_file               = $drupal::params::make_file,
  $include_repos           = $drupal::params::include_repos,
  $server_user             = $drupal::params::server_user,
  $server_group            = $drupal::params::server_group,
  $site_dir                = $drupal::params::site_dir,
  $settings_template       = $drupal::params::settings_template,
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

) {

  #-----------------------------------------------------------------------------

  $definition_name = name("drupal_site_${name}")

  #---

  $build_dir_real = ensure($build_dir, $build_dir, $home_dir)
  $repo_dir_real  = ensure($use_make,
    ensure($git_home, "${git_home}/${repo_name}.git", "${repo_name}.git"),
    $build_dir_real
  )
  $repo_name_real = ensure($git_home and $use_make, "${repo_name}.git", $repo_dir_real)

  #-----------------------------------------------------------------------------
  # Drupal repository (pre processing)

  git::repo { $definition_name:
    path              => $repo_name_real,
    user              => $git_user,
    owner             => $git_user,
    group             => $server_group,
    home_dir          => ensure($git_home and $use_make, $git_home, ''),
    source            => $source,
    revision          => $revision,
    base              => false,
    monitor_file_mode => false,
    update_notify     => ensure($use_make, Exec["${definition_name}_make"])
  }

  if $use_make {
    #---------------------------------------------------------------------------
    # Distribution releases with drush make

    $date_time_str      = strftime("%F-%R")
    $working_copy       = ensure($include_repos, '--working-copy', '')

    $domain_release_dir = "${release_dir}/${date_time_str}"
    $profile_dir        = "${domain_release_dir}/profiles/${repo_name}"

    #---

    corl::exec { $definition_name:
      resources => {
        make => {
          command => "drush make ${working_copy} '${repo_dir_real}/${make_file}' '${domain_release_dir}'",
          creates => $domain_release_dir
        },
        copy => {
          command   => "cp -Rf '${repo_dir_real}' '${profile_dir}'",
          creates   => $profile_dir,
          subscribe => 'make',
          notify    => Corl::Exec["${definition_name}_source"]
        },
        release => {
          command   => "rm -f '${home_dir}'; ln -s '${domain_release_dir}' '${home_dir}'",
          subscribe => Corl::File[$definition_name]
        }
      },
      defaults => {
        refreshonly => true
      },
      require => [ File['drupal-releases'], Git::Repo[$definition_name] ]
    }
  }

  #-----------------------------------------------------------------------------
  # Configuration
  
  #corl::exec { "${definition_name}_source":
  #  resources => {
  #    dir_mode => {
  #      command => "find ${home_dir} -type d -exec chmod ${dir_mode} {} \\;"
  #    },
  #    file_mode => {
  #      command => "find ${home_dir} -type f -exec chmod ${file_mode} {} \\;"
  #    }
  #  },
  #  require => Git::Repo[$definition_name]
  #}
  
  #---

  corl::file { $definition_name:
    resources => {
      config => {
        path    => "${home_dir}/sites/${site_dir}/settings.php",
        mode    => '0660',
        content => template($settings_template),
      },
      files => {
        path   => "${home_dir}/sites/${site_dir}/files",
        ensure => ensure($files_dir, 'link', 'directory'),
        target => ensure($files_dir),
        force  => ensure($files_dir, true),
        mode   => $file_mode
      }
    },
    defaults => {
      owner => $git_user,
      group => $server_group
    },    
    require => Git::Repo[$definition_name] #Corl::Exec["${definition_name}_source"]
  }

  #-----------------------------------------------------------------------------
  # Actions

  corl::exec { "${definition_name}_extra": }

  #-----------------------------------------------------------------------------
  # Cron

  corl::cron { $definition_name: }
}
