# @summary Manage a Pulp-in-one-container
# @param targets A single target to run on (the container host)
plan pulp::in_one_container (
  TargetSpec $targets = "localhost",
  Stdlib::AbsolutePath $container_root = system::env('PWD'),
  String[1] $user = system::env('USER'),
  String[1] $container_name = 'pulp',
  String[1] $container_image = 'pulp/pulp',
  Stdlib::Port $container_port = 8080,
  # FIXME not set up yet:
  Array[Stdlib::AbsolutePath] $import_paths = [ "${container_root}/run/ISOs/unpacked" ],
  Boolean $noop = false,
  Optional[Enum[podman,docker]] $runtime = undef,
  #  Enum[start,stop,destroy,directories,reset-admin-password] $action = 'start',
) {
  $host = get_target($targets)
  run_plan('facts', 'targets' => $host)

  $apply_el7_docker_fixes = (
    $host.facts['os']['family'] == 'Redhat' and
    $host.facts['os']['release']['major'] == '7'
  )

  $runtime_exe = run_plan(
    'pulp::in_one_container::validate_container_exe',
    {
      'host'                   => $host,
      'apply_el7_docker_fixes' => $apply_el7_docker_fixes,
      'runtime'                => $runtime,
    }
  )

  # docker socket hack
  # FIXME move this into another, more env-specific plan
  $setfacl_result = run_command(
    "setfacl --modify 'user:${user}:rw' /var/run/docker.sock",
    $host,
    {'_run_as' => 'root' },
  )

  $ls_result = run_command(
    "${runtime_exe} container ls --format='{{.Image}}  {{.ID}}  {{.Names}}'",
    $host,
  )
  if $ls_result[0].value['stdout'].split("\n").any |$x| {
    $x.match("^${container_image}.*${container_name}$")
  }{
    out::message( "Container '${container_name}' already running!" )
    return undef
  }

  $ls_a_result = run_command(
    "${runtime_exe} container ls -a --format='{{.Image}}  {{.ID}}  {{.Names}}'",
    $host,
  )
  if $ls_a_result[0].value['stdout'].split("\n").any |$x| {
    $x.match("^${container_image}.*${container_name}$" )
  }{
    out::message( "Restarting stopped container '${container_name}'..." )
    return run_command( "${runtime_exe} container start ${container_name}", $host )
  }

  out::message( "Starting new container '${container_name}' from image '${container_image}'..." )
  $apply_result = run_plan(
    'pulp::in_one_container::apply_local_filesystem',
    {
      'host'                   => $host,
      'container_root'         => $container_root,
      'container_port'         => $container_port,
      'import_paths'           => $import_paths,
      'apply_el7_docker_fixes' => $apply_el7_docker_fixes,
      'noop'                   => $noop,
    }
  )

  $selinux_suffix = $host.facts['selinux_enforced'] ? {
    true    => ':Z',
    default => '',
  }
  $start_cmd = @("START_CMD"/n)
    ${runtime_exe} run --detach \
      --name "${container_name}" \
      --publish "${container_port}:80" \
      --log-driver journald \
      --device /dev/fuse \
      --volume "${container_root}/settings:/etc/pulp${selinux_suffix}" \
      --volume "${container_root}/pulp_storage:/var/lib/pulp${selinux_suffix}" \
      --volume "${container_root}/pgsql:/var/lib/pgsql${selinux_suffix}" \
      --volume "${container_root}/containers:/var/lib/containers${selinux_suffix}" \
      --volume "${container_root}/run:/run${selinux_suffix}" \
      "${container_image}"
    | START_CMD

  $command_result = run_command($start_cmd, $host)
  debug::break()
  return $command_result
}
