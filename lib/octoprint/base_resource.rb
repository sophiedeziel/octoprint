# frozen_string_literal: true

module Octoprint
  # Base class for all API resources.
  class BaseResource
    class << self
      # Defines the path for the resource's enpoint
      #
      # @param [String] path      The API's endopoint path
      def resource_path(path)
        @path = path
      end

      # Gets a single resource and instanciates the object.
      #
      # @return [BaseResource]
      def fetch_resource
        response = Octoprint.client.request(@path, http_method: :get)
        deserialize(response)
      end

      # Sends a POST request to the resource's endpoint.
      #
      # @param [String] path      the path of the post request
      # @param [Hash] params      parameters to the request
      # @return [BaseResource]
      def post(path: @path, params: {})
        Octoprint.client.request(
          path,
          http_method: :post,
          body: params.to_json
        )
      end

      # Instanciates an object from a hash. Can be overriden by child classes
      #
      # @param [Hash] attrs      the object's attributes
      # @return [BaseResource]
      def deserialize(attrs)
        new(**attrs)
      end
    end
  end
end
