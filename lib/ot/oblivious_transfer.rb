# frozen_string_literal: true

require_relative "curve25519"

module OT
  # Simple 1-out-of-2 Oblivious Transfer implementation
  # Based on elliptic curve cryptography
  class ObliviousTransfer
    # Sender side of the oblivious transfer protocol
    class Sender
      def initialize
        @messages = nil
        @private_key = Curve25519::Scalar.random
        @public_key = Curve25519::GENERATOR * @private_key
      end

      # Set two messages for 1-out-of-2 OT
      def set_messages(message0, message1)
        @messages = [message0, message1]
      end

      # Generate sender's public parameters
      def generate_parameters
        {
          public_key: @public_key.to_base64,
          generator: Curve25519::GENERATOR.to_base64
        }
      end

      # Process receiver's choice and return encrypted messages
      def process_choice(receiver_public_key_b64, _receiver_params)
        raise "Messages not set" unless @messages

        receiver_key = Curve25519::Point.from_base64(receiver_public_key_b64)

        # Generate random values for each message
        r0 = Curve25519::Scalar.random
        r1 = Curve25519::Scalar.random

        # Create shared secrets based on the receiver's choice encoding
        # The receiver encodes their choice in their public key
        # If choice = 0: receiver_key = g^k
        # If choice = 1: receiver_key = g^k + sender_public_key

        # For message 0: shared secret with receiver_key directly
        shared0 = receiver_key * r0

        # For message 1: shared secret with (receiver_key - sender_public_key)
        # This only works correctly when receiver chose 1
        adjusted_key = receiver_key + (@public_key * Curve25519::Scalar.new(-1))
        shared1 = adjusted_key * r1

        # Encrypt messages using shared secrets as keys
        encrypted0 = encrypt_message(@messages[0], shared0.to_hex)
        encrypted1 = encrypt_message(@messages[1], shared1.to_hex)

        {
          encrypted_messages: [encrypted0, encrypted1],
          r_points: [
            (Curve25519::GENERATOR * r0).to_base64,
            (Curve25519::GENERATOR * r1).to_base64
          ]
        }
      end

      private

      def encrypt_message(message, key)
        # Simple XOR encryption (not cryptographically secure - for demo)
        key_hash = Digest::SHA256.digest(key) # Use digest instead of hexdigest
        message_bytes = message.bytes
        key_bytes = key_hash.bytes

        # Ensure we have enough key material
        expanded_key = (key_bytes * ((message_bytes.length / key_bytes.length) + 1))[0, message_bytes.length]

        encrypted = message_bytes.zip(expanded_key).map { |m, k| m ^ k }.pack("C*")
        [encrypted].pack("m0") # Base64 encode
      end
    end

    # Receiver side of the oblivious transfer protocol
    class Receiver
      def initialize(choice)
        raise "Choice must be 0 or 1" unless [0, 1].include?(choice)

        @choice = choice
        @private_key = Curve25519::Scalar.random
      end

      # Generate receiver's public key based on choice
      def generate_public_key(sender_params)
        sender_public_key = Curve25519::Point.from_base64(sender_params[:public_key])
        generator = Curve25519::Point.from_base64(sender_params[:generator])

        base_key = generator * @private_key

        # If choice is 1, add sender's public key to mask the choice
        @public_key = if @choice == 1
                        base_key + sender_public_key
                      else
                        base_key
                      end

        @public_key.to_base64
      end

      # Decrypt the chosen message
      def decrypt_message(sender_response)
        encrypted_messages = sender_response[:encrypted_messages]
        r_points = sender_response[:r_points].map { |p| Curve25519::Point.from_base64(p) }

        # Use the r_point corresponding to our choice
        r_point = r_points[@choice]

        # Compute shared secret: private_key * r_point
        shared_secret = r_point * @private_key

        # Decrypt the message
        encrypted_message = encrypted_messages[@choice]
        decrypt_message_with_key(encrypted_message, shared_secret.to_hex)
      end

      private

      def decrypt_message_with_key(encrypted_base64, key)
        # Simple XOR decryption (not cryptographically secure - for demo)
        encrypted = encrypted_base64.unpack1("m0")
        key_hash = Digest::SHA256.digest(key) # Use digest instead of hexdigest
        encrypted_bytes = encrypted.bytes
        key_bytes = key_hash.bytes

        # Ensure we have enough key material
        expanded_key = (key_bytes * ((encrypted_bytes.length / key_bytes.length) + 1))[0, encrypted_bytes.length]

        decrypted = encrypted_bytes.zip(expanded_key).map { |e, k| e ^ k }.pack("C*")
        decrypted.force_encoding("UTF-8")
      end
    end

    # Convenience class for running complete OT protocol
    class Protocol
      def self.run(message0, message1, choice)
        # Setup
        sender = Sender.new
        receiver = Receiver.new(choice)

        sender.set_messages(message0, message1)

        # Protocol execution
        sender_params = sender.generate_parameters
        receiver_public_key = receiver.generate_public_key(sender_params)
        sender_response = sender.process_choice(receiver_public_key, {})
        receiver.decrypt_message(sender_response)
      end
    end
  end
end
