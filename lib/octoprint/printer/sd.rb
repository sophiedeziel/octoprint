# typed: true
# frozen_string_literal: true

module Octoprint
  class Printer
    # The printer's SD card state, as included in the full printer state.
    #
    # @example
    #   Octoprint::Printer.get.sd.ready # => true
    #
    # @see https://docs.octoprint.org/en/master/api/printer.html#sd-state
    class Sd < BaseResource
      include AutoInitializable
      include Deserializable

      resource_path("/api/printer/sd")

      # @!attribute [r] ready
      #   @return [Boolean] Whether the SD card has been initialized
      auto_attr :ready, type: Types::Boolean

      # @!attribute [r] extra
      #   @return [Hash, nil] Any additional fields returned by the API
      auto_attr :extra, type: Hash

      auto_initialize!
    end
  end
end
