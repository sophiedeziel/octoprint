# typed: true
# frozen_string_literal: true

module Octoprint
  module Resources
    module Access
      # Provides access to the OctoPrint groups API
      #
      # @see https://docs.octoprint.org/en/master/api/access.html#groups
      class Groups < BaseResource
        extend T::Sig

        resource_path("/api/access/groups")

        # Retrieve a list of groups
        #
        # Requires the SETTINGS permission.
        #
        # @example Get all groups
        #   groups = Octoprint::Resources::Access::Groups.list
        #   groups.each do |group|
        #     puts "#{group.key}: #{group.name}"
        #   end
        #
        # @return [Array<Group>] An array of Group objects
        sig { returns(T::Array[Group]) }
        def self.list
          response = fetch_resource(deserialize: false)
          response.map { |group_data| Group.deserialize(group_data) }
        end

        # Add a new group
        #
        # Requires the SETTINGS permission and a recent credentials check.
        #
        # @example Create a new group
        #   group = Octoprint::Resources::Access::Groups.add(
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
        # @return [Group] The created group
        sig do
          params(
            key: String,
            name: String,
            description: String,
            permissions: T::Array[String],
            subgroups: T::Array[String],
            default: T::Boolean
          ).returns(Group)
        end
        def self.add(key:, name:, description:, permissions:, subgroups:, default:)
          response = post(params: {
                            key: key,
                            name: name,
                            description: description,
                            permissions: permissions,
                            subgroups: subgroups,
                            default: default
                          })
          Group.deserialize(response)
        end

        # Retrieve a specific group
        #
        # Requires the SETTINGS permission.
        #
        # @example Get a specific group
        #   group = Octoprint::Resources::Access::Groups.get(key: "operators")
        #
        # @param key [String] The group's identifier
        # @return [Group] The requested group
        sig { params(key: String).returns(Group) }
        def self.get(key:)
          response = fetch_resource(key, deserialize: false)
          Group.deserialize(response)
        end

        # Update an existing group
        #
        # Requires the SETTINGS permission and a recent credentials check.
        #
        # @example Update a group
        #   group = Octoprint::Resources::Access::Groups.update(
        #     key: "operators",
        #     params: {
        #       description: "Updated description",
        #       permissions: ["CONTROL", "MONITOR", "FILES_LIST"]
        #     }
        #   )
        #
        # @param key [String] The group's identifier
        # @param params [Hash] The attributes to update
        # @return [Group] The updated group
        sig { params(key: String, params: T::Hash[Symbol, T.untyped]).returns(Group) }
        def self.update(key:, params:)
          path = [@path, key].join("/")
          response = put(path: path, params: params)
          Group.deserialize(response)
        end

        # Delete a group
        #
        # Requires the SETTINGS permission and a recent credentials check.
        #
        # @example Delete a group
        #   Octoprint::Resources::Access::Groups.delete(key: "operators")
        #
        # @param key [String] The group's identifier
        # @return [void]
        sig { params(key: String).void }
        def self.delete(key:)
          path = [@path, key].join("/")
          super(path: path)
          nil
        end
      end
    end
  end
end
