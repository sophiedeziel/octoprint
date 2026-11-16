# typed: true
# frozen_string_literal: true

module Octoprint
  class Printer
    # Boolean flags describing the printer's state.
    #
    # @example
    #   flags = Octoprint::Printer.get.state.flags
    #   flags.operational     # => true
    #   flags.printing        # => false
    #   flags.closed_or_error # => false
    #
    # @see https://docs.octoprint.org/en/master/api/datamodel.html#printer-state
    class StateFlags
      include AutoInitializable
      include Deserializable

      # @!attribute [r] operational
      #   @return [Boolean] true if the printer is operational
      auto_attr :operational, type: Types::Boolean

      # @!attribute [r] paused
      #   @return [Boolean] true if the printer is currently paused
      auto_attr :paused, type: Types::Boolean

      # @!attribute [r] printing
      #   @return [Boolean] true if the printer is currently printing
      auto_attr :printing, type: Types::Boolean

      # @!attribute [r] pausing
      #   @return [Boolean] true if the printer is currently printing and in the process of pausing
      auto_attr :pausing, type: Types::Boolean

      # @!attribute [r] cancelling
      #   @return [Boolean] true if the printer is currently printing and in the process of cancelling
      auto_attr :cancelling, type: Types::Boolean

      # @!attribute [r] resuming
      #   @return [Boolean, nil] true if the printer is in the process of resuming
      auto_attr :resuming, type: Types::Boolean

      # @!attribute [r] finishing
      #   @return [Boolean, nil] true if the printer is in the process of finishing a print
      auto_attr :finishing, type: Types::Boolean

      # @!attribute [r] sd_ready
      #   @return [Boolean] true if the printer's SD card is available and initialized
      auto_attr :sd_ready, type: Types::Boolean

      # @!attribute [r] error
      #   @return [Boolean] true if an unrecoverable error occurred
      auto_attr :error, type: Types::Boolean

      # @!attribute [r] ready
      #   @return [Boolean] true if the printer is operational and ready to receive instructions
      auto_attr :ready, type: Types::Boolean

      # @!attribute [r] closed_or_error
      #   @return [Boolean] true if the printer is disconnected (possibly due to an error)
      auto_attr :closed_or_error, type: Types::Boolean

      # @!attribute [r] extra
      #   @return [Hash, nil] Any additional flags returned by the API
      auto_attr :extra, type: Hash

      auto_initialize!
    end
  end
end
