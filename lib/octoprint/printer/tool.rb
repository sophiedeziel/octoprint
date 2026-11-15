# typed: true
# frozen_string_literal: true

module Octoprint
  class Printer
    # Tool (hotend) temperatures and commands: target and offset temperatures, tool selection,
    # extrusion and flow rate.
    #
    # Commands may only be sent while the printer is operational, and {.select_tool} and {.extrude}
    # only while it is not printing. Requires the +CONTROL+ permission for commands and +STATUS+ for {.get}.
    #
    # @example Read the tool temperatures
    #   Octoprint::Printer::Tool.get.tool(0).actual # => 214.8821
    #
    # @example Heat up the hotends
    #   Octoprint::Printer::Tool.target(tool0: 220, tool1: 205)
    #
    # @example Extrude 5mm of filament
    #   Octoprint::Printer::Tool.extrude(5)
    #
    # @see https://docs.octoprint.org/en/master/api/printer.html#issue-a-tool-command
    class Tool < BaseResource
      extend T::Sig
      extend HistoryQuery

      resource_path("/api/printer/tool")

      # Retrieves the current temperature data of all the printer's tools.
      #
      # @param history [Boolean] Whether to include the temperature history
      # @param limit [Integer, nil] Only return the last +limit+ history data points (ignored unless +history+ is true)
      #
      # @example
      #   temperature = Octoprint::Printer::Tool.get(history: true, limit: 2)
      #   temperature.tool(0).target       # => 220.0
      #   temperature.history.size         # => 2
      #
      # @return [Printer::TemperatureState] The tools' temperature state
      # @raise [Octoprint::Exceptions::ConflictError] if the printer is not operational
      sig { params(history: T::Boolean, limit: T.nilable(Integer)).returns(TemperatureState) }
      def self.get(history: false, limit: nil)
        TemperatureState.deserialize(
          fetch_resource(deserialize: false, options: history_query(history: history, limit: limit))
        )
      end

      # Issues a tool command.
      #
      # @param command [String] The command to issue: +target+, +offset+, +select+, +extrude+ or +flowrate+
      # @param options [Hash] Additional command parameters
      #
      # @example
      #   Octoprint::Printer::Tool.issue_command(command: "select", options: { tool: "tool1" })
      #
      # @return [Boolean] true on success (204 No Content)
      # @raise [Octoprint::Exceptions::BadRequestError] if the parameters are invalid
      # @raise [Octoprint::Exceptions::ConflictError] if the printer is not operational
      sig { params(command: String, options: T::Hash[Symbol, T.untyped]).returns(T.untyped) }
      def self.issue_command(command:, options: {})
        post(params: { command: command }.merge(options))
      end

      # Sets the target temperature of one or more tools. A target of 0 turns the heater off.
      #
      # @param targets [Hash{Symbol, String => Numeric}] Target temperatures keyed by +tool{n}+,
      #   or +tool+ for the currently active tool
      #
      # @example Set the temperatures of two hotends
      #   Octoprint::Printer::Tool.target(tool0: 220, tool1: 205)
      #
      # @example Set the temperature of the active hotend
      #   Octoprint::Printer::Tool.target(tool: 220)
      #
      # @return [Boolean] true on success (204 No Content)
      # @raise [Octoprint::Exceptions::BadRequestError] if a key or temperature is invalid
      # @raise [Octoprint::Exceptions::ConflictError] if the printer is not operational
      sig { params(targets: T::Hash[T.any(Symbol, String), Numeric]).returns(T.untyped) }
      def self.target(targets)
        issue_command(command: "target", options: { targets: targets })
      end

      # Sets the temperature offset of one or more tools.
      #
      # @param offsets [Hash{Symbol, String => Numeric}] Temperature offsets keyed by +tool{n}+
      #
      # @example
      #   Octoprint::Printer::Tool.offset(tool0: 10, tool1: -5)
      #
      # @return [Boolean] true on success (204 No Content)
      # @raise [Octoprint::Exceptions::BadRequestError] if a key or offset is invalid
      # @raise [Octoprint::Exceptions::ConflictError] if the printer is not operational
      sig { params(offsets: T::Hash[T.any(Symbol, String), Numeric]).returns(T.untyped) }
      def self.offset(offsets)
        issue_command(command: "offset", options: { offsets: offsets })
      end

      # Selects the printer's current tool. Sends the +select+ command.
      #
      # @param tool [String, Symbol] The tool to select, in the format +tool{n}+
      #
      # @example
      #   Octoprint::Printer::Tool.select_tool("tool1")
      #
      # @return [Boolean] true on success (204 No Content)
      # @raise [Octoprint::Exceptions::BadRequestError] if the tool is invalid
      # @raise [Octoprint::Exceptions::ConflictError] if the printer is not operational or is printing
      sig { params(tool: T.any(String, Symbol)).returns(T.untyped) }
      def self.select_tool(tool)
        issue_command(command: "select", options: { tool: tool.to_s })
      end

      # Extrudes filament from the currently selected tool. Use a negative amount to retract.
      #
      # @param amount [Numeric] The amount of filament to extrude, in mm
      # @param speed [Integer, nil] Speed in mm/min. Defaults to the profile's maximum E axis speed.
      #
      # @example Extrude 5mm
      #   Octoprint::Printer::Tool.extrude(5)
      #
      # @example Retract 3mm at 300mm/min
      #   Octoprint::Printer::Tool.extrude(-3, speed: 300)
      #
      # @return [Boolean] true on success (204 No Content)
      # @raise [Octoprint::Exceptions::BadRequestError] if the amount is invalid
      # @raise [Octoprint::Exceptions::ConflictError] if the printer is not operational or is printing
      sig { params(amount: Numeric, speed: T.nilable(Integer)).returns(T.untyped) }
      def self.extrude(amount, speed: nil)
        issue_command(command: "extrude", options: { amount: amount, speed: speed }.compact)
      end

      # Changes the flow rate factor applied to extrusion.
      #
      # @param factor [Numeric] Percentage between 75 and 125 as an integer (+75+..+125+) or float (+0.75+..+1.25+)
      #
      # @example
      #   Octoprint::Printer::Tool.flowrate(95)
      #
      # @return [Boolean] true on success (204 No Content)
      # @raise [Octoprint::Exceptions::BadRequestError] if the factor is out of range
      # @raise [Octoprint::Exceptions::ConflictError] if the printer is not operational
      sig { params(factor: Numeric).returns(T.untyped) }
      def self.flowrate(factor)
        issue_command(command: "flowrate", options: { factor: factor })
      end
    end
  end
end
