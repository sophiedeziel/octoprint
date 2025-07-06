# typed: true
# frozen_string_literal: true

module Octoprint
  module Resources
    module Access
      # Represents a group in the OctoPrint access control system
      #
      # @example
      #   group = Octoprint::Resources::Access::Group.new(
      #     key: "operators",
      #     name: "Operators",
      #     description: "Can operate the printer",
      #     permissions: ["CONTROL", "MONITOR"],
      #     subgroups: [],
      #     needs_role: [],
      #     default: false,
      #     removable: true,
      #     changeable: true,
      #     toggleable: false
      #   )
      class Group
        extend T::Sig
        include AutoInitializable
        include Deserializable

        # @!attribute [r] key
        #   @return [String] The group key/identifier
        auto_attr :key, type: String

        # @!attribute [r] name
        #   @return [String] The human-readable name
        auto_attr :name, type: String

        # @!attribute [r] description
        #   @return [String] Description of the group
        auto_attr :description, type: String

        # @!attribute [r] permissions
        #   @return [Array<String>] Permissions assigned to this group
        auto_attr :permissions, type: String, array: true

        # @!attribute [r] subgroups
        #   @return [Array<String>] Subgroups included in this group
        auto_attr :subgroups, type: String, array: true

        # @!attribute [r] needs_role
        #   @return [Array<String>] Roles needed for this group
        auto_attr :needs_role, type: String, array: true

        # @!attribute [r] default
        #   @return [Boolean] Whether this is a default group
        auto_attr :default, type: Types::Boolean

        # @!attribute [r] removable
        #   @return [Boolean] Whether this group can be removed
        auto_attr :removable, type: Types::Boolean

        # @!attribute [r] changeable
        #   @return [Boolean] Whether this group can be changed
        auto_attr :changeable, type: Types::Boolean

        # @!attribute [r] toggleable
        #   @return [Boolean] Whether this group can be toggled
        auto_attr :toggleable, type: Types::Boolean

        # @!attribute [r] extra
        #   @return [Hash] Additional attributes from the API
        auto_attr :extra, type: Hash

        auto_initialize!

        deserialize_config do
          rename needsRole: :needs_role
        end
      end
    end
  end
end
