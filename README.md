# OctoPrint Ruby Gem

A comprehensive, type-safe Ruby wrapper for OctoPrint's REST API with full Sorbet integration.

## ✨ Key Features

- **🛡️ Type Safety**: Full Sorbet type annotations with compile-time error checking
- **🔥 Smart Error Handling**: HTTP status codes mapped to specific exception types
- **📦 Comprehensive API Coverage**: Files, jobs, printer state and commands, printer profiles, connection, access control, settings, timelapse, logs, system commands and more
- **🧪 Exceptional Quality**: 100% line coverage, enforced in CI
- **🎯 Multi-Printer Support**: Manage multiple OctoPrint instances with thread-safe clients
- **⚡ Modern Ruby**: Built for Ruby 3.3+ with Zeitwerk autoloading and ActiveSupport integration

## Installation

### Gemfile installation

Add this line to your application's Gemfile:

```Ruby
gem 'octoprint'
```

or run in the terminal

    bundle add octoprint


And then execute:

    bundle install

### global manual installation

    gem install octoprint

## Usage

```ruby
require 'octoprint'

# Configure globally for single printer
Octoprint.configure(host: 'https://octopi.local/', api_key: 'your_api_key')

# List files with full type safety
result = Octoprint::Files.list                   # => Octoprint::Files
result.files.first.name                          # => String (typed)
result.files.first.type_path                     # => Array<String> (typed)

# Get current job with progress tracking
job = Octoprint::Job.get                         # => Octoprint::Job
puts "#{job.information.file[:name]}: #{job.progress.completion}%" if job.progress.completion

# Upload and start a print job (location defaults to Octoprint::Location::Local)
Octoprint::Files.upload("awesome_model.gcode")
Octoprint::Files.select(filename: "awesome_model.gcode")
Octoprint::Job.start
```

Or select and start printing in one call: `Octoprint::Files.select(filename: "awesome_model.gcode", print: true)`.

To generate an app key on your Octoprint's instance, log in to it, click on the Settings button in the top menu and then go to the "Application Keys".

## 🛡️ Type Safety with Sorbet

This gem provides complete type safety with Sorbet integration:

```ruby
# All models are fully typed
job = Octoprint::Job.get
job.information.file           # => Hash | nil (typed), e.g. job.information.file[:name]
job.progress.completion        # => Float | nil (typed)
```

**Benefits:**
- **Compile-time Error Detection**: Catch errors before runtime with `srb tc`
- **IDE Integration**: Full autocomplete and type information (requires proper IDE setup, for example: ruby-lsp and sorbet plugins for VSCode)
- **Refactoring Safety**: Type-checked code changes across the entire codebase
- **Runtime Type Checking**: Optional runtime validation in development

## 🔥 Smart Error Handling

HTTP errors are automatically mapped to specific exception types for clean error flow:

```ruby
begin
  Octoprint::Files.select(filename: "missing.gcode")
rescue Octoprint::Exceptions::NotFoundError => e
  # Handle 404 errors specifically
  puts "Resource not found: #{e.message}"
rescue Octoprint::Exceptions::BadRequestError => e
  # Handle 400 errors specifically
  puts "Invalid request: #{e.message}"
rescue Octoprint::Exceptions::AuthenticationError => e
  # Handle 403 errors specifically
  puts "Authentication failed: #{e.message}"
rescue Octoprint::Exceptions::Error => e
  # Catch-all for every error raised by the gem
  puts "OctoPrint error: #{e.message}"
end
```

**Exception Types** (all under `Octoprint::Exceptions`):
- `Error` - Base class of every exception below, handy as a catch-all rescue
- `AuthenticationError` (403) - Invalid API key or permissions
- `BadRequestError` (400) - Invalid parameters or request format
- `NotFoundError` (404) - Resource doesn't exist
- `ConflictError` (409) - Resource conflicts or state issues
- `UnsupportedMediaTypeError` (415) - Invalid file format
- `InternalServerError` (500) - Server-side errors
- `UnknownError` - Fallback for unexpected responses
- `ConnectionError` - The server can't be reached (connection refused, unreachable host, ...)
- `TimeoutError` - The server didn't respond within the configured timeouts (a subclass of `ConnectionError`)
- `MissingCredentialsError` - `Octoprint::Client.new` was given a `nil` host or API key

