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
      extend TemperatureResponse
      include AutoInitializable
      include Deserializable

      # @!attribute [r] actual
      #   @return [Float, nil] Current temperature
      auto_attr :actual, type: Float

      # @!attribute [r] target
      #   @return [Float, nil] Target temperature, nil if no target temperature is set
      auto_attr :target, type: Float

      # @!attribute [r] offset
      #   @return [Float, nil] Currently configured temperature offset
      auto_attr :offset, type: Float

      # @!attribute [r] history
      #   @return [Array<Printer::TemperatureReading>, nil] The heater's temperature history, only included
      #     when requested
      auto_attr :history, type: TemperatureReading, array: true

      # @!attribute [r] extra
      #   @return [Hash, nil] Any additional fields returned by the API
      auto_attr :extra, type: Hash

      auto_initialize!

      # Gives each heater its own copy of the declared attributes, so that deserialization
      # (including the collection of unknown fields into +extra+) works on subclasses.
      #
      # @param subclass [Class] The inheriting heater
      # @return [void]
      def self.inherited(subclass)
        super
        subclass.instance_variable_set(:@auto_attrs, auto_attrs.dup)
      end

      # Retrieves the heater's current temperature.
      #
      # @param history [Boolean] Whether to include the temperature history
      # @param limit [Integer, nil] Only return the last +limit+ history data points (ignored unless +history+ is true)
      #
      # @return [Printer::Heater] The heater, e.g. a {Printer::Bed}, with its temperature
      # @raise [Octoprint::Exceptions::ConflictError] if the printer is not operational or the heater isn't configured
      sig { params(history: T::Boolean, limit: T.nilable(Integer)).returns(T.attached_class) }
      def self.temperature(history: false, limit: nil)
        response = fetch_resource(deserialize: false, options: history_query(history: history, limit: limit))

        from_response(response, heater_key)
      end

      # The heater's key in the API responses, derived from the class name (+:bed+, +:chamber+).
      #
      # @return [Symbol] The heater's key
      sig { returns(Symbol) }
      def self.heater_key
        T.must(name).demodulize.underscore.to_sym
      end
      private_class_method :heater_key

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
