# typed: true
# frozen_string_literal: true

require "faraday"
require "faraday/multipart"

module Octoprint
  # The API client object.
  #
  # @example Configure a client with custom timeouts
  #   client = Octoprint::Client.new(host: "http://octopi.local", api_key: "key", open_timeout: 1, timeout: 5)
  #
  # @example Allow more time for large file uploads
  #   client = Octoprint::Client.new(host: "http://octopi.local", api_key: "key", timeout: 120)
  #
  # @attr [String] host
  # @attr [String] api_key
  # @attr [Numeric, nil] open_timeout  Seconds to wait for the connection to open. nil falls back to `timeout`
  # @attr [Numeric, nil] timeout       Seconds to wait for a read or a write. nil: adapter default (60s)
  # @attr [Client] client
  class Client
    extend T::Sig

    # Default number of seconds to wait for the connection to open
    DEFAULT_OPEN_TIMEOUT = 2
    # Default number of seconds to wait for a read or a write
    DEFAULT_TIMEOUT = 3

    attr_reader :host, :api_key, :open_timeout, :timeout, :client

    # @param host [String, URI]            Server's host address
    # @param api_key [String]              Server's API key
    # @param open_timeout [Numeric, nil]   Seconds to wait for the connection to open. nil falls back to `timeout`
    # @param timeout [Numeric, nil]        Seconds to wait for a read or a write. nil: adapter default (60s)
    # @raise [Exceptions::MissingCredentialsError] if host or api_key is missing
    sig do
      params(
        host: T.nilable(T.any(String, URI::Generic)),
        api_key: T.nilable(String),
        open_timeout: T.nilable(Numeric),
        timeout: T.nilable(Numeric)
      ).void
    end
    def initialize(host:, api_key:, open_timeout: DEFAULT_OPEN_TIMEOUT, timeout: DEFAULT_TIMEOUT)
      raise Exceptions::MissingCredentialsError if host.nil? || api_key.nil?

      @host         = host
      @api_key      = api_key
      @open_timeout = open_timeout
      @timeout      = timeout
      @client       = new_client
    end

    # Instantiates an object from a hash. Can be overridden by child classes
    #
    # @param [String] path                the path of the request
    # @param [Symbol|String] http_method  the http method of the request
    # @param [Hash] body                  the body of the request
    # @param [Hash] options               options
    # @return [Hash]
    # @raise [Exceptions::TimeoutError] if the server doesn't respond within the configured timeouts
    # @raise [Exceptions::ConnectionError] if the server can't be reached
    def request(path, options_or_http_method = nil, body: nil, headers: {}, options: {}, http_method: :get)
      # Handle both keyword arguments and hash format for backward compatibility
      if options_or_http_method.is_a?(Hash)
        # Called with a hash as second parameter (legacy format from tests)
        options_hash = options_or_http_method
        http_method = options_hash[:http_method] || http_method
        body = options_hash[:params] || options_hash[:body] || body
        headers = options_hash[:headers] || headers
        options = options_hash[:options] || options
      else
        # Called with keyword arguments (new format)
        http_method = options_or_http_method || http_method
      end

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
    end

    private

    def process_error(response)
      errors = {
        400 => Exceptions::BadRequestError,
        403 => Exceptions::AuthenticationError,
        404 => Exceptions::NotFoundError,
        409 => Exceptions::ConflictError,
        415 => Exceptions::UnsupportedMediaTypeError,
        500 => Exceptions::InternalServerError
      }

      error_class = errors[response.status] || Exceptions::UnknownError

      raise(error_class, "[#{response.status}] " + parse_response(response).fetch(:error))
    end

    def parse_response(response)
      parsed_json = JSON.parse(response.body)
      transform_keys_recursively(parsed_json)
    end

    def transform_keys_recursively(obj)
      case obj
      when Hash
        obj.deep_transform_keys { |key| key.underscore.to_sym }
      when Array
        obj.map { |item| transform_keys_recursively(item) }
      else
        obj
      end
    end

    def request_with_client(http_method, path, body, headers, force_multipart: false)
      if force_multipart || body&.any? { |_key, value| value.is_a?(Faraday::UploadIO) }
        file_client = new_client(multipart: true)
        file_client.public_send(http_method, path, body, headers)
      else
        client.public_send(http_method, path, body&.to_json, headers)
      end
    rescue Faraday::TimeoutError => e
      raise Exceptions::TimeoutError, e.message
    rescue Faraday::ConnectionFailed, Faraday::SSLError => e
      # Faraday reports open timeouts (Net::OpenTimeout) as connection failures
      error_class = e.wrapped_exception.is_a?(Timeout::Error) ? Exceptions::TimeoutError : Exceptions::ConnectionError
      raise error_class, e.message
    end

    def new_client(multipart: false)
      Faraday.new(host) do |client|
        client.headers["Authorization"] = "Bearer #{api_key}" unless api_key.nil?
        client.headers["Content-Type"] = multipart ? "multipart/form-data" : "application/json"
        client.request :multipart if multipart
        client.options.open_timeout = open_timeout
        client.options.timeout = timeout
      end
    end
  end
end
