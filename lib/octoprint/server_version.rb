# typed: true
# frozen_string_literal: true

module Octoprint
  # Version information about the OctoPrint server.
  #
  # @example Get server version
  #   version = Octoprint::ServerVersion.get
  #   puts "API: #{version.api}"
  #   puts "Server: #{version.server}"
  #   puts "Text: #{version.text}"
  #
  # @see https://docs.octoprint.org/en/master/api/version.html
  class ServerVersion < BaseResource
    extend T::Sig
    include AutoInitializable
    include Deserializable

    resource_path("/api/version")

    # @!attribute [r] api
    #   @return [String] The server's API version
    auto_attr :api, type: String, nilable: false

    # @!attribute [r] server
    #   @return [String] The server's version number
    auto_attr :server, type: String, nilable: false

    # @!attribute [r] text
    #   @return [String] Server version including the prefix "OctoPrint"
    auto_attr :text, type: String, nilable: false

    # @!attribute [r] extra
    #   @return [Hash] Any additional fields returned by the API
    auto_attr :extra, type: Hash

    auto_initialize!

    # Retrieve information regarding server and API version.
    #
    # @example Get server version
    #   version = Octoprint::ServerVersion.get
    #   puts "API: #{version.api}"
    #   puts "Server: #{version.server}"
    #
    # @return [ServerVersion] Version information object
    # @raise [Octoprint::Exceptions::Error] if the request fails
    sig { returns(ServerVersion) }
    def self.get
      fetch_resource
    end
  end
end
