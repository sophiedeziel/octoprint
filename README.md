# Octoprint

This gem is a Ruby wrapper around Octoprint's REST API.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'octoprint'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install octoprint

## Usage

This gem is still under development. The code below is how I plan to make this gem work. It does not work yet.

```
require 'octoprint'

Octoprint.configure(uri: 'https://octopi.local/', api_key: 'j98G2nsJq...')

# list files
Octoprint::Files.list

# retrieve the current print job information
Octoprint::Job.current
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sophiedeziel/octoprint. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/sophiedeziel/octoprint/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Octoprint project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/sophiedeziel/octoprint/blob/main/CODE_OF_CONDUCT.md).
