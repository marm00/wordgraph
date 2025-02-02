# frozen_string_literal: true

require "wordgraph/core"

RSpec.describe Wordgraph::Core do
  let(:examples_path) {  "spec/fixtures/examples/" }
  def sample(file_name, ext=nil)
    file_path = examples_path + "sample#{file_name}.#{ext || "txt"}"
    core = Wordgraph::Core.new(file_path)
    def core.generate_cloud _
    end
    core.process
  end

  it "process one letter" do
    expect(sample(0)).to eq({"a" => 1})
  end

  it "process multiple words" do
    expect(sample(1)).to eq({"a" => 2, "b" => 1})
  end
  
  it "treat uppercase as lowercase" do
    expect(sample(2)).to eq({"a" => 2, "b" => 1, "c" => 1})
  end

  it "ignore meaningless punctuation" do
    expect(sample(3)).to eq({"a" => 3, "b" => 3, "c" => 3})
  end

  it "keep links and csv" do
    expect(sample(4)).to eq({"a" => 1, "a,b" => 1, "b" => 1, "c.d" => 1})
  end

  it "ignore all whitespace" do
    expect(sample(5)).to eq({
      "a" => 1, "b" => 1, "c" => 1, "d" => 1, 
      "e" => 1, "f" => 1, "g" => 1, "h" => 1
    })
  end

  it "process docx file" do
    expect(sample(0, "docx")).to eq({"a" => 1, "b" => 1, "c" => 1})
  end
end