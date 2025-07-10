# typed: true
# frozen_string_literal: true

module Octoprint
  # Common type aliases for use with auto_attr and Sorbet signatures.
  #
  # This module provides convenient type aliases for commonly used types
  # in the OctoPrint API. These can be used with auto_attr or in regular
  # Sorbet type annotations.
  #
  # @example Using with auto_attr
  #   class User
  #     include AutoInitializable
  #
  #     auto_attr :name, type: String, nilable: false
  #     auto_attr :email, type: Types::NilableString   # Alternative syntax
  #     auto_attr :tags, type: Types::StringArray
  #     auto_attr :metadata, type: Types::Hash
  #
  #     auto_initialize!
  #   end
  #
  # @example Using in Sorbet signatures
  #   sig { params(data: Types::Hash).returns(Types::NilableString) }
  #   def process_data(data)
  #     data[:name]
  #   end
  module Types
    extend T::Sig

    # A hash with symbol keys and untyped values (common for API responses)
    # @example { name: "John", age: 30, active: true }
    Hash = T::Hash[Symbol, T.untyped]

    # An array of strings
    # @example ["tag1", "tag2", "tag3"]
    StringArray = T::Array[String]

    # A nullable string (can be String or nil)
    # @example "John Doe" or nil
    NilableString = T.nilable(String)

    # A nullable integer (can be Integer or nil)
    # @example 42 or nil
    NilableInteger = T.nilable(Integer)

    # A nullable float (can be Float or nil)
    # @example 3.14 or nil
    NilableFloat = T.nilable(Float)

    # A nullable hash (can be Hash or nil)
    # @example { key: "value" } or nil
    NilableHash = T.nilable(T::Hash[Symbol, T.untyped])

    # A nullable string array (can be Array<String> or nil)
    # @example ["tag1", "tag2"] or nil
    NilableStringArray = T.nilable(T::Array[String])

    # A boolean type (true or false)
    # @example true or false
    Boolean = T.any(TrueClass, FalseClass)

    # A nullable boolean (can be Boolean or nil)
    # @example true, false, or nil
    NilableBoolean = T.nilable(T.any(TrueClass, FalseClass))

    # API Response Types
    # A typical API response hash
    # @example { data: {...}, status: "success" }
    ApiResponse = T::Hash[Symbol, T.untyped]

    # File Types
    # A file path string
    # @example "/path/to/file.gcode"
    FilePath = String

    # File size in bytes
    # @example 1048576
    FileSize = Integer

    # Time Types
    # Unix timestamp (seconds since epoch)
    # @example 1640995200
    UnixTimestamp = Integer

    # ISO 8601 formatted date string
    # @example "2023-12-31T12:00:00Z"
    Iso8601String = String

    # Network Types
    # A hostname or IP address
    # @example "octopi.local" or "192.168.1.100"
    Hostname = String

    # A port number
    # @example 80, 443, 5000
    Port = Integer

    # A URL string
    # @example "https://octopi.local/api/version"
    Url = String

    # Printer Types
    # A printer identifier
    # @example "ender3", "_default"
    PrinterId = String

    # Number of extruders
    # @example 1, 2, 4
    ExtruderCount = Integer

    # Bed temperature in Celsius
    # @example 60.0, 80.5
    BedTemperature = Float

    # Job Types
    # Job state string
    # @example "Printing", "Paused", "Operational"
    JobState = String

    # Print progress percentage (0.0 to 100.0)
    # @example 45.5, 100.0
    ProgressPercent = Float

    # Print time in seconds
    # @example 3600, 7200
    PrintTime = Integer

    # Connection Types
    # Connection state string
    # @example "Connected", "Disconnected", "Connecting"
    ConnectionState = String

    # Baud rate for serial connections
    # @example 115200, 250000, 500000
    BaudRate = Integer

    # Serial port name
    # @example "/dev/ttyUSB0", "COM3"
    SerialPort = String
  end
end
