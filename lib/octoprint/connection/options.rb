# typed: true
# frozen_string_literal: true

module Octoprint
  class Connection
    # Available connection options of the printer.
    #
    # Octoprint's API doc: https://docs.octoprint.org/en/master/api/connection.html
    #
    # @attr [Array<String>] ports Available ports
    # @attr [Array<Integer>] baudrates  Available baudrates
    # @attr [Array<Hash>] printer_profiles
    # @attr [String | nil] port_preference
    # @attr [Integer] baudrate_preference
    # @attr [String] printer_profile_preference
    # @attr [Boolean | nil] autoconnect
    #
    # @example
    #           Octoprint.configure(host: 'https://octopi.local/', api_key: 'j98G2nsJq...')
    #
    #           options = Octoprint::Connection.get.options
    #
    #           options.ports #=> ["/dev/ttyACM0"]
    #           options.baudrates #=>  [250000, 230400, 115200, 57600, 38400, 19200, 9600]
    #           options.printer_profiles #=>  [{:id=>"_default", :name=>"Creality CR-10s"}]
    #           options.port_preference #=>  nil
    #           options.baudrate_preference #=>  250000
    #           options.printer_profile_preference #=>  "_default"
    #           options.autoconnect #=>  nil
    class Options
      include AutoInitializable

      auto_attr :ports, type: String, array: true
      auto_attr :baudrates, type: Integer, array: true
      auto_attr :printer_profiles, type: Hash, array: true
      auto_attr :port_preference, type: String
      auto_attr :baudrate_preference, type: Integer
      auto_attr :printer_profile_preference, type: String
      auto_attr :autoconnect, type: T::Boolean

      auto_initialize!
    end
  end
end
