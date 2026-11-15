# typed: true
# frozen_string_literal: true

module Octoprint
  class Printer
    # Temperature reading shared by the printer's heaters ({Printer::Tool}, {Printer::Bed} and
    # {Printer::Chamber}).
    #
    # Including this module declares the following attributes on the including class:
    #
    # - +actual+ [Float, nil] Current temperature
    # - +target+ [Float, nil] Target temperature, nil if no target temperature is set
    # - +offset+ [Float, nil] Currently configured temperature offset
    # - +history+ [Array<Printer::TemperatureReading>, nil] The heater's temperature history, only included
    #   when requested
    # - +extra+ [Hash, nil] Any additional fields returned by the API
    #
    # @example
    #   class Tool < BaseResource
    #     include TemperatureAttributes
    #   end
    #
    #   tool = Tool.from_response({ tool0: { actual: 214.8821, target: 220.0, offset: 0 } }, :tool0)
    #   tool.actual # => 214.8821
    module TemperatureAttributes
      extend T::Sig
      extend T::Helpers

      # Class methods added to the including class.
      module ClassMethods
        extend T::Sig

        # Builds a heater from a temperature response, picking the heater's own data out of the
        # response and out of every history data point.
        #
        # @api private
        # @param response [Hash] A tool, bed or chamber temperature response
        # @param key [Symbol] The heater's key in the response, e.g. +:tool0+ or +:bed+
        # @return [Object] An instance of the including class
        sig { params(response: T::Hash[Symbol, T.untyped], key: Symbol).returns(T.untyped) }
        def from_response(response, key)
          history = response[:history]&.filter_map do |point|
            reading = point[key]
            TemperatureReading.deserialize({ time: point[:time], **reading }.compact) if reading
          end

          T.unsafe(self).deserialize({ **response.fetch(key, {}), history: history }.compact)
        end
      end

      mixes_in_class_methods(ClassMethods)

      # Declares the temperature attributes on the including class.
      #
      # @param base [Class] The including class
      # @return [void]
      sig { params(base: Module).void }
      def self.included(base)
        super

        klass = T.unsafe(base)
        klass.include AutoInitializable
        klass.include Deserializable
        klass.auto_attr :actual, type: Float
        klass.auto_attr :target, type: Float
        klass.auto_attr :offset, type: Float
        klass.auto_attr :history, type: TemperatureReading, array: true
        klass.auto_attr :extra, type: Hash
        klass.auto_initialize!
      end
    end
  end
end
