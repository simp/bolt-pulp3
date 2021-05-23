# Not sure why this file is necessary with the resource api transport, but `puppet device` yells if it's missing so here's a shim:
require 'puppet/resource_api/transport/wrapper'
require 'puppet/transport/schema/pulp3_api'

module Puppet::Util::NetworkDevice::Pulp3_api
  class Device < Puppet::ResourceApi::Transport::Wrapper
    def initialize(url_or_config, _options = {})
      super('pulp3_api', url_or_config)
    end
  end
end
