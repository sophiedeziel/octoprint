# typed: true
# frozen_string_literal: true

module Octoprint
  # A file storage on the server.
  #
  # - `Local`: OctoPrint's uploads folder.
  # - `Printer`: the printer's own storage, usually its SD card. OctoPrint 2.0 calls it `printer`; OctoPrint 1.x
  #   calls it `sdcard`. The gem always uses `printer`, and translates it for the 1.x API (see {Files::Legacy}).
  #
  # @example
  #   Octoprint::Files.list(location: Octoprint::Location::Printer)
  #
  # Octoprint's API doc: https://docs.octoprint.org/en/master/api/files.html
  class Location < T::Enum
    enums do
      Local = new("local")
      Printer = new("printer")
    end

    # The name OctoPrint 1.x uses for the {Printer} storage
    LEGACY_PRINTER = "sdcard"

    # @deprecated Use {Printer}. OctoPrint 2.0 renamed the `sdcard` storage to `printer`. Same value as {Printer}.
    SDCard = Printer
    deprecate_constant :SDCard

    # @return [String] The location as used in API paths ("local" or "printer")
    #: -> String
    def to_s
      serialize.to_s
    end
  end
end
