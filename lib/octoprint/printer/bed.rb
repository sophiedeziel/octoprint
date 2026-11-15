# typed: true
# frozen_string_literal: true

module Octoprint
  class Printer
    # Heated bed temperature and commands.
    #
    # Only available if the selected printer profile has a heated bed, otherwise every request
    # raises {Octoprint::Exceptions::ConflictError}. Requires the +CONTROL+ permission for commands
    # and +STATUS+ for {.get}.
    #
    # @example Read the bed temperature
    #   bed = Octoprint::Printer::Bed.get.bed
    #   puts "#{bed.actual}°C / #{bed.target}°C"
    #
    # @example Include the last two history data points
    #   Octoprint::Printer::Bed.get(history: true, limit: 2).history
    #
    # @example Heat the bed to 75°C
    #   Octoprint::Printer::Bed.target(75)
    #
    # @example Set a -5°C offset
    #   Octoprint::Printer::Bed.offset(-5)
    #
    # @see https://docs.octoprint.org/en/master/api/printer.html#issue-a-bed-command
    class Bed < Heater
      resource_path("/api/printer/bed")
    end
  end
end
