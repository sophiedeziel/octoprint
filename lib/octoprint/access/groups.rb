# typed: true
# frozen_string_literal: true

module Octoprint
  module Access
    # Provides access to the OctoPrint groups API
    #
    # @see https://docs.octoprint.org/en/master/api/access.html#groups
    class Groups < BaseResource
      resource_path("/api/access/groups")

      # Retrieve a list of groups
      #
      # Requires the SETTINGS permission.
      #
      # @example Get all groups
      #   groups = Octoprint::Access::Groups.list
      #   groups.each do |group|
      #     puts "#{group.key}: #{group.name}"
      #   end
      #
      # @return [Array<Group>] An array of Group objects
      #: -> Array[Group]
      def self.list
        response = fetch_resource(deserialize: false)
        groups_data = response[:groups] || response["groups"] || []
        groups_data.map { |group_data| Group.deserialize(group_data) }
      end

      # Add a new group
      #
      # Requires the SETTINGS permission and a recent credentials check.
      #
      # @example Create a new group
      #   group = Octoprint::Access::Groups.add(
      #     key: "operators",
      #     name: "Operators",
      #     description: "Can operate the printer",
      #     permissions: ["CONTROL", "MONITOR"],
      #     subgroups: [],
      #     default: false
      #   )
      #
      # @param key [String] The group's identifier
      # @param name [String] The group's human-readable name
      # @param description [String] Description of the group
      # @param permissions [Array<String>] Permissions to assign
      # @param subgroups [Array<String>] Subgroups to include
      # @param default [Boolean] Whether this is a default group
      # @return [Array<Group>] The created groups
      #: (
      #|   key: String,
      #|   name: String,
      #|   description: String,
      #|   permissions: Array[String],
      #|   subgroups: Array[String],
      #|   default: bool
      #| ) -> Array[Group]
      def self.add(key:, name:, description:, permissions:, subgroups:, default:)
        response = client.request(
          @path,
          http_method: :post,
          body: {
            key: key,
            name: name,
            description: description,
            permissions: permissions,
            subgroups: subgroups,
            default: default
          },
          headers: {},
          options: {}
        )
        groups_data = response[:groups] || response["groups"] || []
        groups_data.map { |group_data| Group.deserialize(group_data) }
      end

      # Retrieve a specific group
      #
      # Requires the SETTINGS permission.
      #
      # @example Get a specific group
      #   group = Octoprint::Access::Groups.get(key: "operators")
      #
      # @param key [String] The group's identifier
      # @return [Group] The requested group
      #: (key: String) -> Group
      def self.get(key:)
        response = fetch_resource(key, deserialize: false)
        Group.deserialize(response)
      end

      # Update an existing group
      #
      # Requires the SETTINGS permission and a recent credentials check.
      #
      # @example Update a group
      #   group = Octoprint::Access::Groups.update(
      #     key: "operators",
      #     params: {
      #       description: "Updated description",
      #       permissions: ["CONTROL", "MONITOR", "FILES_LIST"]
      #     }
      #   )
      #
      # @param key [String] The group's identifier
      # @param params [Hash] The attributes to update
      # @return [Array<Group>] The created groups
      #: (key: String, params: Hash[Symbol, untyped]) -> Array[Group]
      def self.update(key:, params:)
        path = [@path, key].join("/")
        response = client.request(
          path,
          http_method: :put,
          body: params,
          headers: {},
          options: {}
        )

        groups_data = response[:groups] || response["groups"] || []
        groups_data.map { |group_data| Group.deserialize(group_data) }
      end

      # Delete a group
      #
      # Requires the SETTINGS permission and a recent credentials check.
      #
      # @example Delete a group
      #   Octoprint::Access::Groups.delete(key: "operators")
      #
      # @param key [String] The group's identifier
      # @return [void]
      #: (
      #|   ?key: String?,
      #|   ?path: String,
      #|   ?params: Hash[Symbol, untyped],
      #|   ?headers: Hash[Symbol, untyped],
      #|   ?options: Hash[Symbol, untyped]
      #| ) -> untyped
      def self.delete(key: nil, path: @path, params: {}, headers: {}, options: {})
        if key
          # Group deletion case - ignore path parameter and construct our own
          group_path = [@path, key].join("/")
          delete_resource(group_path)
          nil
        else
          # Fall back to base behavior
          super(path: path, params: params, headers: headers, options: options)
        end
      end

      # Delete a resource at the given path
      #: (String path) -> void
      def self.delete_resource(path)
        client.request(
          path,
          http_method: :delete,
          body: nil,
          headers: {},
          options: {}
        )
        nil
      end
    end
  end
end
