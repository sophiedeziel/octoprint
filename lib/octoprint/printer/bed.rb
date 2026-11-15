# typed: true
# frozen_string_literal: true

module Octoprint
  class Printer
    # Heated bed temperature and commands.
    #
    # Only available if the selected printer profile has a heated bed, otherwise every request
    # raises {Octoprint::Exceptions::ConflictError}. Requires the +CONTROL+ permission for commands
    # and +STATUS+ for {.temperature}.
    #
    # @example Read the bed temperature
    #   bed = Octoprint::Printer::Bed.temperature
    #   puts "#{bed.actual}°C / #{bed.target}°C"
    #
    # @example Include the last two history readings
    #   Octoprint::Printer::Bed.temperature(history: true, limit: 2).history.map(&:actual) # => [50.221, 49.1123]
    #
    # @example Heat the bed to 75°C
    #   Octoprint::Printer::Bed.target(75)
    #
    # @example Set a -5°C offset
    #   Octoprint::Printer::Bed.offset(-5)
    #
    # @see https://docs.octoprint.org/en/master/api/printer.html#issue-a-bed-command
    class Bed < BaseResource
      include Heater

      resource_path("/api/printer/bed")
    end
  end
end
