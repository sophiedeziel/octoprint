# typed: true
# frozen_string_literal: true

module Octoprint
  class Printer
    # The printer's general state.
    #
    # @example
    #   state = Octoprint::Printer.get.state
    #   state.text            # => "Operational"
    #   state.flags.ready     # => true
    #
    # @see https://docs.octoprint.org/en/master/api/datamodel.html#printer-state
    class State
      include AutoInitializable
      include Deserializable

      # @!attribute [r] text
      #   @return [String] A textual representation of the current state, e.g. "Operational" or "Printing"
      auto_attr :text, type: String

      # @!attribute [r] flags
      #   @return [Printer::StateFlags] Boolean printer state flags
      auto_attr :flags, type: StateFlags

      # @!attribute [r] error
      #   @return [String, nil] The current error message, if any
      auto_attr :error, type: String

      # @!attribute [r] extra
      #   @return [Hash, nil] Any additional fields returned by the API
      auto_attr :extra, type: Hash

      auto_initialize!

      deserialize_config do
        nested :flags, StateFlags
      end
    end
  end
end
