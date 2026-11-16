# typed: true
# frozen_string_literal: true

module Octoprint
  class Printer
    # Sends arbitrary commands or GCODE scripts to the printer and retrieves custom controls.
    #
    # Use with care: some commands can interfere with or even stop a running print job.
    # Requires the +CONTROL+ permission.
    #
    # @example Send a single command
    #   Octoprint::Printer::Command.send_command("M106")
    #
    # @example Send multiple commands
    #   Octoprint::Printer::Command.send_commands(["M18", "M106 S0"])
    #
    # @example Run a GCODE script template
    #   Octoprint::Printer::Command.run_script("afterPrintCancelled")
    #
    # @example List the custom controls
    #   Octoprint::Printer::Command.custom_controls.map(&:name) # => ["Fan", "Reporting"]
    #
    # @see https://docs.octoprint.org/en/master/api/printer.html#send-an-arbitrary-command-to-the-printer
    class Command < BaseResource
      resource_path("/api/printer/command")

      # Sends an arbitrary command request. Exactly one of +command+, +commands+ or +script+ must be given.
      #
      # @param command [String, nil] A single command to send
      # @param commands [Array<String>, nil] Multiple commands to send, in order
      # @param script [String, nil] The name of a GCODE script template to send
      # @param parameters [Hash, nil] Parameters to replace in the commands or to provide to the script renderer
      # @param context [Hash, nil] Additional template variables for the script renderer (only with +script+)
      #
      # @example
      #   Octoprint::Printer::Command.issue(commands: ["G91", "G1 X%(distance)s", "G90"],
      #                                     parameters: { distance: 10 })
      #
      # @return [Boolean] true on success (204 No Content)
      # @raise [ArgumentError] if not exactly one of +command+, +commands+ or +script+ is given,
      #   or if +context+ is given without +script+
      #: (
      #|   ?command: String?,
      #|   ?commands: Array[String]?,
      #|   ?script: String?,
      #|   ?parameters: Hash[(Symbol | String), untyped]?,
      #|   ?context: Hash[(Symbol | String), untyped]?
      #| ) -> untyped
      def self.issue(command: nil, commands: nil, script: nil, parameters: nil, context: nil)
        unless [command, commands, script].compact.size == 1
          raise ArgumentError, "Exactly one of command, commands or script must be provided"
        end
        raise ArgumentError, "context can only be used with script" if context && script.nil?

        post(params: { command: command, commands: commands, script: script, parameters: parameters,
                       context: context }.compact)
      end

      # Sends a single command to the printer.
      #
      # @param command [String] The command to send
      # @param parameters [Hash, nil] Parameters to replace in the command
      #
      # @example
      #   Octoprint::Printer::Command.send_command("M106")
      #
      # @example With parameters
      #   Octoprint::Printer::Command.send_command("M106 S%(speed)s", parameters: { speed: 255 })
      #
      # @return [Boolean] true on success (204 No Content)
      #: (String command, ?parameters: Hash[(Symbol | String), untyped]?) -> untyped
      def self.send_command(command, parameters: nil)
        issue(command: command, parameters: parameters)
      end

      # Sends multiple commands to the printer, in the given order.
      #
      # @param commands [Array<String>] The commands to send
      # @param parameters [Hash, nil] Parameters to replace in the commands
      #
      # @example
      #   Octoprint::Printer::Command.send_commands(["M18", "M106 S0"])
      #
      # @return [Boolean] true on success (204 No Content)
      #: (
      #|   Array[String] commands,
      #|   ?parameters: Hash[(Symbol | String), untyped]?
      #| ) -> untyped
      def self.send_commands(commands, parameters: nil)
        issue(commands: commands, parameters: parameters)
      end

      # Renders a GCODE script template and sends it to the printer.
      #
      # @param script [String] The name of the GCODE script template
      # @param parameters [Hash, nil] Parameters to provide to the script renderer
      # @param context [Hash, nil] Additional template variables to provide to the script renderer
      #
      # @example
      #   Octoprint::Printer::Command.run_script("afterPrintCancelled")
      #
      # @return [Boolean] true on success (204 No Content)
      #: (
      #|   String script,
      #|   ?parameters: Hash[(Symbol | String), untyped]?,
      #|   ?context: Hash[(Symbol | String), untyped]?
      #| ) -> untyped
      def self.run_script(script, parameters: nil, context: nil)
        issue(script: script, parameters: parameters, context: context)
      end

      # Retrieves the custom controls configured in OctoPrint's +config.yaml+.
      #
      # @example
      #   Octoprint::Printer::Command.custom_controls.each do |control|
      #     puts control.name
      #     control.children&.each { |child| puts "  #{child.name}: #{child.command}" }
      #   end
      #
      # @return [Array<Printer::CustomControl>] The custom controls
      # @see https://docs.octoprint.org/en/master/features/custom_controls.html Custom controls
      #: -> Array[CustomControl]
      def self.custom_controls
        response = fetch_resource("custom", deserialize: false)
        Array(response[:controls]).map { |control| CustomControl.deserialize(control) }
      end
    end
  end
end
