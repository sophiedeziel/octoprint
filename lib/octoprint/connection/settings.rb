# typed: true
# frozen_string_literal: true

module Octoprint
  class Connection
    # Current connection settings of the printer.
    #
    # Octoprint's API doc: https://docs.octoprint.org/en/master/api/connection.html
    #
    # @attr [String] state Connection state
    # @attr [String] port  Serial port
    # @attr [Integer] baudrate Serial communication baud rate
    # @attr [String] printer_profile Current printer profile
    #
    # @example
    #           Octoprint.configure(host: 'https://octopi.local/', api_key: 'j98G2nsJq...')
    #
    #           settings = Octoprint::Connection.get.current
    #
    #           settings.state #=> "Operational"
    #           settings.port #=>  "/dev/ttyACM0"
    #           settings.baudrate #=> 250000
    #           settings.printer_profile #=> "_default"
    class Settings
      include AutoInitializable

      auto_attr :state
      auto_attr :port
      auto_attr :baudrate
      auto_attr :printer_profile

      auto_initialize!
    end
  end
end
