# typed: true
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
      raise Exceptions::MissingCredentialsError if host.nil? || api_key.nil?

      @host    = host
      @api_key = api_key
      @client = new_client
    end

    # Instanciates an object from a hash. Can be overriden by child classes
    #
    # @param [String] path                the path of the request
    # @param [Symbol|String] http_method  the http method of the request
    # @param [Hash] body                  the body of the request
    # @param [Hash] options               options
    # @return [Hash]
    def request(path, http_method: :get, body: nil, headers: {}, options: {})
      response = request_with_client(http_method, path, body, headers,
                                     force_multipart: options.fetch(:force_multipart, false))

      return true if response.status == 204 # No content

      process_error(response) if response.status >= 400

      parse_response(response)
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

    def process_error(response)
      errors = {
        400 => Exceptions::BadRequestError,
        403 => Exceptions::AuthenticationError,
        409 => Exceptions::ConflictError,
        500 => Exceptions::InternalServerError
      }

      error_class = errors[response.status] || Exceptions::UnknownError

      raise(error_class, "[#{response.status}] " + parse_response(response).fetch(:error))
    end

    def parse_response(response)
      JSON
        .parse(response.body)
        .deep_transform_keys { |key| key.underscore.to_sym }
    end

    def request_with_client(http_method, path, body, headers, force_multipart: false)
      if force_multipart || body&.any? { |_key, value| value.is_a?(Faraday::UploadIO) }
        file_client = new_client(multipart: true)
        file_client.public_send(http_method, path, body, headers)
      else
        client.public_send(http_method, path, body&.to_json, headers)
      end
    end

    def new_client(multipart: false)
      Faraday.new(host) do |client|
        client.headers["Authorization"] = "Bearer #{api_key}" unless api_key.nil?
        client.headers["Content-Type"] = multipart ? "multipart/form-data" : "application/json"
        client.request :multipart if multipart
      end
    end
  end
end