## 📦 Comprehensive API Coverage

This gem aims to provide complete coverage of OctoPrint's REST API:

| **Category** | **Features** |
|---|---|
| **Files** | List, get, upload, delete, create folders, select/unselect, slice STL files, copy/move, download URLs |
| **Jobs** | Current job info, progress tracking, start/cancel/restart/pause/resume |
| **Printer** | Printer state, temperatures with history, print head jog/home, tool/bed/chamber temperatures, extrusion, SD card, arbitrary commands, custom controls |
| **Printer Profiles** | List, get, create, update, and delete printer profiles |
| **Connection** | Connect/disconnect printer, connection settings and options |
| **Languages** | List, upload, and delete language packs |
| **Logs** | List and delete log files, download URLs |
| **Timelapse** | List and delete timelapses, render or delete unrendered ones, change the timelapse config |
| **Access** | Users (list, add, get, update, delete, change password, user settings, API keys, current user), groups (list, add, get, update, delete), permissions (list) |
| **Settings** | Get and save settings, regenerate the API key, fetch templates, typed webcam settings |
| **System Commands** | List commands (all or by source) and execute them |
| **Wizard** | Get wizard data and finish wizards |
| **Utilities** | Test paths, URLs, server connectivity, DNS resolution, and addresses |
| **Server** | Server version (`ServerVersion`) and server status / safe mode (`ServerInformation`) |

```ruby
# File management
Octoprint::Files.upload("model.gcode", location: Octoprint::Location::Local)
Octoprint::Files.slice(filename: "model.stl", profile: { slicer: "cura" })

# Job control
job = Octoprint::Job.get
Octoprint::Job.start if job.state == "Operational"

# Printer control
printer = Octoprint::Printer.get(history: true, limit: 10)
printer.temperature.tool(0).actual        # => 214.8
Octoprint::Printer::Printhead.home(axes: %w[x y])
Octoprint::Printer::Tool.target(tool0: 220)
Octoprint::Printer::Bed.target(60)
Octoprint::Printer::Command.send_commands(["M106 S255", "M117 Hello"])

# Timelapses
Octoprint::Timelapse.get(unrendered: true).unrendered.each { |job| Octoprint::Timelapse.render(name: job.name) }
Octoprint::Timelapse.update_config(type: "timed", interval: 10, save: true)

# Printer profiles
profile = Octoprint::PrinterProfiles.create(
  profile: { id: "ender3", name: "Ender 3 Pro", model: "Ender 3 Pro" }
) # => Octoprint::PrinterProfiles::PrinterProfile

# Connection management
Octoprint::Connection.connect(port: "/dev/ttyUSB0", baudrate: 115200)
```

### Flexibility

This gem is built to offer multiple options to interact with Octoprint's apis. Depending on your use case, you can configure the gem for only one Octoprint server, or you can generate an API client to use for each server.

#### Example 1: Use in a Rails app, with a single Octoprint server

```Ruby
# config/initializers/octoprint.rb
Octoprint.configure(host: 'https://octopi.local/', api_key: 'j98G2nsJq...')

# app/controllers/printers_controller.rb
class PrintersController < ApplicationController
  def connect
    Octoprint::Connection.connect
  end
end
```

#### Example 2: Manage multiple printers in a ruby script

```Ruby
ender3 = Octoprint::Client.new(host: 'http://192.168.0.145', api_key: 'asdf')
cr10   = Octoprint::Client.new(host: 'http://192.168.0.167', api_key: 'ghjk')

files = []

ender3.use do
  files << Octoprint::Files.list
end

cr10.use do
  files << Octoprint::Files.list
end
```

#### Timeouts

By default, the client waits up to 2 seconds for the connection to open and up to 3 seconds for each read or write, so an offline printer can't hang your app. Pass `open_timeout:` and `timeout:` (in seconds) to `Octoprint.configure` or `Octoprint::Client.new` to change them. Raise `timeout:` for large file uploads. A `nil` `timeout:` falls back to the HTTP adapter's default (60 seconds for Net::HTTP), and a `nil` `open_timeout:` falls back to `timeout:`.

