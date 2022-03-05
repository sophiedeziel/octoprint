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

Octoprint.configure(host: 'https://octopi.local/', api_key: 'j98G2nsJq...')

# list files
Octoprint::Files.list

# retrieve the current print job information
Octoprint::Job.current
```

To generate an app key on your Octoprint's instance, log in to it, click on the Settings button in the top menu and then go to the "Application Keys".

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### HTTP requests

This project uses VCR to record the HTTP interactions with an Octoprint's API. When you add tests, you can use existing cassettes or record your own. To set this up, first run 
`cp .env.example .env` and add your Octoprint's configuration to the newly created `.env` file. This file is ignored by git, so it is safe to edit. It will make your setup available as environment variables. VCR is configured to filter that data out of cassettes. 

Remember, you should never commit your credentials to git. With the current configuration, you should never have to.

If you need all request to pass through while developing, you can add the `:wip` flag to your tests. It will prevent cassettes from recording until you remove the flag. Remember to remove it and record all missing cassettes before you commit your changes. More information here: https://link.medium.com/QU7ZgM8P9nb

example:
```
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
