# typed: true
# frozen_string_literal: true

module Octoprint
  class Printer
    # A historic temperature reading of a single heater.
    #
    # @example
    #   reading = Octoprint::Printer::Tool.temperatures(history: true)[0].history.first
    #   reading.actual # => 50.221
    #   reading.target # => 70.0
    #
    # @see https://docs.octoprint.org/en/master/api/datamodel.html#historic-temperature-data-point
    class TemperatureReading
      include AutoInitializable
      include Deserializable

      # @!attribute [r] time
      #   @return [Integer, nil] Unix timestamp of the reading, when provided by the server
      auto_attr :time, type: Integer

      # @!attribute [r] actual
      #   @return [Float, nil] Temperature at the time of the reading
      auto_attr :actual, type: Float

      # @!attribute [r] target
      #   @return [Float, nil] Target temperature at the time of the reading, nil if none was set
      auto_attr :target, type: Float

      # @!attribute [r] extra
      #   @return [Hash, nil] Any additional fields returned by the API
      auto_attr :extra, type: Hash

      auto_initialize!

      # The reading's timestamp as a Time object.
      #
      # @return [Time, nil] The time of the reading, nil when the server didn't provide one
      #: -> Time?
      def recorded_at
        return nil unless time

        Time.at(time)
      end
    end
  end
end
