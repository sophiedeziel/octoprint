# frozen_string_literal: true

require "faraday"
require "faraday/multipart"

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
        client.headers["Content-Type"] = "application/json"
      end
    end

    # Instanciates an object from a hash. Can be overriden by child classes
    #
    # @param [String] path                the path of the request
    # @param [Symbol|String] http_method  the http method of the request
    # @param [Hash] body                  the body of the request
    # @return [Hash]
    def request(path, http_method: :get, body: nil, headers: {})
      response = request_with_client(http_method, path, body, headers)

      return true if response.status == 204 # No content

      process_error(response.status) if response.status >= 400

      JSON
        .parse(response.body)
        .deep_transform_keys { |key| key.underscore.to_sym }
    end

    # Every request inside the block will be executed as this client without affecting the gem's initial configuration
    # @return [Client]
    def use
      config_client = Octoprint.client
      Octoprint.client = self
      yield
    ensure
      Octoprint.client = config_client
      self
    end

    private

    def process_error(code)
      errors = {
        400 => Exceptions::BadRequest,
        403 => Exceptions::AuthenticationError
      }

      raise errors[code]
    end

    def request_with_client(http_method, path, body, headers)
      if body&.any? { |_key, value| value.is_a?(Faraday::UploadIO) }
        file_client = Faraday.new(host) do |client|
          client.headers["Authorization"] = "Bearer #{api_key}" unless api_key.nil?
          client.request :multipart
        end
        file_client.public_send(http_method, path, body, headers)
      else
        client.public_send(http_method, path, body&.to_json, headers)
      end
    end
  end
end
