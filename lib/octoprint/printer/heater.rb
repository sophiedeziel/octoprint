# typed: true
# frozen_string_literal: true

module Octoprint
  class Printer
    # Behaviour of the single heater resources ({Printer::Bed} and {Printer::Chamber}): reading the
    # heater's temperature and setting its target and offset.
    #
    # Including this module also includes {Printer::TemperatureAttributes}, so the including class gets the
    # +actual+, +target+, +offset+, +history+ and +extra+ attributes.
    #
    # @example
    #   class Bed < BaseResource
    #     include Heater
    #
    #     resource_path("/api/printer/bed")
    #   end
    #
    #   Bed.temperature.actual # => 50.221
    #   Bed.target(75)
    module Heater
      extend T::Helpers

      # Class methods added to the including resource.
      module ClassMethods
        extend T::Generic
        include HistoryQuery

        has_attached_class!(:out)

        # Retrieves the heater's current temperature.
        #
        # @param history [Boolean] Whether to include the temperature history
        # @param limit [Integer, nil] Only return the last +limit+ history data points (ignored unless +history+
        #   is true)
        #
        # @return [Object] The heater, e.g. a {Printer::Bed}, with its temperature
        # @raise [Octoprint::Exceptions::ConflictError] if the printer is not operational or the heater isn't
        #   configured
        #: (?history: bool, ?limit: Integer?) -> instance
        def temperature(history: false, limit: nil)
          response = T.unsafe(self).fetch_resource(deserialize: false,
                                                   options: history_query(history: history, limit: limit))

          T.unsafe(self).from_response(response, heater_key)
        end

        # Issues a heater command.
        #
        # @param command [String] The command to issue: +target+ or +offset+
        # @param options [Hash] Additional command parameters
        #
        # @return [Boolean] true on success (204 No Content)
        # @raise [Octoprint::Exceptions::BadRequestError] if the parameters are invalid
        # @raise [Octoprint::Exceptions::ConflictError] if the printer is not operational or the heater isn't
        #   configured
        #: (command: String, ?options: Hash[Symbol, untyped]) -> untyped
        def issue_command(command:, options: {})
          T.unsafe(self).post(params: { command: command }.merge(options))
        end

        # Sets the heater's target temperature. A target of 0 turns the heater off.
        #
        # @param temperature [Numeric] The target temperature
        #
        # @return [Boolean] true on success (204 No Content)
        # @raise [Octoprint::Exceptions::BadRequestError] if the temperature is invalid
        # @raise [Octoprint::Exceptions::ConflictError] if the printer is not operational or the heater isn't
        #   configured
        #: (Numeric temperature) -> untyped
        def target(temperature)
          issue_command(command: "target", options: { target: temperature })
        end

        # Sets the heater's temperature offset.
        #
        # @param offset [Numeric] The temperature offset
        #
        # @return [Boolean] true on success (204 No Content)
        # @raise [Octoprint::Exceptions::BadRequestError] if the offset is invalid
        # @raise [Octoprint::Exceptions::ConflictError] if the printer is not operational or the heater isn't
        #   configured
        #: (Numeric offset) -> untyped
        def offset(offset)
          issue_command(command: "offset", options: { offset: offset })
        end

        private

        # The heater's key in the API responses, derived from the class name (+:bed+, +:chamber+).
        #
        # @return [Symbol] The heater's key
        #: -> Symbol
        def heater_key
          T.must(T.unsafe(self).name).demodulize.underscore.to_sym
        end
      end

      mixes_in_class_methods(ClassMethods)

      # Adds the temperature attributes to the including resource.
      #
      # @param base [Class] The including resource
      # @return [void]
      #: (Module base) -> void
      def self.included(base)
        super

        T.unsafe(base).include TemperatureAttributes
      end
    end
  end
end
