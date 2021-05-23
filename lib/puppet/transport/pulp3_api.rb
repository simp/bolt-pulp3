require 'faraday'
require 'uri'
require 'json'

module Puppet::Transport
  # Enables connection to the Pulp3 API
  class Pulp3Api
    attr_reader :connection, :context

    def self.validate_connection_info(connection_info)
      raise Puppet::ResourceError, 'Could not find "user"/"password" in the configuration' unless (connection_info.key?(:user) && connection_info.key?(:password)) # rubocop:disable Metrics/LineLength
    end

    # @summary
    #   Initializes and returns a faraday connection to the given host
    def initialize(context, connection_info)
      self.class.validate_connection_info(connection_info)

      context.debug "Trying to connect to #{connection_info[:uri]} as user #{connection_info[:user]}"
      @connection = Faraday.new( "#{connection_info[:uri]}/pulp/api/v3") do |f|
        f.basic_auth(connection_info[:user], connection_info[:password].unwrap)
        # TODO find out why log_level :info still results in DEBUG messages
        f.response :logger , nil, { bodies: true, headers: false, log_level: :info}
        ###f.request :multipart
        ###f.request :url_encoded
        f.adapter :net_http
        f.request :retry
        #f.response :follow_redirects
        f.headers['Content-Type'] = 'application/json'
        ##f.request :follow_redirects
        ##f.response :json
      end

      @context = context
    end

    # @summary
    #   Return's set facts regarding the class
    def facts(_context)
      { 'operatingsystem' => 'pulp3_api' }
    end

    # @summary
    #   Request api details from the set host, autopaginating if necessary
    def get(url_path, connection, args = nil)
      context.debug "Trying to get #{url_path} "
      # Determine full URL path
      path = (connection.url_prefix.path + url_path).sub(%r[/?$],'/')
      results = []
      page = 1
      loop do
        get_result = connection.get(path, args)
        unless get_result.success?
          context.err("Could not GET Pulp API resources at (#{path})")
          raise Puppet::ResourceError, "Could not GET Pulp API resources at (#{path})"
        end

        result_data = JSON.parse(get_result.body)
        if result_data.key? 'results'
           results += result_data['results']
           context.debug("Successful GET Pulp API resources from (#{path}) (pagination: #{page}) ")
        else
           results = result_data
           context.debug("Successful GET Pulp API resources from (#{path})")
        end
        break unless result_data['next']
        page += 1
      rescue JSON::ParserError => e
        raise Puppet::ResourceError, "Unable to parse JSON response from HUE API: #{e}"
      end

      results
    end

    # @summary
    #   Send's an update command to the given url/connection
    def hue_put(url, connection, message)
      message = message.to_json
      connection.put(url, message)
    end

    def verify(_context)
      # Test that transport can talk to the remote target
      # This is a stub method as no such verify method exist and attempts
      #   to implement one indirectly would merely duplicate hue_get().
    end

    def close(_context)
      # Close connection, free up resources
      # This is a stub method as no close method exists in Faraday gem.
    end
  end
end


