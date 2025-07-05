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

    # Retrieves all registered system commands for a specific source from the OctoPrint server.
    #
    # This method fetches system commands from a specific source (e.g., "core" or "custom").
    # The source determines which set of commands to retrieve.
    #
    # @example Get core system commands
    #   commands = Octoprint::SystemCommands.list_by_source("core")
    #   commands.each do |cmd|
    #     puts "#{cmd.name} - #{cmd.action}"
    #   end
    #
    # @example Get custom system commands
    #   commands = Octoprint::SystemCommands.list_by_source("custom")
    #   commands.each do |cmd|
    #     puts "#{cmd.name} - #{cmd.action}"
    #   end
    #
    # @param source [String] The source to retrieve commands for (e.g., "core", "custom")
    # @return [Array<Command>] Array of Command objects for the specified source
    # @raise [Octoprint::Exceptions::Error] if the request fails
    sig { params(source: String).returns(T::Array[Command]) }
    def self.list_by_source(source)
      response = fetch_resource(source, deserialize: false)
      response.map { |command_data| Command.deserialize(command_data) }
    end

    # Executes a registered system command on the OctoPrint server.
    #
    # This method sends a POST request to execute a specific system command.
    # The command must be pre-registered on the server and available in the specified source.
    #
    # @example Execute core restart command
    #   Octoprint::SystemCommands.execute("core", "restart")
    #
    # @example Execute core reboot command
    #   Octoprint::SystemCommands.execute("core", "reboot")
    #
    # @example Execute custom command
    #   Octoprint::SystemCommands.execute("custom", "my_custom_command")
    #
    # @param source [String] The source of the command (e.g., "core", "custom")
    # @param action [String] The action/identifier of the command to execute
    # @return [Boolean] true if the command was executed successfully
    # @raise [Octoprint::Exceptions::Error] if the request fails or command is not found
    sig { params(source: String, action: String).returns(T::Boolean) }
    def self.execute(source, action) # rubocop:disable Naming/PredicateMethod
      post(path: "/api/system/commands/#{source}/#{action}")
      true
    end
  end
end
