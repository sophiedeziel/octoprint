# typed: true
# frozen_string_literal: true

module Octoprint
  module Resources
    module Access
      # Represents a user in the OctoPrint access control system
      #
      # @example
      #   user = Octoprint::Resources::Access::User.new(
      #     name: "john_doe",
      #     active: true,
      #     admin: false,
      #     api_key: "ABC123",
      #     settings: {},
      #     groups: ["operators"],
      #     permissions: ["CONTROL", "MONITOR"],
      #     needs_role: []
      #   )
      class User
        extend T::Sig
        include AutoInitializable
        include Deserializable

        # @!attribute [r] name
        #   @return [String] The user's login name
        auto_attr :name, type: String

        # @!attribute [r] active
        #   @return [Boolean] Whether the user is active
        auto_attr :active, type: Types::Boolean

        # @!attribute [r] admin
        #   @return [Boolean] Whether the user is an admin (deprecated, use groups)
        auto_attr :admin, type: Types::Boolean

        # @!attribute [r] api_key
        #   @return [String, nil] The user's API key (only in list requests)
        auto_attr :api_key, type: String, nilable: true

        # @!attribute [r] settings
        #   @return [Hash] The user's settings
        auto_attr :settings, type: Hash

        # @!attribute [r] groups
        #   @return [Array<String>] Groups the user belongs to
        auto_attr :groups, type: String, array: true

        # @!attribute [r] permissions
        #   @return [Array<String>] Effective permissions for the user
        auto_attr :permissions, type: String, array: true

        # @!attribute [r] needs_role
        #   @return [Array<String>] Roles needed by the user
        auto_attr :needs_role, type: String, array: true

        # @!attribute [r] extra
        #   @return [Hash] Additional attributes from the API
        auto_attr :extra, type: Hash

        auto_initialize!

        deserialize_config do
          rename apikey: :api_key
          rename needsRole: :needs_role
        end
      end
    end
  end
end
