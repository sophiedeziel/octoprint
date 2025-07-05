# typed: true
# frozen_string_literal: true

module Octoprint
  # Information about the current user accessing the OctoPrint API
  #
  # OctoPrint's API doc: https://docs.octoprint.org/en/master/api/general.html#current-user
  #
  # @attr [String] name         User ID of the current user
  # @attr [Array] permissions   List of permissions assigned to the current user
  # @attr [Array] groups        List of groups the current user is a member of
  # @attr [Hash] extra          Additional fields from the API response for forward compatibility
  #
  # @example Get information about the current user
  #           Octoprint.configure(host: 'https://octopi.local/', api_key: 'j98G2nsJq...')
  #
  #           user = Octoprint::User.current
  #           user.name         #=> "admin"
  #           user.permissions  #=> ["STATUS", "CONNECTION", "WEBCAM", "SYSTEM", "SETTINGS_READ", "SETTINGS"]
  #           user.groups       #=> ["admin", "users"]
  class User < BaseResource
    extend T::Sig
    include Deserializable
    include AutoInitializable

    resource_path("/api/currentuser")

    # User attributes
    auto_attr :name, type: String, nilable: false
    auto_attr :permissions, type: Array
    auto_attr :groups, type: Array
    auto_attr :extra, type: Hash

    auto_initialize!

    # No configuration needed - camelCase conversion and extras collection are automatic!

    # Retrieves information about the current user
    #
    # @return [User] The current user object containing user information
    # @raise [RuntimeError] when no client is configured
    #
    # @example
    #           user = Octoprint::User.current
    #           puts "Current user: #{user.name}"
    sig { returns(Octoprint::User) }
    def self.current
      fetch_resource
    end
  end
end
