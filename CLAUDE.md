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
- You may have to delete cassettes if they don't contain the appropriate response, in order to re-record them
- You may have to use `curl` to prepare for the tests to run in the right conditions
    - For example, if a test deletes a file on the server, you have to upload it first so it can be deleted.
- The `:wip` tag configuration is in `spec/spec_helper.rb`

## Running Quality Gates

Before committing, ensure your code passes all quality checks:

```bash
# Run RuboCop for linting
bundle exec rubocop

# Run Sorbet for type checking
bundle exec srb tc

# Run all tests with coverage report
bundle exec rspec

# Check the RBIs shipped in the gem match the signatures and auto_attr readers
bundle exec rake rbi:check

# Check YARD documentation coverage (should stay at 100%)
bundle exec yard stats --list-undoc
```

## Type Signatures (RBS comments)

Method signatures are inline RBS comments that Sorbet checks statically. They don't run at runtime, which is on purpose: the gem does no runtime type checking in production.

- Write `#: (String, ?force: bool) -> Files` directly above the `def`. Use `#|` to continue a long signature over several lines. Don't use `sig { ... }` blocks or `extend T::Sig`.
- Keep the YARD doc comment directly above the `#:` line with no blank line between them. `.yard/rbs_comments.rb` strips the signature out of the generated docs.
- After changing a public signature or an `auto_attr`, run `bin/tapioca dsl` and then `bundle exec rake rbi:export` to regenerate `rbi/`. It holds the RBS signatures exported by Spoom (`rbi/octoprint.rbi`) and a copy of the Tapioca DSL RBIs for `auto_attr` readers (`rbi/octoprint/**`), with superclasses added so the files merge without conflicts. The gem ships this folder so Tapioca can type the gem in apps that use Sorbet, and CI fails when it's out of date.
- `bundle exec spoom srb sigs translate` converts `sig` blocks to RBS comments if you paste in old-style code.

## Code Coverage

The project uses SimpleCov to track test coverage. Coverage reports are generated automatically when running tests and saved to `coverage/index.html`.

- **Minimum coverage threshold**: 90%
- **Current coverage**: 100.0% (1448/1448 lines covered) - Outstanding coverage achieved!
- **Total test examples**: 1209 examples, 0 failures
- **Coverage groups**: Core, Resources, Files, Libraries

The coverage report excludes:
- Test files (`/spec/`)
- Vendor files (`/vendor/`)

To view the coverage report, open `coverage/index.html` in your browser after running tests.

** Important ** Always run the full test suite to get the actual code coverage.
