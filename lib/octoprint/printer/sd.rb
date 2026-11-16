# typed: true
# frozen_string_literal: true

module Octoprint
  class Printer # rubocop:disable Style/Documentation -- documented in printer.rb
    # Deprecated alias of {Printer::Storage}: OctoPrint 2.0 renamed the printer's SD card to printer storage.
    #
    # It is the same class, so existing code keeps working with both API versions. Referencing it prints a
    # deprecation warning once (see {Deprecation}). This file is excluded from eager loading, so the warning only
    # appears when something uses the constant.
    #
    # @deprecated Use {Printer::Storage} instead.
    #
    # @example Before
    #   Octoprint::Printer::Sd.get.ready # => true
    #
    # @example After
    #   Octoprint::Printer::Storage.get.ready # => true
    Sd = Storage

    Deprecation.warn_once("Printer::Sd", "use Printer::Storage")
  end
end
