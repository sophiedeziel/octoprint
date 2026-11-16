# typed: true
# frozen_string_literal: true

module Octoprint
  class Settings
    module Legacy
      # Moves the 1.x `serial` settings to their OctoPrint 2.0 places, and back for updates.
      #
      # OctoPrint 2.0 replaced the serial settings by printer connectors. Its settings API returns:
      # - `printer_connection.autoconnect` (1.x `serial.autoconnect`)
      # - `feature.notify_suppressed_commands` (1.x `serial.notify_suppressed_commands`)
      # - the serial connector plugin's settings under `plugins.serial_connector`, with nested `timeout`,
      #   `max_communication_timeouts` and `capabilities` sections, `blocklisted_ports` for `blacklisted_ports`,
      #   and `error_handling`/`send_checksum` choices for the 1.x `disconnect_on_errors`,
      #   `ignore_errors_from_firmware`, `always_send_checksum` and `never_send_checksum` flags.
      #
      # The mapping is the one OctoPrint 2.0 uses to answer 1.x clients. The 1.x settings it doesn't map (`port`,
      # `baudrate`, `port_options`, `baudrate_options`, and settings 2.0 dropped) stay under
      # `plugins.serial_connector` with their 1.x names, so they remain reachable.
      module Serial
        # Settings with the same name in 1.x `serial` and 2.0 `plugins.serial_connector`
        SAME_NAME = %w[
          port baudrate portOptions baudrateOptions exclusive lowLatency log additionalPorts additionalBaudrates
          longRunningCommands checksumRequiringCommands blockedCommands ignoredCommands pausingCommands
          sdCancelCommand emergencyCommands helloCommand triggerOkForM29 logPositionOnPause logPositionOnCancel
          abortHeatupOnCancel supportResendsWithoutOk waitToLoadSdFileList sendChecksumWithUnknownCommands
          unknownCommandsNeedAck sdRelativePath sdAlwaysAvailable sdLowerCase repetierTargetTemp
          externalHeatupDetection firmwareDetection blockWhileDwelling useParityWorkaround sanityCheckTools
          sendM112OnError disableSdPrintingDetection ackMax resendRatioThreshold resendRatioStart ignoreEmptyPorts
          encoding enableShutdownActionCommand
        ].freeze

        # 1.x `timeout<Name>` settings, 2.0 `timeout.<name>`
        TIMEOUTS = %w[
          connection detectionFirst detectionConsecutive communication communicationBusy temperature
          temperatureTargetSet temperatureAutoreport sdStatus sdStatusAutoreport posAutoreport
          baudrateDetectionPause positionLogWait
        ].freeze

        # 1.x `maxTimeouts<Name>` settings, 2.0 `maxCommunicationTimeouts.<name>`
        MAX_TIMEOUTS = %w[idle printing long].freeze

        # 1.x `cap<Name>` settings and their 2.0 `capabilities` name
        CAPABILITIES = {
          "AutoreportTemp" => "autoreport_temp",
          "AutoreportSdStatus" => "autoreport_sdstatus",
          "AutoreportPos" => "autoreport_pos",
          "BusyProtocol" => "busy_protocol",
          "EmergencyParser" => "emergency_parser",
          "ExtendedM20" => "extended_m20",
          "LfnWrite" => "lfn_write"
        }.freeze

        # 1.x `serial` setting => path under 2.0 `plugins.serial_connector`, as the server spells them
        PATHS = {
          **SAME_NAME.to_h { |name| [name, [name]] },
          **TIMEOUTS.to_h { |name| ["timeout#{name.upcase_first}", ["timeout", name]] },
          **MAX_TIMEOUTS.to_h { |name| ["maxTimeouts#{name.capitalize}", ["maxCommunicationTimeouts", name]] },
          **CAPABILITIES.to_h { |name, capability| ["cap#{name}", ["capabilities", capability]] },
          "blacklistedPorts" => %w[blocklistedPorts],
          "blacklistedBaudrates" => %w[blocklistedBaudrates],
          "waitForStart" => %w[waitForStartOnConnect]
        }.freeze

        # 2.0 settings that 1.x stores as flags: 2.0 name => [{ 2.0 value => 1.x flag }, value when no flag is set]
        CHOICES = {
          "errorHandling" => [{ "disconnect" => "disconnectOnErrors", "ignore" => "ignoreErrorsFromFirmware" },
                              "cancel"],
          "sendChecksum" => [{ "always" => "alwaysSendChecksum", "never" => "neverSendChecksum" }, "print"]
        }.freeze

        # {PATHS} with the snake_case Symbol keys of parsed responses
        RESPONSE_PATHS = PATHS.to_h { |name, path| [name.underscore.to_sym, path.map { |key| key.underscore.to_sym }] }
                              .freeze

        # {PATHS} with the Symbol keys of request bodies
        REQUEST_PATHS = PATHS.to_h { |name, path| [name.to_sym, path.map(&:to_sym)] }.freeze

        class << self
          # Moves the `serial` settings of a parsed 1.x response to their 2.0 places
          #
          # @param settings [Hash] The parsed settings, modified in place
          # @return [Hash] The settings
          #: (Hash[Symbol, untyped]) -> Hash[Symbol, untyped]
          def from_legacy(settings)
            serial = settings.delete(:serial)
            return settings unless serial.is_a?(Hash)

            serial = serial.dup
            settings[:printer_connection] = { autoconnect: serial.delete(:autoconnect) }
            move_notify_suppressed_commands(settings, serial)
            plugins = settings[:plugins] ||= {}
            # A 2.0 server answering a 1.x client also sends the 2.0 settings: they win
            plugins[:serial_connector] = connector_from_legacy(serial).deep_merge(plugins[:serial_connector] || {})
            settings
          end

          # Moves 2.0 `printerConnection`, `feature.notifySuppressedCommands` and `plugins.serial_connector` updates
          # to the 1.x `serial` settings. Unknown connector settings stay where they are.
          #
          # @param settings [Hash] The settings update, modified in place
          # @return [Hash] The settings update
          #: (Hash[Symbol, untyped]) -> Hash[Symbol, untyped]
          def to_legacy(settings)
            serial = {} #: Hash[Symbol, untyped]
            HashPath.take(settings, %i[printerConnection autoconnect]) { |value| serial[:autoconnect] = value }
            HashPath.take(settings, %i[feature notifySuppressedCommands]) do |value|
              serial[:notifySuppressedCommands] = value
            end
            connector_to_legacy(settings, serial)

            settings[:serial] = (settings[:serial] || {}).merge(serial) unless serial.empty?
            settings
          end

          private

          # A 2.0 server answering a 1.x client sends `feature.notifySuppressedCommands` too: it wins
          #
          #: (Hash[Symbol, untyped], Hash[Symbol, untyped]) -> void
          def move_notify_suppressed_commands(settings, serial)
            feature = settings[:feature] ||= {}
            value = serial.delete(:notify_suppressed_commands)
            feature[:notify_suppressed_commands] = value unless feature.key?(:notify_suppressed_commands)
          end

          #: (Hash[Symbol, untyped]) -> Hash[Symbol, untyped]
          def connector_from_legacy(serial)
            connector = {} #: Hash[Symbol, untyped]
            RESPONSE_PATHS.each do |name, path|
              HashPath.put(connector, path, serial.delete(name)) if serial.key?(name)
            end
            choices_from_legacy(serial, connector)

            connector.merge(serial)
          end

          #: (Hash[Symbol, untyped], Hash[Symbol, untyped]) -> void
          def choices_from_legacy(serial, connector)
            CHOICES.each do |name, (flags, default)|
              values = flags.transform_values { |flag| serial.delete(flag.underscore.to_sym) }
              connector[name.underscore.to_sym] = choice(values, default)
            end
          end

          #: (Hash[Symbol, untyped], Hash[Symbol, untyped]) -> void
          def connector_to_legacy(settings, serial)
            REQUEST_PATHS.each do |name, path|
              HashPath.take(settings, [:plugins, :serial_connector, *path]) { |value| serial[name] = value }
            end
            CHOICES.each do |name, (flags, _default)|
              HashPath.take(settings, [:plugins, :serial_connector, name.to_sym]) do |value|
                flags.each { |choice, flag| serial[flag.to_sym] = (value == choice) }
              end
            end
          end

          # The 2.0 value selected by 1.x flags. nil when the flags are hidden (permission filtering).
          #
          #: (Hash[String, untyped], String) -> String?
          def choice(values, default)
            return if values.values.all?(&:nil?)

            values.key(true) || default
          end
        end
      end
    end
  end
end
