# typed: true
# frozen_string_literal: true

module Octoprint
  class Printer
    # A historic temperature data point.
    #
    # @example
    #   point = Octoprint::Printer.get(history: true).temperature.history.first
    #   point.time            # => 1395651928
    #   point.recorded_at     # => 2014-03-24 05:05:28 -0400
    #   point.tool(0).actual  # => 214.8821
    #   point.bed.target      # => 70.0
    #
    # @see https://docs.octoprint.org/en/master/api/datamodel.html#historic-temperature-data-point
    class TemperatureDataPoint
      include AutoInitializable
      include Deserializable

      # @!attribute [r] time
      #   @return [Integer, nil] Unix timestamp of this data point. Only included in the full printer state
      #     ({Printer.get}), not in the tool, bed and chamber responses
      auto_attr :time, type: Integer

      # @!attribute [r] tools
      #   @return [Hash{Symbol => Printer::TemperatureData}] Temperature data per tool, keyed by +:tool0+...
      #     Empty when the response contains no tool data
      auto_attr :tools, type: Hash

      # @!attribute [r] bed
      #   @return [Printer::TemperatureData, nil] Temperature data of the heated bed
      auto_attr :bed, type: TemperatureData

      # @!attribute [r] chamber
      #   @return [Printer::TemperatureData, nil] Temperature data of the heated chamber
      auto_attr :chamber, type: TemperatureData

      # @!attribute [r] extra
      #   @return [Hash, nil] Any additional fields returned by the API
      auto_attr :extra, type: Hash

      auto_initialize!

      deserialize_config do
        nested :bed, TemperatureData
        nested :chamber, TemperatureData

        transform do |data|
          TemperatureData.extract_tools(data)
        end
      end

      # Temperature data of the tool with the given index.
      #
      # @param index [Integer] The tool's index, starting at 0
      # @return [Printer::TemperatureData, nil] The tool's temperature data, nil if there is no such tool
      #: (?Integer index) -> TemperatureData?
      def tool(index = 0)
        tools&.[](:"tool#{index}")
      end

      # The data point's timestamp as a Time object.
      #
      # @return [Time, nil] The time of the data point
      #: -> Time?
      def recorded_at
        return nil unless time

        Time.at(time)
      end
    end
  end
end
