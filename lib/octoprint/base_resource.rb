# typed: true
# frozen_string_literal: true

module Octoprint
  # Base class for all API resources.
  class BaseResource
    class << self
      # Defines the path for the resource's endpoint
      #
      # @param [String] path      The API's endpoint path
      def resource_path(path)
        @path = path
      end

      # Gets a single resource and instantiates the object.
      #
      # @return [BaseResource]
      def fetch_resource(path = nil, deserialize: true, options: {})
        path = [@path, path].compact.join("/")
        response = perform(ApiRequest.new(http_method: :get, path: path, query: options))
        return deserialize(response) if deserialize

        response
      end

      # Sends a POST request to the resource's endpoint.
      #
      # @param [String] path      the path of the post request
      # @param [Hash] params      parameters to the request
      # @param [Hash] options     options
      # @return [Object]
      #: (
      #|   ?path: String,
      #|   ?params: Hash[Symbol, untyped],
      #|   ?headers: Hash[Symbol, untyped],
      #|   ?options: Hash[Symbol, untyped]
      #| ) -> untyped
      def post(path: @path, params: {}, headers: {}, options: {})
        perform(ApiRequest.new(http_method: :post, path: path, body: params, headers: headers, options: options))
      end

      # Sends a PUT request to the resource's endpoint.
      #
      # @param [String] path      the path of the put request
      # @param [Hash] params      parameters to the request
      # @param [Hash] headers     headers to the request
      # @param [Hash] options     options
      # @return [Object]
      #: (
      #|   ?path: String,
      #|   ?params: Hash[Symbol, untyped],
      #|   ?headers: Hash[Symbol, untyped],
      #|   ?options: Hash[Symbol, untyped]
      #| ) -> untyped
      def put(path: @path, params: {}, headers: {}, options: {})
        perform(ApiRequest.new(http_method: :put, path: path, body: params, headers: headers, options: options))
      end

      # Sends a PATCH request to the resource's endpoint.
      #
      # @param [String] path      the path of the patch request
      # @param [Hash] params      parameters to the request
      # @param [Hash] headers     headers to the request
      # @param [Hash] options     options
      # @return [Object]
      #: (
      #|   ?path: String,
      #|   ?params: Hash[Symbol, untyped],
      #|   ?headers: Hash[Symbol, untyped],
      #|   ?options: Hash[Symbol, untyped]
      #| ) -> untyped
      def patch(path: @path, params: {}, headers: {}, options: {})
        perform(ApiRequest.new(http_method: :patch, path: path, body: params, headers: headers, options: options))
      end

      # Sends a DELETE request to the resource's endpoint.
      #
      # @param [String] path      the path of the delete request
      # @param [Hash] params      parameters to the request
      # @param [Hash] headers     headers to the request
      # @param [Hash] options     options
      # @return [Object]
      #: (
      #|   ?path: String,
      #|   ?params: Hash[Symbol, untyped],
      #|   ?headers: Hash[Symbol, untyped],
      #|   ?options: Hash[Symbol, untyped]
      #| ) -> untyped
      def delete(path: @path, params: {}, headers: {}, options: {})
        perform(ApiRequest.new(http_method: :delete, path: path, body: params.empty? ? nil : params,
                               headers: headers, options: options))
      end

      # Instantiates an object from a hash. Can be overridden by child classes
      #
      # @param [Hash] attrs      the object's attributes
      # @return [BaseResource]
      def deserialize(attrs)
        new(**attrs)
      end

      # The converter that turns this resource's 2.0-style requests and responses into 1.x ones, if it has one:
      # the `Legacy` constant nested in the resource (e.g. `Connection::Legacy`), never an inherited one.
      # See {LegacyConverter}.
      #
      # @return [LegacyConverter, nil]
      #: -> LegacyConverter?
      def legacy_converter
        return unless const_defined?(:Legacy, false)

        const_get(:Legacy, false)
      end

      private

      # Raises unless the configured client's API version has a feature. Call it before a request that only
      # exists in a newer API, so it fails without reaching the server.
      #
      #: (Symbol) -> void
      def require_feature!(feature)
        client.require_feature!(feature)
      end

      # Sends a request, through the resource's legacy converter when the client speaks the 1.x API.
      # The client is only asked for its API version when the resource has a converter.
      #
      #: (ApiRequest) -> untyped
      def perform(request)
        converter = legacy_converter
        converter = nil if converter && !client.legacy_api?
        sent = converter ? converter.to_request(request) : request

        response = send_request(sent)
        converter ? converter.from_response(response, request) : response
      end

      #: (ApiRequest) -> untyped
      def send_request(request)
        # GET keeps its historical call shape: no body, headers or options
        return client.request(request.full_path, http_method: :get) if request.http_method == :get

        client.request(
          request.full_path,
          http_method: request.http_method,
          body: request.body,
          headers: request.headers,
          options: request.options
        )
      end

      #: -> Client
      def client
        client = Octoprint.client
        raise "No client configured" unless client

        client
      end
    end

    def initialize(**attrs); end
  end
end
