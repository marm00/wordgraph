# frozen_string_literal: true

spec.add_dependency "optparse"

RSpec.describe Wordgraph do
  it "has a version number" do
    expect(Wordgraph::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(false).to eq(true)
  end
end
