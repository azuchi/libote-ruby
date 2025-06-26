# frozen_string_literal: true

require "securerandom"
require "digest"

module Ote
  module Curve25519
    # Curve25519 parameters
    P = (2**255) - 19
    L = (2**252) + 27_742_317_777_372_353_535_851_937_790_883_648_493

    # Point on Curve25519
    class Point
      attr_reader :x, :y

      def initialize(x = 0, y = 1)
        @x = x % P
        @y = y % P
      end

      # Create point from hash
      def self.hash(data)
        digest = Digest::SHA256.digest(data)
        x = digest.unpack1("Q<") % P
        new(x, derive_y(x))
      end

      # Generate random point
      def self.random
        scalar = Scalar.random
        GENERATOR * scalar
      end

      # Point addition
      def +(other)
        return self if other.nil? || other.infinity?
        return other if infinity?

        # Simplified addition (not cryptographically secure - for demo)
        new_x = (@x + other.x) % P
        new_y = (@y + other.y) % P
        Point.new(new_x, new_y)
      end

      # Scalar multiplication
      def *(other)
        return Point.new(0, 0) if other.value.zero?

        result = Point.new(0, 0) # Identity point
        addend = self
        scalar_bits = other.value

        while scalar_bits.positive?
          result += addend if scalar_bits & 1 == 1
          addend = addend.double
          scalar_bits >>= 1
        end

        result
      end

      # Point doubling
      def double
        # Simplified doubling (not cryptographically secure - for demo)
        new_x = (@x * 2) % P
        new_y = (@y * 2) % P
        Point.new(new_x, new_y)
      end

      def infinity?
        @x.zero? && @y.zero?
      end

      def ==(other)
        @x == other.x && @y == other.y
      end

      def to_bytes
        [@x, @y].pack("Q<Q<")
      end

      def to_hex
        to_bytes.unpack1("H*")
      end

      def to_base64
        [to_bytes].pack("m0")
      end

      def self.from_hex(hex_string)
        bytes = [hex_string].pack("H*")
        x, y = bytes.unpack("Q<Q<")
        new(x, y)
      end

      def self.from_base64(base64_string)
        bytes = base64_string.unpack1("m0")
        x, y = bytes.unpack("Q<Q<")
        new(x, y)
      end

      def self.derive_y(x)
        # Simplified Y coordinate derivation (not cryptographically secure)
        ((x * x) + 1) % P
      end
    end

    # Scalar for Curve25519
    class Scalar
      attr_reader :value

      def initialize(value = 0)
        @value = value % L
      end

      # Create scalar from hash
      def self.hash(data)
        digest = Digest::SHA256.digest(data)
        value = digest.unpack1("Q<") % L
        new(value)
      end

      # Generate random scalar
      def self.random
        bytes = SecureRandom.random_bytes(32)
        value = bytes.unpack1("Q<") % L
        new(value)
      end

      # Scalar arithmetic
      def +(other)
        Scalar.new(@value + other.value)
      end

      def -(other)
        Scalar.new(@value - other.value)
      end

      def *(other)
        if other.is_a?(Scalar)
          Scalar.new(@value * other.value)
        elsif other.is_a?(Point)
          other * self
        else
          Scalar.new(@value * other)
        end
      end

      def inverse
        # Extended Euclidean Algorithm for modular inverse
        Scalar.new(mod_inverse(@value, L))
      end

      def ==(other)
        @value == other.value
      end

      def to_bytes
        [@value].pack("Q<")
      end

      def to_hex
        to_bytes.unpack1("H*")
      end

      def to_base64
        [to_bytes].pack("m0")
      end

      def self.from_hex(hex_string)
        bytes = [hex_string].pack("H*")
        value = bytes.unpack1("Q<")
        new(value)
      end

      def self.from_base64(base64_string)
        bytes = base64_string.unpack1("m0")
        value = bytes.unpack1("Q<")
        new(value)
      end

      private

      def mod_inverse(a, m)
        return 0 if m == 1

        m0 = m
        x0 = 0
        x1 = 1

        while a > 1
          q = a / m
          m, a = a % m, m
          x0, x1 = x1 - (q * x0), x0
        end

        x1.negative? ? x1 + m0 : x1
      end
    end

    # Generator point for Curve25519
    GENERATOR = Point.new(9, Point.send(:derive_y, 9))
  end
end
