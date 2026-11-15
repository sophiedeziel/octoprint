# typed: true
# frozen_string_literal: true

module Octoprint
  class Printer
    # Heated chamber temperature and commands.
    #
    # Only available if the selected printer profile has a heated chamber, otherwise every request
    # raises {Octoprint::Exceptions::ConflictError}. Requires the +CONTROL+ permission for commands
    # and +STATUS+ for {.temperature}.
    #
    # @example Read the chamber temperature
    #   chamber = Octoprint::Printer::Chamber.temperature
    #   puts "#{chamber.actual}°C / #{chamber.target}°C"
    #
    # @example Heat the chamber to 50°C
    #   Octoprint::Printer::Chamber.target(50)
    #
    # @example Set a -5°C offset
    #   Octoprint::Printer::Chamber.offset(-5)
    #
    # @see https://docs.octoprint.org/en/master/api/printer.html#issue-a-chamber-command
    class Chamber < BaseResource
      include Heater

      resource_path("/api/printer/chamber")
    end
  end
end
