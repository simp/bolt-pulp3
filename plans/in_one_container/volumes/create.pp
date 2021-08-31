# @summary Ensure volumes exist for the pulp container and prepopulate as necessary
#
# @param volume_names
#   The Volumes to create
#
# @private true
#
# Details at https://pulpproject.org/pulp-in-one-container/
plan pulp3::in_one_container::volumes::create (
  TargetSpec $host,
  String[1] $runtime_exe,
  Stdlib::Port $container_port,
  Array[String[1]] $volume_names = [
    'pulp-containers',
    'pulp-pgsql',
    'pulp-run',
    'pulp-settings',
    'pulp-storage'
  ],
  Boolean $noop = false,
) {
  apply(
    $host,
    '_description' => 'Ensure volumes exist for pulp container',
    '_noop' => $noop,
    '_catch_errors' => false,
  ){
    $volume_names.each |String $volume_name| {
      exec { "Create ${volume_name}":
        command => "${runtime_exe} volume create ${volume_name}",
        unless  => "${runtime_exe} volume inspect ${volume_name}",
        path    => [
          '/bin',
          '/usr/bin'
        ]
      }
    }
  }

  $pulp_settings = @("SETTINGS"/n)
    CONTENT_ORIGIN='http://${host.facts['fqdn']}:${container_port}'
    ANSIBLE_API_HOSTNAME='http://${host.facts['fqdn']}:${container_port}'
    ANSIBLE_CONTENT_HOSTNAME='http://${host.facts['fqdn']}:${container_port}/pulp/content'
    TOKEN_AUTH_DISABLED=True
    ALLOWED_CONTENT_CHECKSUMS=['sha224', 'sha256', 'sha384', 'sha512', 'sha1', 'md5']
    ALLOWED_IMPORT_PATHS=['/run/ISOs/unpacked','/allowed_imports']
    LOGGING={
        'version': 1,
        'disable_existing_loggers': False,
        'formatters': {
            'console': {
                'format': '%(name)-12s %(levelname)-8s %(message)s'
            },
            'file': {
                'format': '%(asctime)s %(name)-12s %(levelname)-8s %(message)s'
            }
        },
        'handlers': {
            'console': {
                'class': 'logging.StreamHandler',
                'formatter': 'console'
            },
            'file': {
                'level': 'INFO',
                'class': 'logging.FileHandler',
                'formatter': 'file',
                'filename': '/run/django-info.log'
            }
        },
        'loggers': {
            '': {
                'level': 'INFO',
                'handlers': ['console', 'file']
            }
        }
    }
    | SETTINGS

  $tmp_container_out = run_command("${runtime_exe} run -id --name pulp_tmp --volume pulp-settings:/pulp centos:8", $host)

  $create_settings_py_out = run_command("(${runtime_exe} exec -i pulp_tmp sh -c 'cat > /pulp/settings.py') << EOM\n${pulp_settings}\nEOM", $host)

  $destroy_tmp_container_out = run_command("${runtime_exe} rm -f pulp_tmp", $host)
}
