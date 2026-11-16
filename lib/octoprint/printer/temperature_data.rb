# typed: true
# frozen_string_literal: true

module Octoprint
  class Printer
    # Temperature data of a single heater (tool, bed or chamber).
    #
    # @example
    #   bed = Octoprint::Printer.get.temperature.bed
    #   bed.actual # => 50.221
    #   bed.target # => 70.0
    #   bed.offset # => 5
    #
    # @see https://docs.octoprint.org/en/master/api/datamodel.html#temperature-data
    class TemperatureData
      include AutoInitializable
      include Deserializable

      # Matches the keys of tool temperatures, e.g. +tool0+, +tool1+
      TOOL_KEY = /\Atool\d+\z/

      # @!attribute [r] actual
      #   @return [Float, nil] Current temperature
      auto_attr :actual, type: Float

      # @!attribute [r] target
      #   @return [Float, nil] Target temperature, nil if no target temperature is set
      auto_attr :target, type: Float

      # @!attribute [r] offset
      #   @return [Float, nil] Currently configured temperature offset, not included in historic data points
      auto_attr :offset, type: Float

      # @!attribute [r] extra
      #   @return [Hash, nil] Any additional fields returned by the API
      auto_attr :extra, type: Hash

      auto_initialize!

      # Moves all +tool{n}+ entries of a temperature hash into a +:tools+ hash of {TemperatureData}.
      #
      # @api private
      # @param data [Hash] A temperature state or history data point hash
      # @return [Hash] The modified data hash
      #: (Hash[Symbol, untyped] data) -> Hash[Symbol, untyped]
      def self.extract_tools(data)
        tool_keys = data.keys.select { |key| key.to_s.match?(TOOL_KEY) }
        data[:tools] = tool_keys.to_h { |key| [key, deserialize(data.delete(key))] }
        data
      end
    end
  end
end
