# frozen_string_literal: true

require_relative "ote/version"
require_relative "ote/curve25519"
require_relative "ote/oblivious_transfer"
require_relative "ote/simple_ot"

# Ruby implementation of Oblivious Transfer (OT) protocols
module Ote
  class Error < StandardError; end

  # Convenience methods for common operations
  module_function

  # Run a simple 1-out-of-2 oblivious transfer (using RSA-based implementation)
  def simple_ot(message0, message1, choice)
    SimpleOT::Protocol.run(message0, message1, choice)
  end

  # Create a new OT sender (elliptic curve version)
  def sender
    ObliviousTransfer::Sender.new
  end

  # Create a new OT receiver with choice (elliptic curve version)
  def receiver(choice)
    ObliviousTransfer::Receiver.new(choice)
  end

  # Create a new RSA-based OT sender
  def simple_sender
    SimpleOT::Sender.new
  end

  # Create a new RSA-based OT receiver with choice
  def simple_receiver(choice)
    SimpleOT::Receiver.new(choice)
  end
end