```Ruby
client = Octoprint::Client.new(host: 'http://192.168.0.145', api_key: 'asdf', open_timeout: 1, timeout: 30)

begin
  client.use { Octoprint::Job.get }
rescue Octoprint::Exceptions::ConnectionError # also rescues Octoprint::Exceptions::TimeoutError
  puts "Printer is offline"
end
```

#### Webcam settings

`Octoprint::Settings.webcam` returns the webcam settings as a typed object. It supports the multi-webcam settings of OctoPrint 1.9+ (using the default webcam) and the legacy settings of older versions.

```Ruby
webcam = Octoprint::Settings.webcam # => Octoprint::Settings::Webcam
webcam.enabled                      # => true
webcam.stream_url                   # => "/webcam/?action=stream" (can be relative to the host)
webcam.snapshot_url                 # => "http://localhost:8080/?action=snapshot"

# Already have the settings? Skip the extra request
Octoprint::Settings::Webcam.from_settings(Octoprint::Settings.get)
```

## 🧪 Testing & Code Quality

This gem maintains quality standards:

### Test Coverage
- **100% Line Coverage**
- **API calls recorded with VCR**: Real API interactions recorded and replayed, ensuring tests ran in real conditions while keeping CI simple and fast.

### Code Quality
- **RuboCop**
- **Sorbet Type Checking**

```bash
# Run all quality checks
bundle exec rspec
bundle exec rubocop
bundle exec srb tc
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Testing with Octoprint

You can test with an existing octoprint instance that you have, or you can setup a test [octoprint](https://octoprint.org/download/) instance using the [virtual printer plugin](https://docs.octoprint.org/en/main/bundledplugins/virtual_printer.html).

There are many ways you can set that up; using Docker, pip on your local machine or use a raspberry pi, and many more options. Pick the one that works for you.

As a convenience, here is the test setup I use, using Docker:

```bash
brew install --cask docker # Install docker on a mac, if not already installed.

# Once Docker is started
docker run -d -p 5050:80 --name octoprint octoprint/octoprint
```

Then, open http://localhost:5050/ and go through the setup wizard.

Enable the virtual printer plugin.

Go to Settings > Application keys and generate a new API key.

Set the `OCTOPRINT_HOST` and `OCTOPRINT_API_KEY` environment variables in your preferred way. For convenience, there is an example `.env` that you can copy. Some development tools will recognize that file and automatically load its content as environment variables. Copy it by entering `cp .env.example .env` in your terminal and add your Octoprint's configuration to the newly created `.env` file. This file is ignored by git, so it is safe to edit. VCR is configured to filter that data out of cassettes.

Remember, you should never commit your credentials to git. With the current configuration, you should never have to.

### Recorded HTTP requests for the test suite

This project uses VCR to record the HTTP interactions with an Octoprint's API. When you add tests, you can use existing cassettes or record new ones. You should never edit the cassettes manually. You can delete the files and re-record them as you need.

If you need all request to pass through while developing, you can add the `:wip` flag to your tests. It will prevent cassettes from recording until you remove the flag. Remember to remove it and record all missing cassettes before you commit your changes. More information here: https://link.medium.com/QU7ZgM8P9nb

example:
```Ruby
    it "calls the API", :wip, vcr: {cassette_name: '/currentuser'} do
      result = Octoprint::Access::User.current

      expect(result).to be_a Octoprint::Access::User
      expect(result.name).to eq 'sophie'
    end
```

It is preferable to have the test setup and teardown making all the required operations so deleting all cassettes to re-record them results in a successful full run, in any order of the tests.

For example: if a file is required on the octoprint instance in order to make an API call referencing that file, the test setup should upload it.

However, it is not realistic to apply this strictly, some exceptions exist. It is not recommended to delete all cassettes to record them again. Only re-record new cassettes if strictly needed.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sophiedeziel/octoprint. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/sophiedeziel/octoprint/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Octoprint project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/sophiedeziel/octoprint/blob/main/CODE_OF_CONDUCT.md).
