# typed: true
# frozen_string_literal: true

module Octoprint
  module Access
    # Provides access to the OctoPrint users API
    #
    # @see https://docs.octoprint.org/en/master/api/access.html#users
    class Users < BaseResource
      extend T::Sig

      resource_path("/api/access/users")

      # Retrieve a list of users
      #
      # Requires the SETTINGS permission.
      #
      # @example Get all users
      #   users = Octoprint::Access::Users.list
      #   users.each do |user|
      #     puts "#{user.name} - Active: #{user.active}"
      #   end
      #
      # @return [Array<User>] An array of User objects
      sig { returns(T::Array[User]) }
      def self.list
        response = fetch_resource(deserialize: false)
        users_data = response[:users] || response["users"] || []
        users_data.map { |user_data| User.deserialize(user_data) }
      end

      # Add a new user
      #
      # Requires the SETTINGS permission and a recent credentials check.
      #
      # @example Create a new user
      #   user = Octoprint::Access::Users.add(
      #     name: "john_doe",
      #     password: "secure_password",
      #     active: true,
      #     admin: false
      #   )
      #
      # @param name [String] The user's login name
      # @param password [String] The user's password
      # @param active [Boolean] Whether the user should be active
      # @param admin [Boolean] Whether the user should be an admin (deprecated)
      # @param groups [Array<String>, nil] Groups to assign the user to
      # @param permissions [Array<String>, nil] Additional permissions
      # @return [Array<User>] An array of User objects
      sig do
        params(
          name: String,
          password: String,
          active: T::Boolean,
          admin: T::Boolean,
          groups: T.nilable(T::Array[String]),
          permissions: T.nilable(T::Array[String])
        ).returns(T::Array[User])
      end
      def self.add(name:, password:, active:, admin:, groups: nil, permissions: nil)
        params = {
          name: name,
          password: password,
          active: active,
          admin: admin
        }
        params[:groups] = groups if groups
        params[:permissions] = permissions if permissions

        response = post_with_hash_format(params: params)
        users_data = response[:users] || response["users"] || []
        users_data.map { |user_data| User.deserialize(user_data) }
      end

      # Retrieve a specific user
      #
      # Requires the SETTINGS permission.
      #
      # @example Get a specific user
      #   user = Octoprint::Access::Users.get(username: "john_doe")
      #
      # @param username [String] The user's login name
      # @return [User] The requested user
      sig { params(username: String).returns(User) }
      def self.get(username:)
        response = fetch_resource(username, deserialize: false)
        User.deserialize(response)
      end

      # Update an existing user
      #
      # Requires the SETTINGS permission and a recent credentials check.
      #
      # @example Update a user
      #   user = Octoprint::Access::Users.update(
      #     username: "john_doe",
      #     params: {
      #       active: false,
      #       groups: ["operators", "users"]
      #     }
      #   )
      #
      # @param username [String] The user's login name
      # @param params [Hash] The attributes to update
      # @return [Array<User>] The list of users
      sig { params(username: String, params: T::Hash[Symbol, T.untyped]).returns(T::Array[User]) }
      def self.update(username:, params:)
        path = [@path, username].join("/")
        response = put_with_hash_format(path: path, params: params)

        users_data = response[:users] || response["users"] || []
        users_data.map { |user_data| User.deserialize(user_data) }
      end

      # Delete a user
      #
      # Requires the SETTINGS permission and a recent credentials check.
      #
      # @example Delete a user
      #   Octoprint::Access::Users.delete(username: "john_doe")
      #
      # @param username [String] The user's login name
      # @return [void]
      sig do
        params(
          username: T.nilable(String),
          path: T.nilable(String),
          params: T.nilable(T::Hash[Symbol, T.untyped]),
          headers: T.nilable(T::Hash[Symbol, T.untyped]),
          options: T.nilable(T::Hash[Symbol, T.untyped])
        ).returns(T.untyped)
      end
      def self.delete(username: nil, path: nil, params: nil, headers: nil, options: nil)
        if username
          # User deletion case
          user_path = [@path, username].join("/")
          delete_resource(user_path)
          nil
        else
          # Base case - call parent implementation
          super(path: T.must(path), params: params || {}, headers: headers || {}, options: options || {})
        end
      end

      # Delete a resource at the given path
      sig { params(path: String).void }
      def self.delete_resource(path)
        client.request(
          path,
          {
            http_method: :delete
          }
        )
        nil
      end

      # Change a user's password
      #
      # Requires appropriate permissions based on whether changing own or other's password.
      #
      # @example Change a user's password
      #   Octoprint::Access::Users.change_password(
      #     username: "john_doe",
      #     password: "new_secure_password"
      #   )
      #
      # @param username [String] The user's login name
      # @param password [String] The new password
      # @return [void]
      sig { params(username: String, password: String).returns(T.untyped) }
      def self.change_password(username:, password:)
        path = [@path, username, "password"].join("/")
        post_with_hash_format(path: path, params: { password: password })
        nil
      end

      # Get a user's settings
      #
      # @example Get user settings
      #   settings = Octoprint::Access::Users.get_settings(username: "john_doe")
      #
      # @param username [String] The user's login name
      # @return [Hash] The user's settings
      sig { params(username: String).returns(T::Hash[Symbol, T.untyped]) }
      def self.get_settings(username:)
        path = [username, "settings"].join("/")
        fetch_resource(path, deserialize: false)
      end

      # Update a user's settings
      #
      # @example Update user settings
      #   settings = Octoprint::Access::Users.update_settings(
      #     username: "john_doe",
      #     settings: { interface: { color: "dark" } }
      #   )
      #
      # @param username [String] The user's login name
      # @param settings [Hash] The settings to update
      # @return [Hash] The updated settings
      sig { params(username: String, settings: T::Hash[Symbol, T.untyped]).returns(T::Hash[Symbol, T.untyped]) }
      def self.update_settings(username:, settings:)
        path = [@path, username, "settings"].join("/")
        patch_with_hash_format(path: path, params: settings)
      end

      # Generate a new API key for a user
      #
      # Requires appropriate permissions.
      #
      # @example Generate new API key
      #   api_key = Octoprint::Access::Users.generate_api_key(username: "john_doe")
      #
      # @param username [String] The user's login name
      # @return [String] The new API key
      sig { params(username: String).returns(String) }
      def self.generate_api_key(username:)
        path = [@path, username, "apikey"].join("/")
        response = client.request(path, { http_method: :post })
        response[:apikey]
      end

      # Delete a user's API key
      #
      # Requires appropriate permissions.
      #
      # @example Delete API key
      #   Octoprint::Access::Users.delete_api_key(username: "john_doe")
      #
      # @param username [String] The user's login name
      # @return [void]
      sig { params(username: String).returns(T.untyped) }
      def self.delete_api_key(username:)
        path = [@path, username, "apikey"].join("/")
        delete_resource(path)
        nil
      end

      # Retrieve information about the current user
      #
      # @example Get current user
      #   user = Octoprint::Access::Users.current
      #   puts "Current user: #{user.name}"
      #
      # @return [User] The current user object
      # @raise [RuntimeError] when no client is configured
      sig { returns(User) }
      def self.current
        response = client.request("/api/currentuser", http_method: :get)
        User.deserialize(response)
      end

      # Log in, or get the user tied to the current API key ("passive login")
      #
      # Without arguments, this is a passive login: OctoPrint returns the user
      # tied to the client's API key, along with a session key you can send in
      # the `auth` message of the push API. This is the main use case for this gem.
      #
      # With a username and a password, this is an active login. OctoPrint
      # checks the credentials, returns the user and sets a session cookie.
      # This gem only authenticates with its API key: it doesn't keep cookies,
      # so the session cookie is thrown away and later requests keep using the
      # API key. The returned {LoginResponse#session} is still valid for the push API.
      #
      # @example Passive login, to authenticate on the push API
      #   login = Octoprint::Access::Users.login
      #   login.user.name  # => "sophie"
      #   login.session    # => "5f8c1a..."
      #
      # @example Active login, to check a user's credentials
      #   login = Octoprint::Access::Users.login(username: "john_doe", password: "secret", remember: true)
      #   login.user.name  # => "john_doe"
      #
      # @param username [String, nil] The user's login name. Omit for a passive login
      # @param password [String, nil] The user's password. Omit for a passive login
      # @param remember [Boolean] Whether OctoPrint should set a "remember me" cookie (active login only)
      # @return [LoginResponse] The logged in user, the session key and whether the client is external
      # @raise [ArgumentError] if only one of `username` and `password` is given,
      #   or if `remember` is set on a passive login
      # @raise [Exceptions::AuthenticationError] if the username or password is wrong,
      #   the user is unknown or the account is deactivated
      # @see https://docs.octoprint.org/en/1.11.8/api/general.html#login
      sig do
        params(
          username: T.nilable(String),
          password: T.nilable(String),
          remember: T::Boolean
        ).returns(LoginResponse)
      end
      def self.login(username: nil, password: nil, remember: false)
        response = client.request("/api/login", http_method: :post,
                                                body: login_params(username, password, remember))
        LoginResponse.deserialize(response)
      end

      # End the current login session
      #
      # Logout only ends a session cookie set by a browser-based login. This gem
      # authenticates with its API key and doesn't keep cookies, so there is no
      # session to end and the API key keeps working afterwards. It is provided
      # for completeness.
      #
      # The docs say OctoPrint answers `204 No Content`, but OctoPrint 1.11.8
      # answers `200 OK` with the guest's needs as the body. Both mean success.
      #
      # @example
      #   Octoprint::Access::Users.logout # => true
      #
      # @return [Boolean] true when OctoPrint accepts the logout (`200` or `204`)
      # @see https://docs.octoprint.org/en/1.11.8/api/general.html#logout
      sig { returns(T::Boolean) }
      def self.logout # rubocop:disable Naming/PredicateMethod
        client.request("/api/logout", http_method: :post)
        true
      end

      sig do
        params(
          username: T.nilable(String),
          password: T.nilable(String),
          remember: T::Boolean
        ).returns(T::Hash[Symbol, T.untyped])
      end
      private_class_method def self.login_params(username, password, remember)
        if username.nil? && password.nil?
          raise ArgumentError, "remember only applies to an active login" if remember

          return { passive: true }
        end
        raise ArgumentError, "username and password must be given together" if username.nil? || password.nil?

        params = { user: username, pass: password }
        params[:remember] = true if remember
        params
      end

      sig { params(path: String, params: T::Hash[Symbol, T.untyped]).returns(T.untyped) }
      private_class_method def self.post_with_hash_format(path: @path, params: {})
        T.unsafe(client).request(path, { http_method: :post, params: params })
      end

      sig { params(path: String, params: T::Hash[Symbol, T.untyped]).returns(T.untyped) }
      private_class_method def self.put_with_hash_format(path: @path, params: {})
        T.unsafe(client).request(path, { http_method: :put, params: params })
      end

      sig { params(path: String, params: T::Hash[Symbol, T.untyped]).returns(T.untyped) }
      private_class_method def self.patch_with_hash_format(path: @path, params: {})
        T.unsafe(client).request(path, { http_method: :patch, params: params })
      end
    end
  end
end
