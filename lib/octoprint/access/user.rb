# typed: true
# frozen_string_literal: true

module Octoprint
  module Access
    # Represents a user in the OctoPrint access control system
    #
    # @example
    #   user = Octoprint::Access::User.new(
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

      # @!attribute [r] needs
      #   @return [Hash] Needs information with groups and roles
      auto_attr :needs, type: Hash

      # @!attribute [r] roles
      #   @return [Array<String>] User roles
      auto_attr :roles, type: String, array: true

      # @!attribute [r] user
      #   @return [Boolean, nil] Whether this is a user (vs admin)
      auto_attr :user, type: Types::Boolean, nilable: true

      # @!attribute [r] extra
      #   @return [Hash] Additional attributes from the API
      auto_attr :extra, type: Hash

      auto_initialize!

      deserialize_config do
        rename apikey: :api_key
        rename needsRole: :needs_role
        transform do |data|
          # Handle the needs structure which comes as a hash with group and role arrays
          data[:needs_role] = data[:needs][:role] if data[:needs].is_a?(Hash) && data[:needs][:role]
        end
      end

      # Convenient class method to get current user (delegates to Users.current)
      #
      # @example Get current user
      #   user = Octoprint::Access::User.current
      #   puts "Current user: #{user.name}"
      #
      # @return [User] The current user object
      sig { returns(User) }
      def self.current
        Users.current
      end
    end
  end
end
