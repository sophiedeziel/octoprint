# typed: true
# frozen_string_literal: true

module Octoprint
  class Connection
    # Current connection of the printer, in the OctoPrint 2.0 shape.
    #
    # With the 1.x API, the gem converts the old `port` and `baudrate` into the `serial` connector and its
    # parameters.
    #
    # Octoprint's API doc: https://docs.octoprint.org/en/dev/api/connection.html
    #
    # @example
    #   Octoprint.configure(host: 'https://octopi.local/', api_key: 'j98G2nsJq...')
    #
    #   settings = Octoprint::Connection.get.current
    #
    #   settings.state        #=> "Operational"
    #   settings.connector    #=> "serial"
    #   settings.parameters   #=> { port: "VIRTUAL", baudrate: 115200 }
    #   settings.capabilities #=> { job_on_hold: true, temperature_offsets: true }
    #   settings.profile      #=> "_default"
    class Settings
      include AutoInitializable

      # @!attribute [r] state
      #   @return [String] Connection state, e.g. `"Operational"`, `"Offline"` (2.0) or `"Closed"` (1.x)
      auto_attr :state, type: String

      # @!attribute [r] connector
      #   @return [String, nil] The connector in use, e.g. `"serial"`. nil while disconnected
      auto_attr :connector, type: String

      # @!attribute [r] parameters
      #   @return [Hash{Symbol => Object}, nil] The connector's parameters, e.g. `{ port: "VIRTUAL", baudrate: 115200 }`
      #     for the serial connector. Empty while disconnected
      auto_attr :parameters, type: Hash

      # @!attribute [r] capabilities
      #   @return [Hash{Symbol => Boolean}, nil] What the connected printer supports, e.g.
      #     `{ job_on_hold: true, temperature_offsets: true }`. nil while disconnected, and always with the 1.x API
      auto_attr :capabilities, type: Hash

      # @!attribute [r] profile
      #   @return [String, nil] Identifier of the printer profile in use
      auto_attr :profile, type: String

      auto_initialize!

      # Serial port of the connection
      #
      # @deprecated Use `parameters[:port]`
      # @return [String, nil]
      #: -> String?
      def port
        Deprecation.warn_once("Connection::Settings#port", "use parameters[:port]")
        parameters&.[](:port)
      end

      # Baud rate of the serial connection
      #
      # @deprecated Use `parameters[:baudrate]`
      # @return [Integer, nil]
      #: -> Integer?
      def baudrate
        Deprecation.warn_once("Connection::Settings#baudrate", "use parameters[:baudrate]")
        parameters&.[](:baudrate)
      end

      # Identifier of the printer profile in use
      #
      # @deprecated Use {#profile}
      # @return [String, nil]
      #: -> String?
      def printer_profile
        Deprecation.warn_once("Connection::Settings#printer_profile", "use profile")
        profile
      end
    end
  end
end
