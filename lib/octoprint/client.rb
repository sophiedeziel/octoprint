# frozen_string_literal: true

require "faraday"

module Octoprint
  # The API client object.
  #
  # @attr [String] host
  # @attr [String] api_key
  # @attr [Client] client
  class Client
    attr_reader :host, :api_key, :client

    def initialize(host:, api_key:)
      raise Exceptions::MissingCredentials if host.nil? || api_key.nil?

      @host    = host
      @api_key = api_key
      @client = Faraday.new(host) do |client|
        client.headers["Authorization"] = "Bearer #{api_key}" unless api_key.nil?
      end
    end

    # Instanciates an object from a hash. Can be overriden by child classes
    #
    # @param [String] path                the path of the request
    # @param [Symbol|String] http_method  the http method of the request
    # @param [Hash] body                  the body of the request
    # @return [Hash]
    def request(path, http_method: :get, body: {})
      response = client.public_send(http_method, path, **body)

      raise Exceptions::AuthenticationError if response.status == 403

      JSON
        .parse(response.body)
        .deep_transform_keys { |key| key.underscore.to_sym }
    end
  end
end
