# frozen_string_literal: true

require "spec_helper"

RSpec.describe OT::Extension do
  describe "Correlation Robust Hash" do
    it "produces consistent hashes for same input" do
      seed = "test_seed"
      index = 42

      hash1 = OT::Extension::CorrelationRobustHash.hash(seed, index)
      hash2 = OT::Extension::CorrelationRobustHash.hash(seed, index)

      expect(hash1).to eq(hash2)
    end

    it "produces different hashes for different inputs" do
      seed = "test_seed"

      hash1 = OT::Extension::CorrelationRobustHash.hash(seed, 1)
      hash2 = OT::Extension::CorrelationRobustHash.hash(seed, 2)

      expect(hash1).not_to eq(hash2)
    end

    it "can generate hashes with specified length" do
      seed = "test_seed"
      index = 1
      length = 16

      hash_val = OT::Extension::CorrelationRobustHash.hash_with_length(seed, index, length)

      expect(hash_val.length).to eq(length)
    end
  end

  describe "Protocol execution" do
    let(:message_pairs) do
      [
        ["Message 0A", "Message 0B"],
        ["Message 1A", "Message 1B"],
        ["Message 2A", "Message 2B"]
      ]
    end

    let(:choices) { [0, 1, 0] }

    it "can perform OT extension with multiple message pairs" do
      results = OT.extension(message_pairs, choices)

      expect(results.length).to eq(3)
      expect(results[0]).to eq("Message 0A") # choice 0
      expect(results[1]).to eq("Message 1B") # choice 1
      expect(results[2]).to eq("Message 2A") # choice 0
    end

    it "handles larger batches of OTs" do
      # Test with 10 message pairs
      large_message_pairs = 10.times.map do |i|
        ["Option #{i}A", "Option #{i}B"]
      end
      large_choices = 10.times.map { rand(2) }

      results = OT.extension(large_message_pairs, large_choices)

      expect(results.length).to eq(10)

      # Verify each result matches the expected choice
      results.each_with_index do |result, i|
        choice = large_choices[i]
        expected = large_message_pairs[i][choice]
        expect(result).to eq(expected)
      end
    end

    it "raises error when choices don't match message pairs" do
      expect do
        OT.extension(message_pairs, [0, 1]) # Only 2 choices for 3 pairs
      end.to raise_error("Number of choices must match number of message pairs")
    end
  end

  describe "Sender class" do
    let(:sender) { OT.extension_sender }
    let(:message_pairs) do
      [
        ["Test 0A", "Test 0B"],
        ["Test 1A", "Test 1B"]
      ]
    end

    it "can be instantiated" do
      expect(sender).to be_a(OT::Extension::Sender)
    end

    it "can set message pairs" do
      expect do
        sender.message_pairs = message_pairs
      end.not_to raise_error
    end

    it "raises error when extending OTs without messages" do
      receiver_matrix = [[0, 1], [1, 0]]

      expect do
        sender.extend_ots(receiver_matrix)
      end.to raise_error("No messages set")
    end
  end

  describe "Receiver class" do
    let(:choices) { [0, 1, 0] }
    let(:receiver) { OT.extension_receiver(choices) }

    it "can be instantiated" do
      expect(receiver).to be_a(OT::Extension::Receiver)
    end

    it "stores choices correctly" do
      receiver_choices = receiver.choices

      expect(receiver_choices).to eq([0, 1, 0])
    end

    it "can process extension OTs" do
      # Create a simple sender response for testing
      sender_response = {
        seeds: [SecureRandom.bytes(32)],
        encrypted_messages: [
          %w[encrypted_msg_0 encrypted_msg_1],
          %w[encrypted_msg_2 encrypted_msg_3],
          %w[encrypted_msg_4 encrypted_msg_5]
        ]
      }

      expect do
        receiver.receive_extended_ots(sender_response)
      end.not_to raise_error
    end
  end
end
