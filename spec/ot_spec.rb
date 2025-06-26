# frozen_string_literal: true

require "ot"

RSpec.describe OT do
  it "has a version number" do
    expect(OT::VERSION).not_to be nil
  end

  describe ".simple_ot" do
    it "performs 1-out-of-2 oblivious transfer" do
      message0 = "Secret message 0"
      message1 = "Secret message 1"
      choice = 1

      result = OT.simple_ot(message0, message1, choice)
      expect(result).to eq(message1)
    end
  end

  describe ".extension" do
    it "performs OT extension for multiple message pairs" do
      message_pairs = [
        ["Message 0 for OT 0", "Message 1 for OT 0"],
        ["Message 0 for OT 1", "Message 1 for OT 1"]
      ]
      choices = [0, 1]

      result = OT.extension(message_pairs, choices)
      expect(result).to eq(["Message 0 for OT 0", "Message 1 for OT 1"])
    end
  end
end
