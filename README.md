# OctoPrint Ruby Gem

A comprehensive, type-safe Ruby wrapper for OctoPrint's REST API with full Sorbet integration.

## ✨ Key Features

- **🛡️ Type Safety**: Full Sorbet type annotations with compile-time error checking
- **🔥 Smart Error Handling**: HTTP status codes mapped to specific exception types
- **📦 Comprehensive API Coverage**: Support for Files, Jobs, Printer Profiles, Connections, Logs, and more
- **🧪 Exceptional Quality**: 100% test coverage with 464 test examples and 0 failures
- **🎯 Multi-Printer Support**: Manage multiple OctoPrint instances with thread-safe clients
- **⚡ Modern Ruby**: Built for Ruby 3.2+ with Zeitwerk autoloading and ActiveSupport integration

## Installation

Add this line to your application's Gemfile:

```Ruby
gem 'octoprint'
```

or
    $ bundle add octoprint


And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install octoprint

## Usage

```ruby
require 'octoprint'

# Configure globally for single printer
Octoprint.configure(host: 'https://octopi.local/', api_key: 'your_api_key')

# List files with full type safety
files = Octoprint::Files.list                    # => Array<Octoprint::File>
files.first.name                                 # => String (typed)
files.first.type_path                            # => Array<String> (typed)

# Get current job with progress tracking
job = Octoprint::Job.current                     # => Octoprint::Job
puts "#{job.file.name}: #{job.progress.percent}%" if job.progress.percent

# Upload and start a print job
Octoprint::Files.upload("awesome_model.gcode", "local")
Octoprint::Files.select("local", "awesome_model.gcode")
Octoprint::Job.start
```

To generate an app key on your Octoprint's instance, log in to it, click on the Settings button in the top menu and then go to the "Application Keys".

## 🛡️ Type Safety with Sorbet

This gem provides complete type safety with Sorbet integration:

```ruby
# All models are fully typed
job = Octoprint::Job.current
job.file.name         # => String (typed)
job.progress.percent  # => Float | nil (typed)
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
  Octoprint::Files.upload(file_path, invalid_target)
rescue Octoprint::BadRequestError => e
  # Handle 400 errors specifically
  puts "Invalid request: #{e.message}"
rescue Octoprint::AuthenticationError => e
  # Handle 403 errors specifically
  puts "Authentication failed: #{e.message}"
rescue Octoprint::NotFoundError => e
  # Handle 404 errors specifically
  puts "Resource not found: #{e.message}"
end
```

**Exception Types:**
- `AuthenticationError` (403) - Invalid API key or permissions
- `BadRequestError` (400) - Invalid parameters or request format
- `NotFoundError` (404) - Resource doesn't exist
- `ConflictError` (409) - Resource conflicts or state issues
- `UnsupportedMediaTypeError` (415) - Invalid file format
- `InternalServerError` (500) - Server-side errors
- `UnknownError` - Fallback for unexpected responses

## 📦 Comprehensive API Coverage

This gem aims to provide complete coverage of OctoPrint's REST API:

| **Category** | **Features** |
|---|---|
| **Files** | Upload, download, create folders, select/unselect, slice STL files, copy/move |
| **Jobs** | Current job info, progress tracking, start/stop/pause operations |
| **Printer Profiles** | Create, update, delete, and manage printer configurations |
| **Connection** | Connect/disconnect printer, connection settings and options |
| **Languages** | Upload, manage, and delete language packs |
| **Logs** | List, view, and manage OctoPrint log files |
| **Utilities** | Test paths, URLs, addresses, and server connectivity |
| **Server** | Get server version and system information |

```ruby
# File management
Octoprint::Files.upload("model.gcode", "local")
Octoprint::Files.slice("model.stl", slicer: "cura")

# Job control
job = Octoprint::Job.current
Octoprint::Job.start if job.state == "ready"

# Printer profiles
profile = Octoprint::PrinterProfile.create(
  id: "ender3",
  name: "Ender 3 Pro",
  model: "Ender 3 Pro"
)

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

#### Example 2: Manage multiplie printers in a ruby script

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

## 🧪 Testing & Code Quality

This gem maintains exceptional quality standards:

### Test Coverage
- **100% Line Coverage**: 718/718 lines covered
- **VCR Integration**: Real API interactions recorded and replayed, ensuring tests ran in real conditions
- **Sensitive Data Protection**: Automatically filters hosts and API keys

### Code Quality
- **RuboCop Clean**: 0 offenses across 70 files
- **Sorbet Type Checking**: All files pass `srb tc` with 0 errors
- **Modern Ruby Standards**: Built for Ruby 3.2+ with best practices

```bash
# Run all quality checks
bundle exec rspec
bundle exec rubocop
bundle exec srb tc
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### HTTP requests

This project uses VCR to record the HTTP interactions with an Octoprint's API. When you add tests, you can use existing cassettes or record new ones. You should never edit the cassettes manually. You can delete the files and re-record them as you need.

To set up recording with actual HTTP requests, first set the `OCTOPRINT_HOST` and `OCTOPRINT_API_KEY` environment variables in your prefered way. For convenience, there is an example `.env` that you can copy. Some development tools will recognize that file and automaticaaly load it's content as environment variables. Copy it by entering `cp .env.example .env` in your terminal and add your Octoprint's configuration to the newly created `.env` file. This file is ignored by git, so it is safe to edit. VCR is configured to filter that data out of cassettes.

Remember, you should never commit your credentials to git. With the current configuration, you should never have to.

If you need all request to pass through while developing, you can add the `:wip` flag to your tests. It will prevent cassettes from recording until you remove the flag. Remember to remove it and record all missing cassettes before you commit your changes. More information here: https://link.medium.com/QU7ZgM8P9nb

example:
```Ruby
    it "calls the API", :wip, vcr: {cassette_name: '/currentuser'} do
      result = Octoprint.User.current

      expect(result).to be_a Octoprint::User
      expect(result.name).to eq 'sophie'
    end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sophiedeziel/octoprint. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/sophiedeziel/octoprint/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Octoprint project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/sophiedeziel/octoprint/blob/main/CODE_OF_CONDUCT.md).
