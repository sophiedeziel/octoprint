# typed: true
# frozen_string_literal: true

module Octoprint
  class Connection
    # Available connection options of the printer, in the OctoPrint 2.0 shape.
    #
    # With the 1.x API, the gem converts the old `ports`, `baudrates`, `portPreference` and `baudratePreference`
    # into a single `serial` connector.
    #
    # Octoprint's API doc: https://docs.octoprint.org/en/dev/api/connection.html
    #
    # @example
    #   Octoprint.configure(host: 'https://octopi.local/', api_key: 'j98G2nsJq...')
    #
    #   options = Octoprint::Connection.get.options
    #
    #   options.connectors.map(&:connector)    #=> ["serial"]
    #   options.connectors.first.parameters    #=> { port: ["/dev/ttyACM0", "VIRTUAL"], baudrate: [115200, ...] }
    #   options.preferred_connector.connector  #=> "serial"
    #   options.preferred_connector.parameters #=> { port: nil, baudrate: nil }
    #   options.profiles                       #=> [{ id: "_default", name: "Default" }]
    #   options.preferred_profile              #=> "_default"
    class Options
      include AutoInitializable

      # @!attribute [r] connectors
      #   @return [Array<Connector>, nil] The available connectors and the values their parameters accept
      auto_attr :connectors, type: Connector, array: true

      # @!attribute [r] profiles
      #   @return [Array<Hash>, nil] The available printer profiles (`id` and `name`)
      auto_attr :profiles, type: Hash, array: true

      # @!attribute [r] preferred_connector
      #   @return [PreferredConnector, nil] The connector and parameters used when none are given
      auto_attr :preferred_connector, type: PreferredConnector

      # @!attribute [r] preferred_profile
      #   @return [String, nil] Identifier of the printer profile used when none is given
      auto_attr :preferred_profile, type: String

      # @!attribute [r] autoconnect
      #   @return [Boolean, nil] Whether OctoPrint connects to the printer on startup. Only some 1.x servers report
      #     it; always nil with the 2.0 API
      auto_attr :autoconnect, type: T::Boolean

      auto_initialize!

      # Available serial ports
      #
      # @deprecated Use the `port` parameter of the serial connector in {#connectors}
      # @return [Array<String>, nil]
      #: -> Array[String]?
      def ports
        Deprecation.warn_once("Connection::Options#ports", "use the serial connector in connectors")
        serial_connector&.parameters&.[](:port)
      end

      # Available serial baud rates
      #
      # @deprecated Use the `baudrate` parameter of the serial connector in {#connectors}
      # @return [Array<Integer>, nil]
      #: -> Array[Integer]?
      def baudrates
        Deprecation.warn_once("Connection::Options#baudrates", "use the serial connector in connectors")
        serial_connector&.parameters&.[](:baudrate)
      end

      # Available printer profiles
      #
      # @deprecated Use {#profiles}
      # @return [Array<Hash>, nil]
      #: -> Array[Hash[untyped, untyped]]?
      def printer_profiles
        Deprecation.warn_once("Connection::Options#printer_profiles", "use profiles")
        profiles
      end

      # Preferred serial port
      #
      # @deprecated Use {#preferred_connector}
      # @return [String, nil]
      #: -> String?
      def port_preference
        Deprecation.warn_once("Connection::Options#port_preference", "use preferred_connector")
        serial_preference(:port)
      end

      # Preferred serial baud rate
      #
      # @deprecated Use {#preferred_connector}
      # @return [Integer, nil]
      #: -> Integer?
      def baudrate_preference
        Deprecation.warn_once("Connection::Options#baudrate_preference", "use preferred_connector")
        serial_preference(:baudrate)
      end

      # Identifier of the preferred printer profile
      #
      # @deprecated Use {#preferred_profile}
      # @return [String, nil]
      #: -> String?
      def printer_profile_preference
        Deprecation.warn_once("Connection::Options#printer_profile_preference", "use preferred_profile")
        preferred_profile
      end

      private

      #: -> Connector?
      def serial_connector
        connectors&.find { |connector| connector.connector == SERIAL }
      end

      #: (Symbol) -> untyped
      def serial_preference(parameter)
        preferred = preferred_connector
        return if preferred.nil? || preferred.connector != SERIAL

        preferred.parameters&.[](parameter)
      end
    end
  end
end
