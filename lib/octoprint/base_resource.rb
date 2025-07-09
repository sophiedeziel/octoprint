# typed: true
# frozen_string_literal: true

module Octoprint
  # Base class for all API resources.
  class BaseResource
    class << self
      extend T::Sig
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
        path += "?#{Faraday::Utils.build_query(options)}" if options.any?
        response = client.request(path, http_method: :get)
        return deserialize(response) if deserialize

        response
      end

      # Sends a POST request to the resource's endpoint.
      #
      # @param [String] path      the path of the post request
      # @param [Hash] params      parameters to the request
      # @param [Hash] options     options
      # @return [Object]
      sig do
        params(
          path: String,
          params: T::Hash[Symbol, T.untyped],
          headers: T::Hash[Symbol, T.untyped],
          options: T::Hash[Symbol, T.untyped]
        )
          .returns(T.untyped)
      end
      def post(path: @path, params: {}, headers: {}, options: {})
        client.request(
          path,
          http_method: :post,
          body: params,
          headers: headers,
          options: options
        )
      end

      # Sends a PUT request to the resource's endpoint.
      #
      # @param [String] path      the path of the put request
      # @param [Hash] params      parameters to the request
      # @param [Hash] headers     headers to the request
      # @param [Hash] options     options
      # @return [Object]
      sig do
        params(
          path: String,
          params: T::Hash[Symbol, T.untyped],
          headers: T::Hash[Symbol, T.untyped],
          options: T::Hash[Symbol, T.untyped]
        )
          .returns(T.untyped)
      end
      def put(path: @path, params: {}, headers: {}, options: {})
        client.request(
          path,
          http_method: :put,
          body: params,
          headers: headers,
          options: options
        )
      end

      # Sends a PATCH request to the resource's endpoint.
      #
      # @param [String] path      the path of the patch request
      # @param [Hash] params      parameters to the request
      # @param [Hash] headers     headers to the request
      # @param [Hash] options     options
      # @return [Object]
      sig do
        params(
          path: String,
          params: T::Hash[Symbol, T.untyped],
          headers: T::Hash[Symbol, T.untyped],
          options: T::Hash[Symbol, T.untyped]
        )
          .returns(T.untyped)
      end
      def patch(path: @path, params: {}, headers: {}, options: {})
        client.request(
          path,
          http_method: :patch,
          body: params,
          headers: headers,
          options: options
        )
      end

      # Sends a DELETE request to the resource's endpoint.
      #
      # @param [String] path      the path of the delete request
      # @param [Hash] params      parameters to the request
      # @param [Hash] headers     headers to the request
      # @param [Hash] options     options
      # @return [Object]
      sig do
        params(
          path: String,
          params: T::Hash[Symbol, T.untyped],
          headers: T::Hash[Symbol, T.untyped],
          options: T::Hash[Symbol, T.untyped]
        )
          .returns(T.untyped)
      end
      def delete(path: @path, params: {}, headers: {}, options: {})
        client.request(
          path,
          http_method: :delete,
          body: params.empty? ? nil : params,
          headers: headers,
          options: options
        )
      end

      # Instantiates an object from a hash. Can be overridden by child classes
      #
      # @param [Hash] attrs      the object's attributes
      # @return [BaseResource]
      def deserialize(attrs)
        new(**attrs)
      end

      private

      sig do
        returns(Client)
      end
      def client
        client = Octoprint.client
        raise "No client configured" unless client

        client
      end
    end

    def initialize(**attrs); end
  end
end
