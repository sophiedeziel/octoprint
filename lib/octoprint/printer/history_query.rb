# typed: true
# frozen_string_literal: true

module Octoprint
  class Printer
    # Builds the +history+ and +limit+ query parameters shared by the temperature endpoints.
    #
    # @api private
    module HistoryQuery
      extend T::Sig

      private

      # @param history [Boolean] Whether to include the temperature history
      # @param limit [Integer, nil] Maximum number of history data points, only sent when +history+ is true
      # @return [Hash] The query parameters
      sig { params(history: T::Boolean, limit: T.nilable(Integer)).returns(T::Hash[Symbol, T.untyped]) }
      def history_query(history:, limit:)
        return {} unless history

        options = { history: true }
        options[:limit] = limit if limit
        options
      end
    end
  end
end
