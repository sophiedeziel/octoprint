# Claude Development Guide

This document contains important information for Claude when working on the OctoPrint gem.

## Recording VCR Cassettes for Tests

When adding new API endpoints or modifying existing ones, you may need to record new VCR cassettes for the tests. Never hand-write cassettes.

### Servers

The specs know two OctoPrint servers. Configure them in `.env` (see `.env.example`):

| Server | Env vars | Placeholders in cassettes | Cassette folder |
|---|---|---|---|
| 1.11 (default) | `OCTOPRINT_HOST_1_11`, `OCTOPRINT_API_KEY_1_11` (fallback: `OCTOPRINT_HOST`, `OCTOPRINT_API_KEY`) | `<HOST>`, `<API_KEY>` | `spec/cassettes/<name>.yml` |
| 2.0 | `OCTOPRINT_HOST_2_0`, `OCTOPRINT_API_KEY_2_0` | `<HOST_2_0>`, `<API_KEY_2_0>` | `spec/cassettes/2_0/<name>.yml` |

Use a user or application API key for 2.0: it no longer generates a global API key. The version support lives in `spec/support/octoprint_versions.rb`.

### 1. Add a temporary `record: :once`
```ruby
describe "Your new feature", vcr: { cassette_name: "files/your_feature", record: :once } do
  # Your test code here
end
```

### 2. Run the test
```bash
bundle exec rspec spec/integration/your_spec.rb
```

### 3. Remove `record: :once`
Once the cassette is recorded, remove it so future runs replay the cassette (the default is `record: :none`).

### Recording against OctoPrint 2.0

Tag a group with `octoprint: "2.0"` to talk to the 2.0 server and replay from `spec/cassettes/2_0/`. VCR turns the dot in `2.0` into an underscore, so keep the same `cassette_name` as the 1.11 spec:

```ruby
describe ".get", octoprint: "2.0", vcr: { cassette_name: "server_version/get" } do
  include_context "with default Octoprint config" # host and api_key of the tagged server
  use_octoprint_server
end
```

To run the same expectations against every supported server, use `on_octoprint_versions`. It defines one context per version, each tagged with `octoprint:`, and yields the version:

```ruby
on_octoprint_versions do |version|
  describe ".get", vcr: { cassette_name: "server_version/get_by_version" } do
    use_octoprint_server
    its(:server) { is_expected.to eq({ "1.11" => "1.11.8", "2.0" => "2.0.0rc7" }.fetch(version)) }
  end
end
```

A group tagged with a non-default version must give an explicit `cassette_name`.

### Important Notes
- VCR filters sensitive data with the placeholders above, plus `<LOGIN_PASSWORD>`, session cookies and session keys
- You may have to delete cassettes if they don't contain the appropriate response, in order to re-record them
- You may have to use `curl` to prepare for the tests to run in the right conditions
    - For example, if a test deletes a file on the server, you have to upload it first so it can be deleted.
- The `:wip` tag turns VCR **off** (real requests, nothing recorded). Use it to debug against a live server, not to record. Its configuration is in `spec/spec_helper.rb`

## OctoPrint API versions (1.11 and 2.0)

The gem talks to OctoPrint 1.11.x and 2.0.x servers. Each `Octoprint::Client` picks its API with `api_version:`: `"1.11"` (default, no header), `"2.0"` (sends `X-OctoPrint-Api-Version: 2.0.0`) or `:auto` (one `GET /api/version` per client, then the latest API both sides support). See `lib/octoprint/api_version.rb` and issue #265.

**Models follow the 2.0 response shapes.** When the client speaks the 1.x API, a resource whose 1.x requests or responses differ converts them with a legacy converter:

- Put it in `lib/octoprint/<resource>/legacy.rb` as `Octoprint::<Resource>::Legacy` (e.g. `Octoprint::Connection::Legacy`, `Octoprint::Printer::Storage::Legacy`). `BaseResource` finds it by name, and it isn't inherited by subclasses. Don't touch `BaseResource` to add one.
- `extend LegacyConverter` and override what differs. Both methods default to returning their input:
  - `self.to_request(request)` gets the 2.0-style `ApiRequest` (`http_method`, `path`, `query`, `body`, `headers`, `options`) and returns the 1.x request to send. Use `request.with(path: ...)`.
  - `self.from_response(response, request)` gets the parsed 1.x response and the **original** 2.0-style request, and returns the response in the 2.0 shape. A 204 response is `true`.
- Converters only run for requests made with `fetch_resource`, `post`, `put`, `patch` and `delete`. A resource that calls `client.request` directly (e.g. `Access::Users`) bypasses them.
- Never branch on the version inside a resource (`if client.api_version >= ...`). Put the 1.x differences in the converter.
- Features that only exist in the 2.0 API go in `ApiVersion::FEATURES`. Call `require_feature!(:feature)` in the resource method before the request, so a 1.x client gets `Exceptions::UnsupportedFeatureError` without reaching the server. When a 1.x equivalent exists, convert to it instead of raising.
- Test both: unit-test the converter with hashes taken from recorded cassettes, and run the integration specs against both servers with `on_octoprint_versions`. The `octoprint:` metadata also sets the client's `api_version:` (via `use_octoprint_server`); tag a group with `api_version: "1.11"` to talk to the 2.0 server without the header.

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
- **Current coverage**: 100.0% (1557/1557 lines covered) - Outstanding coverage achieved!
- **Total test examples**: 1305 examples, 0 failures
- **Coverage groups**: Core, Resources, Files, Libraries

The coverage report excludes:
- Test files (`/spec/`)
- Vendor files (`/vendor/`)

To view the coverage report, open `coverage/index.html` in your browser after running tests.

** Important ** Always run the full test suite to get the actual code coverage.
