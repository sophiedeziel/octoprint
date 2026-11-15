# typed: true
# frozen_string_literal: true

module Octoprint
  class Printer
    # Temperature state of the printer's tools, bed and chamber, with an optional history.
    #
    # Returned by {Printer.get} (as {Printer#temperature}), {Printer::Tool.get}, {Printer::Bed.get}
    # and {Printer::Chamber.get}. Only the heaters relevant to the request are populated.
    #
    # @example
    #   temperature = Octoprint::Printer::Tool.get(history: true, limit: 2)
    #   temperature.tools.keys         # => [:tool0, :tool1]
    #   temperature.tool(0).actual     # => 214.8821
    #   temperature.history.first.time # => 1395651928
    #
    # @see https://docs.octoprint.org/en/master/api/printer.html#temperature-state
    class TemperatureState
      extend T::Sig
      include AutoInitializable
      include Deserializable

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

      # @!attribute [r] history
      #   @return [Array<Printer::TemperatureDataPoint>, nil] Temperature history, only included when requested
      auto_attr :history, type: TemperatureDataPoint, array: true

      # @!attribute [r] extra
      #   @return [Hash, nil] Any additional fields returned by the API
      auto_attr :extra, type: Hash

      auto_initialize!

      deserialize_config do
        nested :bed, TemperatureData
        nested :chamber, TemperatureData
        array :history, TemperatureDataPoint

        transform do |data|
          TemperatureData.extract_tools(data)
        end
      end

      # Temperature data of the tool with the given index.
      #
      # @example
      #   Octoprint::Printer::Tool.get.tool(1).target # => 205.0
      #
      # @param index [Integer] The tool's index, starting at 0
      # @return [Printer::TemperatureData, nil] The tool's temperature data, nil if there is no such tool
      sig { params(index: Integer).returns(T.nilable(TemperatureData)) }
      def tool(index = 0)
        tools&.[](:"tool#{index}")
      end
    end
  end
end
