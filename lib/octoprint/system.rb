# typed: strict
# frozen_string_literal: true

module Octoprint
  # The System API allows retrieval and execution of system commands on the OctoPrint server.
  # System commands can be used to shutdown or restart the OctoPrint server or the system it's running on.
  #
  # @see https://docs.octoprint.org/en/master/api/system.html OctoPrint System API Documentation
  class System < BaseResource
    extend T::Sig

    resource_path("/api/system")

    # Retrieves all configured system commands.
    #
    # Returns all configured system commands divided by source.
    # The response contains two sections: `core` (predefined commands) and `custom` (user-defined commands).
    #
    # @example List all system commands
    #   commands = Octoprint::System.commands
    #   commands.core.each do |cmd|
    #     puts "#{cmd.name} (#{cmd.action})"
    #   end
    #
    # @return [Commands] An object containing core and custom system commands
    # @raise [Octoprint::Exceptions::Error] if the request fails
    sig { returns(Commands) }
    def self.commands
      Commands.list
    end
  end
end
