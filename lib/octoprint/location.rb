# typed: true
# frozen_string_literal: true

module Octoprint
  # The target location to which to upload the file.
  #
  # Currently only local and sdcard are supported here, with local referring to OctoPrint’s uploads folder and sdcard
  # referring to the printer’s SD card.
  #
  # Octoprint's API doc: https://docs.octoprint.org/en/master/api/files.html
  class Location < T::Enum
    enums do
      Local = new("local")
      SDCard = new("sdcard")
    end

    def to_s
      @value.to_s
    end
  end
end
