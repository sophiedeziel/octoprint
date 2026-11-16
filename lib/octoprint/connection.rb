# typed: true
# frozen_string_literal: true

module Octoprint
  # Connection handling with the 3D printer
  #
  # The model follows the OctoPrint 2.0 shape, where a **connector** (e.g. `serial`) and its parameters (e.g.
  # `port` and `baudrate`) describe the connection. With the 1.x API (the default), the gem converts the old
  # serial-only `port`/`baudrate` shape to it, so the same code works with both versions.
  #
  # Octoprint's API doc: https://docs.octoprint.org/en/dev/api/connection.html
  #
  # @attr [Connection::Settings] current The current connection
  # @attr [Connection::Options] options The available connectors and printer profiles
  #
  # @example
  #   Octoprint.configure(host: 'https://octopi.local/', api_key: 'j98G2nsJq...')
  #
  #   connection = Octoprint::Connection.get
  #   connection.current.state                     #=> "Operational"
  #   connection.current.parameters                #=> { port: "VIRTUAL", baudrate: 115200 }
  #   connection.options.connectors.map(&:connector) #=> ["serial"]
  #
  #   Octoprint::Connection.connect(connector: "serial", parameters: { port: "VIRTUAL", baudrate: 115200 })
  class Connection < BaseResource
    include AutoInitializable

    # Identifier of the serial connector, the only one OctoPrint 1.x has
    SERIAL = "serial"

    # Keys of the deprecated `connect(port:, baudrate:, ...)` call style
    LEGACY_CONNECT_KEYS = %i[port baudrate printerProfile save autoconnect].freeze
    private_constant :LEGACY_CONNECT_KEYS

    resource_path("/api/connection")

    auto_attr :current, type: Settings, from: :current
    auto_attr :options, type: Options, from: :options

    auto_initialize!

    class << self
      # Retrieve the current connection, the available connectors with the values their parameters accept, and the
      # printer profiles.
      #
      # @return [Connection]
      #
      # @example
      #   connection = Octoprint::Connection.get
      #   connection.current.state #=> "Operational"
      #   connection.options.connectors.first.parameters[:port] #=> ["/dev/ttyACM0", "VIRTUAL"]
      #: -> Connection
      def get
        fetch_resource
      end

      # Closes the connection from OctoPrint to the printer
      #
      # @return [true]
      #: -> bool
      def disconnect
        post(params: { command: "disconnect" })
      end

      # Opens the connection from OctoPrint to the printer. Without parameters, OctoPrint uses the existing
      # preferences if there are any, or tries to autodetect them.
      #
      # Only the `serial` connector exists with the 1.x API: its parameters are sent as the old `port` and
      # `baudrate`. The old `connect(port:, baudrate:, printerProfile:)` call style still works, but is deprecated.
      #
      # @example Connect to the virtual printer
      #   Octoprint::Connection.connect(connector: "serial", parameters: { port: "VIRTUAL", baudrate: 115200 })
      #
      # @example Autodetect, and save the profile as the new preference
      #   Octoprint::Connection.connect(printer_profile: "_default", save: true)
      #
      # @param legacy_params [Hash] Deprecated: `port`, `baudrate`, `printerProfile`, `save` and `autoconnect`
      # @param connector [String] The connector to use. Only `"serial"` with the 1.x API
      # @param parameters [Hash, nil] The connector's parameters, e.g. `{ port: "VIRTUAL", baudrate: 115200 }`
      # @param printer_profile [String, nil] The id of the printer profile to use
      # @param save [Boolean, nil] Whether to save the connection settings as the new preference
      # @param autoconnect [Boolean, nil] Whether to connect to the printer automatically on server startup
      # @param legacy_options [Hash] Deprecated: `port:`, `baudrate:` and `printerProfile:`
      # @return [true]
      # @raise [Exceptions::UnsupportedFeatureError] for a connector other than `serial` with the 1.x API
      # @raise [ArgumentError] for an unknown option
      #: (
      #|   ?Hash[Symbol, untyped] legacy_params,
      #|   ?connector: String,
      #|   ?parameters: Hash[Symbol, untyped]?,
      #|   ?printer_profile: String?,
      #|   ?save: bool?,
      #|   ?autoconnect: bool?,
      #|   **untyped legacy_options
      #| ) -> bool
      def connect(legacy_params = {}, connector: SERIAL, parameters: nil, printer_profile: nil, save: nil,
                  autoconnect: nil, **legacy_options)
        legacy = legacy_connect_options(legacy_params.merge(legacy_options))
        parameters ||= legacy[:parameters]
        printer_profile ||= legacy[:printer_profile]
        save = legacy[:save] if save.nil?
        autoconnect = legacy[:autoconnect] if autoconnect.nil?

        require_feature!(:connectors) unless connector == SERIAL

        post(params: {
          command: "connect", connector: connector, parameters: parameters,
          printerProfile: printer_profile, save: save, autoconnect: autoconnect
        }.compact)
      end

      # Tells OctoPrint to recover from a stalled communication with the printer, e.g. by faking a lost
      # acknowledgment on the serial line. Only use it in emergencies (e.g. to save a print): investigate and fix
      # the cause instead of depending on it.
      #
      # Sent as the old `fake_ack` command with the 1.x API.
      #
      # @example
      #   Octoprint::Connection.repair #=> true
      #
      # @return [true]
      #: -> bool
      def repair
        post(params: { command: "repair" })
      end

      # Fakes an acknowledgment message for OctoPrint in case one got lost on the serial line.
      #
      # @deprecated Use {.repair}, which OctoPrint 2.0 renamed it to
      # @return [true]
      #: -> bool
      def fake_ack
        Deprecation.warn_once("Connection.fake_ack", "use Connection.repair")
        repair
      end

      private

      # Converts the deprecated `connect` options to the new ones
      #
      #: (Hash[Symbol, untyped]) -> Hash[Symbol, untyped]
      def legacy_connect_options(options)
        return {} if options.empty?

        unknown = options.keys - LEGACY_CONNECT_KEYS
        raise ArgumentError, "unknown keywords: #{unknown.map(&:inspect).join(", ")}" unless unknown.empty?

        Deprecation.warn_once(
          "Connection.connect(port:, baudrate:, printerProfile:)",
          'use Connection.connect(connector: "serial", parameters: { port:, baudrate: }, printer_profile:)'
        )
        serial = options.slice(:port, :baudrate).compact
        {
          parameters: serial.empty? ? nil : serial,
          printer_profile: options[:printerProfile],
          save: options[:save],
          autoconnect: options[:autoconnect]
        }
      end
    end
  end
end
