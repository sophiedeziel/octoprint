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
      # @param [Octoprint::Client] client      the API client to use
      # @return [BaseResource]
      def get(client: Octoprint.client)
        response = client.request(@path, http_method: :get)
        deserialize(response)
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
