# typed: true
# frozen_string_literal: true

module Octoprint
  # Base class for all API resources.
  class BaseResource
    class << self
      extend T::Sig
      # Defines the path for the resource's enpoint
      #
      # @param [String] path      The API's endopoint path
      def resource_path(path)
        @path = path
      end

      # Gets a single resource and instanciates the object.
      #
      # @return [BaseResource]
      def fetch_resource(path = nil)
        path = [@path, path].compact.join("/")
        response = client.request(path, http_method: :get)
        deserialize(response)
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

      # Instanciates an object from a hash. Can be overriden by child classes
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
