# typed: true
# frozen_string_literal: true

require "open3"

# Octoprint::Printer::Sd warns when it's first referenced, so this spec only references it inside examples.
RSpec.describe "Octoprint::Printer::Sd" do
  let(:deprecation) { "[octoprint] Printer::Sd is deprecated: use Printer::Storage\n" }

  # The alias, without the warning printed when an example references it first
  def sd_alias
    stderr = $stderr
    $stderr = StringIO.new
    Octoprint::Printer::Sd
  ensure
    $stderr = stderr
  end

  it "is an alias of Printer::Storage" do
    expect(sd_alias).to be(Octoprint::Printer::Storage)
  end

  it "uses the printer storage API" do
    expect(sd_alias.instance_variable_get(:@path)).to eq("/api/printer/storage")
    expect(sd_alias.legacy_converter).to be(Octoprint::Printer::Storage::Legacy)
  end

  it "deserializes the storage state" do
    sd = sd_alias.deserialize({ ready: true })

    expect(sd).to be_a(Octoprint::Printer::Storage)
    expect(sd.ready).to be(true)
  end

  # In a separate process: this one may have loaded the alias already
  describe "loading" do
    def run_ruby(script)
      lib = File.expand_path("../../../lib", __dir__)
      Open3.capture3(RbConfig.ruby, "-I", lib, "-e", "require 'octoprint'; #{script}")
    end

    it "isn't eager loaded, so the warning only appears when it's used" do
      _stdout, stderr, status = run_ruby("Zeitwerk::Loader.eager_load_all")

      expect(status).to be_success
      expect(stderr).not_to include("deprecated")
    end

    it "warns once, the first time it's referenced" do
      stdout, stderr, status = run_ruby("Octoprint::Printer::Sd; Octoprint::Printer::Sd; print Octoprint::Printer::Sd")

      expect(status).to be_success
      expect(stdout).to eq("Octoprint::Printer::Storage")
      expect(stderr.scan(deprecation).size).to eq(1)
    end
  end
end
