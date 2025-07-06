# typed: true
# frozen_string_literal: true

module Octoprint
  module Resources
    module Access
      # Represents a permission in the OctoPrint access control system
      #
      # @example
      #   permission = Octoprint::Resources::Access::Permission.new(
      #     key: "SETTINGS",
      #     name: "Settings",
      #     dangerous: false,
      #     default_groups: ["admins", "operators"],
      #     description: "Allows access to settings",
      #     needs: ["CONNECTION"]
      #   )
      class Permission
        extend T::Sig
        include AutoInitializable
        include Deserializable

        # @!attribute [r] key
        #   @return [String] The permission key
        auto_attr :key, type: String

        # @!attribute [r] name
        #   @return [String] The human-readable name
        auto_attr :name, type: String

        # @!attribute [r] dangerous
        #   @return [Boolean] Whether this permission is dangerous
        auto_attr :dangerous, type: Types::Boolean

        # @!attribute [r] default_groups
        #   @return [Array<String>] Groups that have this permission by default
        auto_attr :default_groups, type: String, array: true

        # @!attribute [r] description
        #   @return [String, nil] Description of the permission
        auto_attr :description, type: String, nilable: true

        # @!attribute [r] needs
        #   @return [Array<String>] Permissions this one depends on
        auto_attr :needs, type: String, array: true

        # @!attribute [r] extra
        #   @return [Hash] Additional attributes from the API
        auto_attr :extra, type: Hash

        auto_initialize!

        deserialize_config do
          rename defaultGroups: :default_groups
        end
      end
    end
  end
end
