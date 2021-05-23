require 'puppet/resource_api'

Puppet::ResourceApi.register_transport(
  name: 'pulp3_api',
  desc: 'Provides transport to the Pulp 3 REST API',

  connection_info: {
    uri: {
      type: 'String',
      desc: 'The URI of the Pulp server',
    },
    user:        {
      type: 'String',
      desc: 'The username to use for authenticating all connections to the Pulp API',
    },
    password:    {
      type:      'String',
      desc:      'The password to use for authenticating all connections to the Pulp API',
      sensitive: true,
    },
  },
)

