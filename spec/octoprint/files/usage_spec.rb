# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Files::Usage do
  describe "#initialize" do
    it "creates usage with free and total space" do
      usage = described_class.new(free: 491_531_599_872, total: 994_662_584_320)

      expect(usage.free).to eq(491_531_599_872)
      expect(usage.total).to eq(994_662_584_320)
    end

    it "handles optional attributes" do
      usage = described_class.new

      expect(usage.free).to be_nil
      expect(usage.total).to be_nil
    end

    it "accepts only free space" do
      usage = described_class.new(free: 1000)

      expect(usage.free).to eq(1000)
      expect(usage.total).to be_nil
    end
  end

  describe "inheritance and modules" do
    it "includes AutoInitializable" do
      expect(described_class.included_modules).to include(Octoprint::AutoInitializable)
    end

    it "has auto_attrs defined" do
      expect(described_class.auto_attrs).to include(:free, :total)
    end
  end
end
