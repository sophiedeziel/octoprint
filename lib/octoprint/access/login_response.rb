# typed: true
# frozen_string_literal: true

module Octoprint
  module Access
    # The response of a login request (`POST /api/login`)
    #
    # OctoPrint returns a user record with a few extra fields. The user record is
    # wrapped in a {User} (see {#user}), and the extra fields have their own readers.
    #
    # @example Get a session key for the push API
    #   login = Octoprint::Access::Users.login
    #   login.user.name           # => "sophie"
    #   login.session             # => "5f8c1a..."
    #   login.is_external_client  # => false
    #   login.login_mechanism     # => "apikey"
    #
    # @see https://docs.octoprint.org/en/1.11.8/api/general.html#data-model
    class LoginResponse
      include AutoInitializable
      include Deserializable

      # Fields of the login response that are not part of the user record
      LOGIN_FIELDS = %i[session is_external_client login_mechanism credentials_seen].freeze

      # @!attribute [r] user
      #   @return [User] The user tied to the session or the API key
      auto_attr :user, type: User

      # @!attribute [r] session
      #   @return [String] Session key, usable with the `auth` message on the push API
      auto_attr :session, type: String

      # @!attribute [r] is_external_client
      #   @return [Boolean] Whether the request was detected as coming from outside the local network
      auto_attr :is_external_client, type: Types::Boolean

      # @!attribute [r] login_mechanism
      #   @return [String, nil] How the user was authenticated, e.g. "apikey" or "password".
      #     Not in the 1.11.8 docs, but sent by OctoPrint 1.11.8
      auto_attr :login_mechanism, type: String

      # @!attribute [r] credentials_seen
      #   @return [String, nil] ISO 8601 time of the last credentials check, e.g. "2026-11-16T03:56:31+00:00".
      #     Not in the 1.11.8 docs, but sent by OctoPrint 1.11.8
      auto_attr :credentials_seen, type: String

      auto_initialize!

      deserialize_config do
        rename _is_external_client: :is_external_client,
               _login_mechanism: :login_mechanism,
               _credentials_seen: :credentials_seen
        transform do |data|
          # Everything that isn't a login field belongs to the user record
          user_data = data.except(*LOGIN_FIELDS)
          user_data.each_key { |key| data.delete(key) }
          data[:user] = User.deserialize(user_data)
        end
      end
    end
  end
end
