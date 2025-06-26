# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ote::ObliviousTransfer do
  describe "1-out-of-2 Oblivious Transfer" do
    let(:message0) { "Secret message 0" }
    let(:message1) { "Secret message 1" }

    it "can perform complete OT protocol with choice 0" do
      result = Ote.simple_ot(message0, message1, 0)
      expect(result).to eq(message0)
    end

    it "can perform complete OT protocol with choice 1" do
      result = Ote.simple_ot(message0, message1, 1)
      expect(result).to eq(message1)
    end

    it "sender can be instantiated" do
      sender = Ote.sender
      expect(sender).to be_a(Ote::ObliviousTransfer::Sender)
    end

    it "receiver can be instantiated with choice" do
      receiver = Ote.receiver(0)
      expect(receiver).to be_a(Ote::ObliviousTransfer::Receiver)
    end

    it "receiver rejects invalid choices" do
      expect do
        Ote.receiver(2)
      end.to raise_error("Choice must be 0 or 1")
    end
  end

  describe "Sender class" do
    let(:sender) { Ote::ObliviousTransfer::Sender.new }

    it "can set messages" do
      expect do
        sender.set_messages("msg0", "msg1")
      end.not_to raise_error
    end

    it "can generate parameters" do
      params = sender.generate_parameters
      expect(params).to have_key(:public_key)
      expect(params).to have_key(:generator)
    end

    it "raises error when processing choice without messages" do
      expect do
        sender.process_choice("dummy_key", {})
      end.to raise_error("Messages not set")
    end
  end

  describe "Receiver class" do
    let(:receiver) { Ote::ObliviousTransfer::Receiver.new(0) }
    let(:sender_params) do
      {
        public_key: Ote::Curve25519::GENERATOR.to_base64,
        generator: Ote::Curve25519::GENERATOR.to_base64
      }
    end

    it "can generate public key" do
      public_key = receiver.generate_public_key(sender_params)
      expect(public_key).to be_a(String)
      expect(public_key.length).to be > 0
    end
  end
end
