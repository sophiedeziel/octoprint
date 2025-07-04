# Claude Development Guide

This document contains important information for Claude when working on the OctoPrint gem.

## Recording VCR Cassettes for Tests

When adding new API endpoints or modifying existing ones, you may need to record new VCR cassettes for the tests. Here's how to do it:

### 1. Use the `:wip` tag
Add the `:wip` tag to your test to enable real HTTP requests:
```ruby
describe "Your new feature", vcr: { cassette_name: "files/your_feature" }, :wip do
  # Your test code here
end
```

### 2. Run the test
```bash
bundle exec rspec spec/octoprint/your_spec.rb
```

### 3. Remove `:wip` tag
Once the cassette is recorded successfully, remove the `:wip` tag so future test runs use the cassette instead of making real requests.

### Important Notes
- VCR automatically filters sensitive data:
  - `<HOST>` replaces the actual host
  - `<API_KEY>` replaces the API key
- Cassettes are stored in `spec/cassettes/`
- The `:wip` tag configuration is in `spec/spec_helper.rb`

## Running Quality Gates

Before committing, ensure your code passes all quality checks:

```bash
# Run RuboCop for linting
bundle exec rubocop

# Run Sorbet for type checking
bundle exec srb tc

# Run all tests
bundle exec rspec
```
