# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ote::Curve25519 do
  describe "Point class" do
    it "can create points" do
      point = Ote::Curve25519::Point.new(9, 10)
      expect(point.x).to eq(9)
      expect(point.y).to eq(10)
    end

    it "can create point from hash" do
      point = Ote::Curve25519::Point.hash("test data")
      expect(point).to be_a(Ote::Curve25519::Point)
    end

    it "can generate random points" do
      point1 = Ote::Curve25519::Point.random
      point2 = Ote::Curve25519::Point.random
      expect(point1).not_to eq(point2)
    end

    it "supports serialization" do
      point = Ote::Curve25519::Point.new(123, 456)
      hex = point.to_hex
      base64 = point.to_base64

      expect(Ote::Curve25519::Point.from_hex(hex)).to eq(point)
      expect(Ote::Curve25519::Point.from_base64(base64)).to eq(point)
    end
  end

  describe "Scalar class" do
    it "can create scalars" do
      scalar = Ote::Curve25519::Scalar.new(42)
      expect(scalar.value).to eq(42)
    end

    it "can create scalar from hash" do
      scalar = Ote::Curve25519::Scalar.hash("test data")
      expect(scalar).to be_a(Ote::Curve25519::Scalar)
    end

    it "can generate random scalars" do
      scalar1 = Ote::Curve25519::Scalar.random
      scalar2 = Ote::Curve25519::Scalar.random
      expect(scalar1).not_to eq(scalar2)
    end

    it "supports arithmetic operations" do
      s1 = Ote::Curve25519::Scalar.new(10)
      s2 = Ote::Curve25519::Scalar.new(5)

      expect((s1 + s2).value).to eq(15)
      expect((s1 - s2).value).to eq(5)
      expect((s1 * s2).value).to eq(50)
    end

    it "supports serialization" do
      scalar = Ote::Curve25519::Scalar.new(123)
      hex = scalar.to_hex
      base64 = scalar.to_base64

      expect(Ote::Curve25519::Scalar.from_hex(hex)).to eq(scalar)
      expect(Ote::Curve25519::Scalar.from_base64(base64)).to eq(scalar)
    end
  end
end
