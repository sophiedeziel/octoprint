# typed: true
# frozen_string_literal: true

module Octoprint
  # Full state of the printer: temperatures, SD card state and general printer state.
  #
  # @example Get the current printer state
  #   printer = Octoprint::Printer.get
  #   printer.state.text                    # => "Operational"
  #   printer.state.flags.printing          # => false
  #   printer.temperature.tool(0).actual    # => 214.8821
  #   printer.temperature.bed.target        # => 70.0
  #   printer.sd.ready                      # => true
  #
  # @example Include the temperature history, limited to the last two data points
  #   printer = Octoprint::Printer.get(history: true, limit: 2)
  #   printer.temperature.history.map(&:time) # => [1395651928, 1395651926]
  #
  # @example Exclude data that isn't needed
  #   printer = Octoprint::Printer.get(exclude: %i[temperature sd])
  #   printer.temperature # => nil
  #
  # @see https://docs.octoprint.org/en/master/api/printer.html OctoPrint Printer API Documentation
  class Printer < BaseResource
    extend T::Sig
    extend HistoryQuery
    include AutoInitializable
    include Deserializable

    resource_path("/api/printer")

    # @!attribute [r] temperature
    #   @return [Printer::TemperatureState, nil] The printer's temperature state, nil when excluded
    auto_attr :temperature, type: TemperatureState

    # @!attribute [r] sd
    #   @return [Printer::Sd, nil] The printer's SD card state, nil when excluded or unavailable
    auto_attr :sd, type: Sd

    # @!attribute [r] state
    #   @return [Printer::State, nil] The printer's general state, nil when excluded
    auto_attr :state, type: State

    # @!attribute [r] extra
    #   @return [Hash, nil] Any additional fields returned by the API
    auto_attr :extra, type: Hash

    auto_initialize!

    deserialize_config do
      nested :temperature, TemperatureState
      nested :sd, Sd
      nested :state, State
    end

    # Fields that can be excluded from the full state response.
    EXCLUDABLE_FIELDS = %w[temperature sd state].freeze

    # Retrieves the current state of the printer.
    #
    # @param history [Boolean] Whether to include the temperature history
    # @param limit [Integer, nil] Only return the last +limit+ history data points (ignored unless +history+ is true)
    # @param exclude [Array<String, Symbol>] Fields to leave out of the response: +temperature+, +sd+ and/or +state+
    #
    # @example Get the printer state
    #   printer = Octoprint::Printer.get
    #   printer.state.text # => "Operational"
    #
    # @example Get the printer state with the last 10 temperature data points
    #   Octoprint::Printer.get(history: true, limit: 10).temperature.history
    #
    # @example Only retrieve the general state
    #   Octoprint::Printer.get(exclude: %i[temperature sd]).state.flags.ready # => true
    #
    # @return [Printer] The current printer state
    # @raise [ArgumentError] if +exclude+ contains an unknown field
    # @raise [Octoprint::Exceptions::ConflictError] if the printer is not operational
    sig do
      params(
        history: T::Boolean,
        limit: T.nilable(Integer),
        exclude: T::Array[T.any(String, Symbol)]
      ).returns(Printer)
    end
    def self.get(history: false, limit: nil, exclude: [])
      options = history_query(history: history, limit: limit)

      if exclude.any?
        excluded = exclude.map(&:to_s)
        invalid = excluded - EXCLUDABLE_FIELDS
        raise ArgumentError, "Invalid exclude field(s): #{invalid.join(", ")}" if invalid.any?

        options[:exclude] = excluded.join(",")
      end

      fetch_resource(options: options)
    end
  end
end
