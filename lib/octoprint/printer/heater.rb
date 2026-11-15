# typed: true
# frozen_string_literal: true

module Octoprint
  class Printer
    # Shared behaviour for single heater resources ({Printer::Bed} and {Printer::Chamber}).
    #
    # @abstract Subclasses must define their +resource_path+.
    class Heater < BaseResource
      extend T::Sig
      extend HistoryQuery

      # Retrieves the heater's current temperature data.
      #
      # @param history [Boolean] Whether to include the temperature history
      # @param limit [Integer, nil] Only return the last +limit+ history data points (ignored unless +history+ is true)
      #
      # @return [Printer::TemperatureState] The heater's temperature state
      # @raise [Octoprint::Exceptions::ConflictError] if the printer is not operational or the heater isn't configured
      sig { params(history: T::Boolean, limit: T.nilable(Integer)).returns(TemperatureState) }
      def self.get(history: false, limit: nil)
        TemperatureState.deserialize(
          fetch_resource(deserialize: false, options: history_query(history: history, limit: limit))
        )
      end

      # Issues a heater command.
      #
      # @param command [String] The command to issue: +target+ or +offset+
      # @param options [Hash] Additional command parameters
      #
      # @return [Boolean] true on success (204 No Content)
      # @raise [Octoprint::Exceptions::BadRequestError] if the parameters are invalid
      # @raise [Octoprint::Exceptions::ConflictError] if the printer is not operational or the heater isn't configured
      sig { params(command: String, options: T::Hash[Symbol, T.untyped]).returns(T.untyped) }
      def self.issue_command(command:, options: {})
        post(params: { command: command }.merge(options))
      end

      # Sets the heater's target temperature. A target of 0 turns the heater off.
      #
      # @param temperature [Numeric] The target temperature
      #
      # @return [Boolean] true on success (204 No Content)
      # @raise [Octoprint::Exceptions::BadRequestError] if the temperature is invalid
      # @raise [Octoprint::Exceptions::ConflictError] if the printer is not operational or the heater isn't configured
      sig { params(temperature: Numeric).returns(T.untyped) }
      def self.target(temperature)
        issue_command(command: "target", options: { target: temperature })
      end

      # Sets the heater's temperature offset.
      #
      # @param offset [Numeric] The temperature offset
      #
      # @return [Boolean] true on success (204 No Content)
      # @raise [Octoprint::Exceptions::BadRequestError] if the offset is invalid
      # @raise [Octoprint::Exceptions::ConflictError] if the printer is not operational or the heater isn't configured
      sig { params(offset: Numeric).returns(T.untyped) }
      def self.offset(offset)
        issue_command(command: "offset", options: { offset: offset })
      end
    end
  end
end
