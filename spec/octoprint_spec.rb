# frozen_string_literal: true

RSpec.describe Octoprint do
  it "has a version number" do
    expect(Octoprint::VERSION).not_to be nil
  end

  it "has a configure method" do
    expect(Octoprint).to respond_to :configure
  end
end
