# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Deprecation do
  before { described_class.reset! }

  describe ".warn_once" do
    it "warns once per name" do
      expect do
        described_class.warn_once("Thing#old", "use new")
        described_class.warn_once("Thing#old", "use new")
        described_class.warn_once("Thing#other", "use new")
      end.to output("[octoprint] Thing#old is deprecated: use new\n[octoprint] Thing#other is deprecated: use new\n")
        .to_stderr
    end
  end

  describe ".reset!" do
    it "warns again" do
      expect do
        described_class.warn_once("Thing#old", "use new")
        described_class.reset!
        described_class.warn_once("Thing#old", "use new")
      end.to output(/\A(\[octoprint\] Thing#old is deprecated: use new\n){2}\z/).to_stderr
    end
  end
end
