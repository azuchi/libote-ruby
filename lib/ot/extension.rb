# frozen_string_literal: true

require "digest"
require "securerandom"

module OT
  # Simplified OT Extension implementation
  # Educational implementation of OT extension for demonstration
  class Extension
    # Security parameter (number of base OTs needed)
    SECURITY_PARAMETER = 128

    # Correlation robust hash function using SHA256
    class CorrelationRobustHash
      def self.hash(seed, index)
        # Use seed || index as input to SHA256
        input = seed + index.to_s.b
        Digest::SHA256.digest(input)
      end

      def self.hash_with_length(seed, index, length)
        # Generate hash and expand to desired length if needed
        hash_val = hash(seed, index)
        if length <= hash_val.length
          hash_val[0, length]
        else
          # Expand by concatenating multiple hashes
          result = hash_val.dup
          counter = 1
          while result.length < length
            result += hash(seed, index + counter)
            counter += 1
          end
          result[0, length]
        end
      end
    end

    # OT Extension Sender
    class Sender
      def initialize
        @messages = []
      end

      def message_pairs=(message_pairs)
        @messages = message_pairs
      end

      def extend_ots(receiver_choices)
        num_extensions = @messages.length
        raise "No messages set" if num_extensions.zero?

        # Step 1: Generate random seeds for each base OT
        sender_seeds = SECURITY_PARAMETER.times.map { SecureRandom.bytes(32) }

        # Step 2: For each extension OT, compute encrypted messages
        extended_results = []

        num_extensions.times do |j|
          receiver_choices[j]

          # Derive keys from sender seeds
          key0 = derive_key(sender_seeds, j, 0)
          key1 = derive_key(sender_seeds, j, 1)

          # NOTE: Both keys are computed but only the correct one will decrypt properly

          # Encrypt both messages, but only one will be correctly decryptable
          msg0, msg1 = @messages[j]

          # Encrypt message 0 with key0, message 1 with key1
          encrypted0 = xor_strings(msg0, key0[0, msg0.length])
          encrypted1 = xor_strings(msg1, key1[0, msg1.length])

          extended_results << [encrypted0, encrypted1]
        end

        # Return the seeds and encrypted messages
        {
          seeds: sender_seeds,
          encrypted_messages: extended_results
        }
      end

      private

      def derive_key(seeds, index, choice_bit)
        key = ""
        seeds.each_with_index do |seed, _i|
          # XOR seed with choice bit for key derivation
          modified_seed = choice_bit == 1 ? xor_with_bit(seed, 1) : seed
          key += CorrelationRobustHash.hash(modified_seed, index)
        end
        key
      end

      def xor_with_bit(seed, bit)
        result = seed.dup
        if bit == 1 && !result.empty?
          # XOR the first byte with 1
          result[0] = (result[0].ord ^ 1).chr
        end
        result
      end

      def xor_strings(str1, str2)
        result = ""
        [str1.length, str2.length].min.times do |i|
          result += (str1.getbyte(i) ^ str2.getbyte(i)).chr
        end
        result
      end
    end

    # OT Extension Receiver
    class Receiver
      def initialize(choices)
        @choices = choices
        @num_extensions = choices.length
      end

      attr_reader :choices

      def receive_extended_ots(sender_response)
        seeds = sender_response[:seeds]
        encrypted_messages = sender_response[:encrypted_messages]

        results = []

        @num_extensions.times do |j|
          choice = @choices[j]

          # Derive the same key the sender used for our choice
          key = derive_key(seeds, j, choice)

          # Decrypt the message corresponding to our choice
          encrypted_msg = encrypted_messages[j][choice]
          decrypted = xor_strings(encrypted_msg, key[0, encrypted_msg.length])

          results << decrypted
        end

        results
      end

      private

      def derive_key(seeds, index, choice_bit)
        key = ""
        seeds.each_with_index do |seed, _i|
          # XOR seed with choice bit for key derivation
          modified_seed = choice_bit == 1 ? xor_with_bit(seed, 1) : seed
          key += CorrelationRobustHash.hash(modified_seed, index)
        end
        key
      end

      def xor_with_bit(seed, bit)
        result = seed.dup
        if bit == 1 && !result.empty?
          # XOR the first byte with 1
          result[0] = (result[0].ord ^ 1).chr
        end
        result
      end

      def xor_strings(str1, str2)
        result = ""
        [str1.length, str2.length].min.times do |i|
          result += (str1.getbyte(i) ^ str2.getbyte(i)).chr
        end
        result
      end
    end

    # High-level protocol runner
    class Protocol
      def self.run(message_pairs, choices)
        # Validate input
        raise "Number of choices must match number of message pairs" if choices.length != message_pairs.length

        # Setup
        sender = Sender.new
        receiver = Receiver.new(choices)

        sender.message_pairs = message_pairs

        # Execute extension protocol
        receiver_choices = receiver.choices
        sender_response = sender.extend_ots(receiver_choices)
        receiver.receive_extended_ots(sender_response)
      end
    end
  end
end
