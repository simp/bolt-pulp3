require 'faraday'
require 'uri'
require 'json'

module Puppet::Transport
  # Enables connection to the Pulp3 API
  class Pulp3Api
    attr_reader :connection, :context

    # @summary
    #   Initializes and returns a faraday connection to the given host
    def initialize(context, connection_info)
      self.class.validate_connection_info(connection_info)

      context.debug "Trying to connect to #{connection_info[:uri]} as user #{connection_info[:user]}"
      @connection = Faraday.new( "#{connection_info[:uri]}/pulp/api/v3") do |f|
        f.basic_auth(connection_info[:user], connection_info[:password].unwrap)
        f.headers['Content-Type'] = 'application/json'
        f.request :multipart
        f.request :url_encoded

        # TODO tighten settings when we know more about likely retry situations
        f.request :retry, {
          max: 2,
          interval: 0.05,
          interval_randomness: 0.5,
          backoff_factor: 2
        }
        #f.response :follow_redirects  # AVOID: not default middleware
        #f.response :json              # AVOID: not default middleware

        # TODO find out why setting log_level :info still results in DEBUG messages
        f.response :logger, nil, {bodies: true, headers: false, log_level: :info}

        f.adapter :net_http
      end

      @context = context
    end

    def self.validate_connection_info(connection_info)
      raise Puppet::ResourceError, 'Could not find "user"/"password" in the configuration' unless (connection_info.key?(:user) && connection_info.key?(:password)) # rubocop:disable Metrics/LineLength
    end

    # @summary
    #  Access target, return a Facter facts hash
    def facts(_context)
      { 'operatingsystem' => 'pulp3_api' }
    end

    # @summary
    #   Request api details from the set host, autopaginating if necessary
    def pulp3_api_get(url_path, connection, args = nil)
      context.debug "Trying to GET #{url_path} "
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
    #   Sends POST command to the given url/connection
    def pulp3_api_post(url_path, connection, args)
      path = (connection.url_prefix.path + url_path).sub(%r[/?$],'/')
      args_w_defaults = {base_path: args[:name] }.merge(args)
      message = JSON.pretty_generate( args_w_defaults )
      context.debug "Trying to POST #{url_path}, message:\n#{message}"
      post_result = connection.post(path, message)
        unless post_result.success?
          context.err("Could not POST to Pulp API at #{url_path}: (#{post_result.status}) #{post_result.reason_phrase}")
   require 'pry'; binding.pry
          raise Puppet::ResourceError, "Could not POST Pulp API resources at (#{path})"
        end
      context.created(args[:name], "POST new resource successfully")
      nil
    end


    # @summary
    #   Sends an update command to the given url/connection
    def pulp3_api_put(path, connection, args)
      #path = (connection.url_prefix.path + url_path).sub(%r[/?$],'/')
      args_w_defaults = {base_path: args[:name] }.merge(args)
      message = JSON.pretty_generate( args_w_defaults )

      context.debug "Trying to PUT #{path}, message:\n#{message}"
      put_result = connection.put(path, message)
      unless put_result.success?
        context.err("Could not PUT to Pulp API at #{path}: (#{put_result.status}) #{put_result.reason_phrase}")
        raise Puppet::ResourceError, "Could not PUT Pulp API resources at (#{path})"
      end
      context.debug "Successfully PUT #{path}"
    end

    def close(_context)
      # Close connection, free up resources
      # This is a stub method as no close method exists in Faraday gem.
    end

    # @summary
    #   Test that transport can talk to the remote target
    def verify(_context)
      # Test that transport can talk to the remote target
      # This is a stub method as no such verify method exist and attempts
      #   to implement one indirectly would merely duplicate hue_get().
    end

  end
end


