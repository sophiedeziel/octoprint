# typed: true
# frozen_string_literal: true

module Octoprint
  class Printer
    # Builds heater objects ({Printer::Tool}, {Printer::Bed}, {Printer::Chamber}) out of the
    # temperature responses of the tool, bed and chamber endpoints.
    #
    # @api private
    module TemperatureResponse
      extend T::Sig

      # Builds a heater from a temperature response, picking the heater's own data out of the
      # response and out of every history data point.
      #
      # @param response [Hash] A tool, bed or chamber temperature response
      # @param key [Symbol] The heater's key in the response, e.g. +:tool0+ or +:bed+
      # @return [Object] An instance of the extending class
      sig { params(response: T::Hash[Symbol, T.untyped], key: Symbol).returns(T.untyped) }
      def from_response(response, key)
        history = response[:history]&.filter_map do |point|
          reading = point[key]
          TemperatureReading.deserialize({ time: point[:time], **reading }.compact) if reading
        end

        T.unsafe(self).deserialize({ **response.fetch(key, {}), history: history }.compact)
      end
    end
  end
end
