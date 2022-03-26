# frozen_string_literal: true

module Octoprint
  # Connection handling with the 3D printer
  #
  # Octoprint's API doc: https://docs.octoprint.org/en/master/api/connection.html
  #
  # @attr [Connection::Settings] current connection state
  # @attr [Connection::Options] options connection options
  #
  # @example
  #           Octoprint.configure(host: 'https://octopi.local/', api_key: 'j98G2nsJq...')
  #
  #           connection = Octoprint::Connection.get
  #           connection.current.state= #=> "Printing"
  #           connection.options.ports #=> ["/dev/ttyACM0"]
  class Connection < BaseResource
    resource_path("/api/connection")
    attr_reader :current, :options

    def initialize(current:, options:)
      @current = Settings.new(**current)
      @options = Options.new(**options)
      super()
    end

    # Retrieve the current connection settings, including information regarding the available baudrates and serial ports
    # and the current connection state.
    #
    # @return [Connection]
    #
    # @example
    #           client = Octoprint::Client.new(host: 'https://octopi.local/', api_key: 'j98G2nsJq...')
    #
    #           connection = Octoprint::Connection.get(client: client)
    #           connection.current.state= #=> "Printing"
    #           connection.options.ports #=> ["/dev/ttyACM0"]
    def self.get
      fetch_resource
    end

    # Closses the serial connection from Octoprint to the printer
    #
    # @return [True]
    def self.disconnect
      post(params: { command: "disconnect" })
    end

    # Opens the serial connection from Octoprint to the printer. When the options are left out, OctoPrint will use
    # existing preference if available or attempt autodetection.
    #
    # @option [String] port The port to connect to.
    # @option [Integer] baudrate The baudrate to connect with.
    # @option [String] printerProfile The id of the printer profile to use for the connection.
    # @option [Boolean] save Whether to save the supplied connection settings as the new preference.
    # @option [Boolean] autoconnect Whether to attempt to automatically connect to the printer on server startup.
    #
    # @return [True]
    def self.connect(params = {})
      params[:command] = "connect"
      post(params: params)
    end

    # Fakes an acknowledgment message for OctoPrint in case one got lost on the serial line and the communication with
    # the printer since stalled. This should only be used in “emergencies” (e.g. to save prints), the reason for the
    # lost acknowledgment should always be properly investigated and removed instead of depending on this “symptom
    # solver”.
    # @return [True]
    def self.fake_ack
      post(params: { command: "fake_ack" })
    end
  end
end
