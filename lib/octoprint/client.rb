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
  # @example Talk to servers that speak different API versions
  #   ender3 = Octoprint::Client.new(host: "http://ender3.local", api_key: "key")                    # 1.11 API
  #   mk4    = Octoprint::Client.new(host: "http://mk4.local", api_key: "key", api_version: "2.0")   # 2.0 API
  #   fleet  = Octoprint::Client.new(host: "http://any.local", api_key: "key", api_version: :auto)  # detected
  #
  #   mk4.use { Octoprint::Job.get }
  #   fleet.api_version     # => Gem::Version "2.0" against an OctoPrint 2.0 server (asks the server once)
  #   fleet.server_version  # => Gem::Version "2.0.0rc7"
  #
  # @attr [String] host
  # @attr [String] api_key
  # @attr [Numeric, nil] open_timeout  Seconds to wait for the connection to open. nil falls back to `timeout`
  # @attr [Numeric, nil] timeout       Seconds to wait for a read or a write. nil: adapter default (60s)
  # @attr [String, Symbol] requested_api_version  The `api_version:` the client was created with
  # @attr [Client] client
  class Client
    # Default number of seconds to wait for the connection to open
    DEFAULT_OPEN_TIMEOUT = 2
    # Default number of seconds to wait for a read or a write
    DEFAULT_TIMEOUT = 3

    attr_reader :host, :api_key, :open_timeout, :timeout, :requested_api_version, :client

    # @param host [String, URI]            Server's host address
    # @param api_key [String]              Server's API key
    # @param open_timeout [Numeric, nil]   Seconds to wait for the connection to open. nil falls back to `timeout`
    # @param timeout [Numeric, nil]        Seconds to wait for a read or a write. nil: adapter default (60s)
    # @param api_version [String, Symbol]  The OctoPrint API to speak: `"1.11"` (default), `"2.0"` (OctoPrint 2.0
    #                                      servers only) or `:auto` (asks the server once). See {ApiVersion}.
    # @raise [Exceptions::MissingCredentialsError] if host or api_key is missing
    # @raise [ArgumentError] if api_version isn't one of the accepted values
    #: (
    #|   host: (String | URI::Generic)?,
    #|   api_key: String?,
    #|   ?open_timeout: Numeric?,
    #|   ?timeout: Numeric?,
    #|   ?api_version: (String | Symbol)
    #| ) -> void
    def initialize(host:, api_key:, open_timeout: DEFAULT_OPEN_TIMEOUT, timeout: DEFAULT_TIMEOUT,
                   api_version: ApiVersion::DEFAULT)
      raise Exceptions::MissingCredentialsError if host.nil? || api_key.nil?

      @host                  = host
      @api_key               = api_key
      @open_timeout          = open_timeout
      @timeout               = timeout
      @requested_api_version = validate_api_version(api_version)
      @server_version        = nil #: Gem::Version?
      @version_mutex         = Mutex.new
      @client                = new_client
    end

    # The API version the client speaks.
    #
    # With `api_version: :auto`, the first call asks the server for its version (`GET /api/version`, once per
    # client) and picks the latest API both sides support. A failed detection isn't remembered: the next call
    # tries again.
    #
    # @return [Gem::Version] {ApiVersion::V1_11} or {ApiVersion::V2_0}
    # @raise [Exceptions::ConnectionError] if `:auto` can't reach the server
    #: -> Gem::Version
    def api_version
      requested = requested_api_version
      return ApiVersion::REQUESTABLE.fetch(requested.to_s) unless requested == ApiVersion::AUTO

      ApiVersion.for_server(detect_server_version)
    end

    # The server's version, once `api_version: :auto` has detected it.
    #
    # @return [Gem::Version, nil] nil until detected, and always nil for a client with a pinned `api_version:`
    #: -> Gem::Version?
    def server_version
      @version_mutex.synchronize { @server_version }
    end

    # Forgets the detected server version, so an `api_version: :auto` client asks again on its next request.
    # Use it after the server was upgraded.
    #
    # @return [nil]
    #: -> void
    def refresh_version!
      @version_mutex.synchronize { @server_version = nil }

      nil
    end

    # Whether the client's API version answers with the 1.x response shapes
    #
    # @return [Boolean]
    #: -> bool
    def legacy_api?
      ApiVersion.legacy?(api_version)
    end

    # Whether the client's API version has a feature.
    #
    # @example
    #   client.supports?(:connectors) # => false with the 1.11 API
    #
    # @param feature [Symbol] A key of {ApiVersion::FEATURES}
    # @return [Boolean]
    # @raise [ArgumentError] for an unknown feature
    #: (Symbol) -> bool
    def supports?(feature)
      api_version >= ApiVersion.required_for(feature)
    end

    # Raises unless the client's API version has a feature.
    #
    # @param feature [Symbol] A key of {ApiVersion::FEATURES}
    # @return [void]
    # @raise [Exceptions::UnsupportedFeatureError] if the client's API version doesn't have the feature
    # @raise [ArgumentError] for an unknown feature
    #: (Symbol) -> void
    def require_feature!(feature)
      return if supports?(feature)

      raise Exceptions::UnsupportedFeatureError,
            "#{feature} needs the OctoPrint #{ApiVersion.required_for(feature)} API, " \
            "but this client uses the #{api_version} API#{server_version_suffix}"
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

    #: ((String | Symbol)) -> (String | Symbol)
    def validate_api_version(api_version)
      return api_version if api_version == ApiVersion::AUTO || ApiVersion::REQUESTABLE.key?(api_version)

      accepted = [*ApiVersion::REQUESTABLE.keys, ApiVersion::AUTO].map(&:inspect).join(", ")
      raise ArgumentError, "Unknown api_version #{api_version.inspect}. Use one of #{accepted}"
    end

    # Asks the server for its version once. Never remembers a failure.
    #
    #: -> Gem::Version
    def detect_server_version
      @version_mutex.synchronize do
        detected = @server_version
        next detected if detected

        # Without the version header: every OctoPrint version answers this one
        response = send_raw(:get, "/api/version", nil, {})
        process_error(response) if response.status >= 400
        @server_version = ApiVersion.parse(parse_response(response).fetch(:server))
      end
    end

    #: -> String
    def server_version_suffix
      version = server_version
      version ? " (OctoPrint #{version})" : ""
    end

    # Headers that select the API version, empty for the 1.x API
    #
    #: -> Hash[String, String]
    def api_version_headers
      value = ApiVersion.header_value(api_version)
      value ? { ApiVersion::HEADER => value } : {}
    end

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
      send_raw(http_method, path, body, api_version_headers.merge(headers || {}), force_multipart: force_multipart)
    end

    def send_raw(http_method, path, body, headers, force_multipart: false)
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
