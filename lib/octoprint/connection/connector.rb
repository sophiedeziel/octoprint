# typed: true
# frozen_string_literal: true

module Octoprint
  class Connection
    # A connector OctoPrint can use to reach the printer, and the values it accepts for each of its parameters.
    #
    # OctoPrint 1.x only has the serial connector. With the 1.x API, the gem builds it from the old `ports` and
    # `baudrates` options.
    #
    # Octoprint's API doc: https://docs.octoprint.org/en/dev/api/connection.html
    #
    # @example
    #   connector = Octoprint::Connection.get.options.connectors.first
    #
    #   connector.connector  #=> "serial"
    #   connector.name       #=> "Serial Connection"
    #   connector.parameters #=> { port: ["/dev/ttyACM0", "VIRTUAL"], baudrate: [115200, 250000, ...] }
    class Connector
      include AutoInitializable

      # @!attribute [r] connector
      #   @return [String] The connector's identifier, e.g. `"serial"`. Pass it to {Connection.connect}
      auto_attr :connector, type: String

      # @!attribute [r] name
      #   @return [String] The connector's human-readable name, e.g. `"Serial Connection"`
      auto_attr :name, type: String

      # @!attribute [r] parameters
      #   @return [Hash{Symbol => Array}] The values each parameter accepts, by parameter name. The serial
      #     connector has `port` and `baudrate`
      auto_attr :parameters, type: Hash

      auto_initialize!
    end
  end
end
