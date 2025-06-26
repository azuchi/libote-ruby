# frozen_string_literal: true

require_relative "ot/version"
require_relative "ot/curve25519"
require_relative "ot/oblivious_transfer"
require_relative "ot/simple_ot"
require_relative "ot/extension"

# Ruby implementation of Oblivious Transfer (OT) protocols
module OT
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

  # Run OT extension for multiple message pairs and choices
  def extension(message_pairs, choices)
    Extension::Protocol.run(message_pairs, choices)
  end

  # Create a new OT extension sender
  def extension_sender
    Extension::Sender.new
  end

  # Create a new OT extension receiver with choices
  def extension_receiver(choices)
    Extension::Receiver.new(choices)
  end

  # Set message pairs for OT extension sender (compatibility method)
  def set_extension_message_pairs(sender, message_pairs)
    sender.message_pairs = message_pairs
  end
end
