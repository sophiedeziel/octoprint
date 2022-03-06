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
    # @option options [Octoprint::Client] :client the API client to use
    # @return [Connection]
    #
    # @example
    #           client = Octoprint::Client.new(host: 'https://octopi.local/', api_key: 'j98G2nsJq...')
    #
    #           connection = Octoprint::Connection.get(client: client)
    #           connection.current.state= #=> "Printing"
    #           connection.options.ports #=> ["/dev/ttyACM0"]
    def self.get(options = {})
      super(**options)
    end
  end
end
