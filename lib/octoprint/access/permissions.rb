# typed: true
# frozen_string_literal: true

module Octoprint
  module Access
    # Provides access to the OctoPrint permissions API
    #
    # @see https://docs.octoprint.org/en/master/api/access.html#retrieve-a-list-of-permissions
    class Permissions < BaseResource
      extend T::Sig

      resource_path("/api/access/permissions")

      # Retrieve a list of permissions
      #
      # @example Get all permissions
      #   permissions = Octoprint::Access::Permissions.list
      #   permissions.each do |permission|
      #     puts "#{permission.key}: #{permission.name}"
      #   end
      #
      # @return [Array<Permission>] An array of Permission objects
      sig { returns(T::Array[Permission]) }
      def self.list
        response = fetch_resource(deserialize: false)
        permissions_data = response[:permissions] || response["permissions"] || []
        permissions_data.map { |permission_data| Permission.deserialize(permission_data) }
      end
    end
  end
end
