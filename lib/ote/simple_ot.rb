# frozen_string_literal: true

require "openssl"
require "securerandom"
require "digest"

module Ote
  # Simple RSA-based 1-out-of-2 Oblivious Transfer implementation
  # This is for educational purposes only - not cryptographically secure
  class SimpleOT
    class Sender
      def initialize
        @messages = nil
        @rsa_key = OpenSSL::PKey::RSA.new(2048)
        @public_key = @rsa_key.public_key
      end

      def set_messages(message0, message1)
        @messages = [message0, message1]
      end

      def public_key
        @public_key.to_pem
      end

      def encrypt_messages(receiver_x0, receiver_x1)
        raise "Messages not set" unless @messages

        # Parse receiver's values
        x0 = OpenSSL::BN.new(receiver_x0, 16)
        x1 = OpenSSL::BN.new(receiver_x1, 16)

        # Generate random values k0, k1
        k0 = OpenSSL::BN.rand(256)
        k1 = OpenSSL::BN.rand(256)

        # RSA parameters
        @rsa_key.e
        n = @rsa_key.n

        # Compute y0 = k0 + x0^d mod n and y1 = k1 + x1^d mod n
        # where d is the private exponent
        d = @rsa_key.d

        y0 = (k0 + x0.mod_exp(d, n)) % n
        y1 = (k1 + x1.mod_exp(d, n)) % n

        # Encrypt messages with k0 and k1
        encrypted0 = encrypt_with_key(@messages[0], k0.to_s(16))
        encrypted1 = encrypt_with_key(@messages[1], k1.to_s(16))

        {
          encrypted_messages: [encrypted0, encrypted1],
          y_values: [y0.to_s(16), y1.to_s(16)]
        }
      end

      private

      def encrypt_with_key(message, key)
        # Simple XOR with SHA256 of key
        key_hash = Digest::SHA256.digest(key)
        message_bytes = message.bytes
        key_bytes = key_hash.bytes

        # Expand key if needed
        expanded_key = (key_bytes * ((message_bytes.length / key_bytes.length) + 1))[0, message_bytes.length]

        encrypted = message_bytes.zip(expanded_key).map { |m, k| m ^ k }.pack("C*")
        [encrypted].pack("m0") # Base64 encode
      end
    end

    class Receiver
      def initialize(choice)
        raise "Choice must be 0 or 1" unless [0, 1].include?(choice)

        @choice = choice
      end

      def generate_blinding_values(sender_public_key_pem)
        public_key = OpenSSL::PKey::RSA.new(sender_public_key_pem)
        n = public_key.n
        e = public_key.e

        # Generate random values
        r0 = OpenSSL::BN.rand(256)
        r1 = OpenSSL::BN.rand(256)

        @r_values = [r0, r1]

        # Generate x0 and x1 based on choice
        if @choice.zero?
          # For choice 0: x0 = r0^e mod n, x1 = random
          x0 = r0.mod_exp(e, n)
          x1 = OpenSSL::BN.rand(n.num_bits)
        else
          # For choice 1: x0 = random, x1 = r1^e mod n
          x0 = OpenSSL::BN.rand(n.num_bits)
          x1 = r1.mod_exp(e, n)
        end

        {
          x0: x0.to_s(16),
          x1: x1.to_s(16)
        }
      end

      def decrypt_message(sender_response)
        encrypted_messages = sender_response[:encrypted_messages]
        y_values = sender_response[:y_values].map { |y| OpenSSL::BN.new(y, 16) }

        # Use the r value and y value corresponding to our choice
        r = @r_values[@choice]
        y = y_values[@choice]

        # Compute the key: k = y - r^e mod n
        # Since sender computed y = k + x^d mod n where x = r^e mod n for the chosen bit
        # So k = y - r^e mod n for the receiver
        # We need the public key to compute r^e mod n
        # But we stored r, not x, so let's use a different approach

        # The receiver knows r (which was used to compute x = r^e mod n)
        # The sender computed y = k + x^d mod n = k + (r^e)^d mod n = k + r mod n
        # So k = y - r mod n

        # Since the math should work out: k = y - r
        k = (y - r).to_s(16)

        # Decrypt the chosen message
        encrypted_message = encrypted_messages[@choice]
        decrypt_with_key(encrypted_message, k)
      end

      private

      def decrypt_with_key(encrypted_base64, key)
        # Simple XOR decryption
        encrypted = encrypted_base64.unpack1("m0")
        key_hash = Digest::SHA256.digest(key)
        encrypted_bytes = encrypted.bytes
        key_bytes = key_hash.bytes

        # Expand key if needed
        expanded_key = (key_bytes * ((encrypted_bytes.length / key_bytes.length) + 1))[0, encrypted_bytes.length]

        decrypted = encrypted_bytes.zip(expanded_key).map { |e, k| e ^ k }.pack("C*")
        decrypted.force_encoding("UTF-8")
      end
    end

    # Protocol runner
    class Protocol
      def self.run(message0, message1, choice)
        sender = Sender.new
        receiver = Receiver.new(choice)

        sender.set_messages(message0, message1)

        # Protocol execution
        sender_public_key = sender.public_key
        blinding_values = receiver.generate_blinding_values(sender_public_key)
        sender_response = sender.encrypt_messages(blinding_values[:x0], blinding_values[:x1])
        receiver.decrypt_message(sender_response)
      end
    end
  end
end
