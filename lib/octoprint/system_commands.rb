# typed: strict
# frozen_string_literal: true

module Octoprint
  # The SystemCommands API allows retrieval and execution of system commands on the OctoPrint server.
  # System commands can be used to shutdown or restart the OctoPrint server or the system it's running on.
  #
  # @see https://docs.octoprint.org/en/master/api/system.html OctoPrint System API Documentation
  class SystemCommands < BaseResource
    extend T::Sig
    include Deserializable
    include AutoInitializable

    resource_path("/api/system/commands")

    # @!attribute [r] core
    #   @return [Array<Command>] List of core (predefined) system commands
    auto_attr :core, type: Command, array: true, nilable: false

    # @!attribute [r] custom
    #   @return [Array<Command>] List of custom (user-defined) system commands
    auto_attr :custom, type: Command, array: true, nilable: false

    # @!attribute [r] extra
    #   @return [Hash] Any additional fields returned by the API that are not explicitly defined
    auto_attr :extra, type: Hash

    auto_initialize!

    deserialize_config do
      array :core, Command
      array :custom, Command
    end

    # Retrieves all registered system commands from the OctoPrint server.
    #
    # This method fetches both core and custom system commands. Core commands are
    # predefined by OctoPrint (like shutdown, restart), while custom commands are
    # user-defined.
    #
    # @example Get all system commands
    #   commands = Octoprint::SystemCommands.list
    #
    #   # Access core commands
    #   commands.core.each do |cmd|
    #     puts "Core: #{cmd.name} - #{cmd.action}"
    #   end
    #
    #   # Access custom commands
    #   commands.custom.each do |cmd|
    #     puts "Custom: #{cmd.name} - #{cmd.action}"
    #   end
    #
    # @return [SystemCommands] A SystemCommands object containing arrays of core and custom commands
    # @raise [Octoprint::Exceptions::Error] if the request fails
    sig { returns(SystemCommands) }
    def self.list
      fetch_resource
    end
  end
end
