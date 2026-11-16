# typed: true
# frozen_string_literal: true

module Octoprint
  module Access
    # Represents a user in the OctoPrint access control system
    #
    # The model follows the OctoPrint 2.0 shape. OctoPrint 2.0 dropped the `admin`, `user` and `roles` keys
    # from user records (even without the `X-OctoPrint-Api-Version` header) and added `has_password`.
    # The dropped attributes are `nil` on 2.0: use {#admin?} and {#groups} instead.
    #
    # @example
    #   user = Octoprint::Access::User.new(
    #     name: "john_doe",
    #     active: true,
    #     has_password: true,
    #     api_key: "ABC123",
    #     settings: {},
    #     groups: ["operators"],
    #     permissions: ["CONTROL", "MONITOR"],
    #     needs_role: []
    #   )
    class User
      include AutoInitializable
      include Deserializable

      # @!attribute [r] name
      #   @return [String] The user's login name
      auto_attr :name, type: String

      # @!attribute [r] active
      #   @return [Boolean] Whether the user is active
      auto_attr :active, type: Types::Boolean

      # @!attribute [r] admin
      #   @deprecated Removed in OctoPrint 2.0, where it is always `nil`. Use {#admin?} instead.
      #   @return [Boolean, nil] Whether the user is an admin. `nil` on OctoPrint 2.0
      auto_attr :admin, type: Types::Boolean

      # @!attribute [r] has_password
      #   @return [Boolean, nil] Whether the user has a password set. New in OctoPrint 2.0, `nil` on 1.11
      auto_attr :has_password, type: Types::Boolean

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
      #   @deprecated Removed in OctoPrint 2.0, where it is always `nil`. Use {#needs_role} or {#groups} instead.
      #   @return [Array<String>, nil] User roles. `nil` on OctoPrint 2.0
      auto_attr :roles, type: String, array: true

      # @!attribute [r] user
      #   @deprecated Removed in OctoPrint 2.0, where it is always `nil`. Use {#groups} instead.
      #   @return [Boolean, nil] Whether the user is in the users group. `nil` on OctoPrint 2.0
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

      # Key of OctoPrint's built-in admin group
      ADMIN_GROUP = "admins"
      # Key of the ADMIN permission, as listed in {#permissions}
      ADMIN_PERMISSION = "ADMIN"
      # Role of the ADMIN permission, as listed in {#needs_role}
      ADMIN_ROLE = "admin"

      # Whether the user is an admin, on OctoPrint 1.11 and 2.0.
      #
      # Replaces the `admin` flag that OctoPrint 2.0 removed. A user is an admin when it is in the
      # `admins` group or has the ADMIN permission: {Users.current} lists it in {#permissions}, while
      # {Users.list}, {Users.get} and {Users.login} list it in {#needs_role} (which includes the
      # permissions of every group of the user).
      #
      # @example
      #   Octoprint::Access::Users.get(username: "john_doe").admin? # => false
      #   Octoprint::Access::Users.current.admin?                   # => true
      #
      # @return [Boolean]
      #: -> bool
      def admin?
        Array(groups).include?(ADMIN_GROUP) ||
          Array(permissions).include?(ADMIN_PERMISSION) ||
          Array(needs_role).include?(ADMIN_ROLE)
      end

      # Convenient class method to get current user (delegates to Users.current)
      #
      # @example Get current user
      #   user = Octoprint::Access::User.current
      #   puts "Current user: #{user.name}"
      #
      # @return [User] The current user object
      #: -> User
      def self.current
        Users.current
      end
    end
  end
end
