# typed: true
# frozen_string_literal: true

module Octoprint
  class Connection
    # The connector and parameters OctoPrint uses when it connects without being told which ones.
    #
    # With the 1.x API, the gem builds it from the old `portPreference` and `baudratePreference` options.
    #
    # Octoprint's API doc: https://docs.octoprint.org/en/dev/api/connection.html
    #
    # @example
    #   preferred = Octoprint::Connection.get.options.preferred_connector
    #
    #   preferred.connector  #=> "serial"
    #   preferred.parameters #=> { port: "/dev/ttyACM0", baudrate: 115200 }
    class PreferredConnector
      include AutoInitializable

      # @!attribute [r] connector
      #   @return [String] The preferred connector's identifier, e.g. `"serial"`
      auto_attr :connector, type: String

      # @!attribute [r] parameters
      #   @return [Hash{Symbol => Object}] The preferred value of each parameter, nil when there is none
      auto_attr :parameters, type: Hash

      auto_initialize!
    end
  end
end
