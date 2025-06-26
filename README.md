# OT

Pure Ruby implementation of Oblivious Transfer (OT) protocols. This library provides both basic 1-out-of-2 Oblivious Transfer and OT Extension implementations for efficient batch operations.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'oblivious-transfer', require: 'ot'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install oblivious-transfer

## Usage

### Simple 1-out-of-2 Oblivious Transfer

The simplest way to use the library is with the `simple_ot` method:

```ruby
require 'ot'

# Messages for the OT protocol
message0 = "Secret message 0"
message1 = "Secret message 1"

# Receiver chooses which message to receive (0 or 1)
choice = 1

# Perform the OT protocol
chosen_message = OT.simple_ot(message0, message1, choice)
puts chosen_message  # => "Secret message 1"
```

### RSA-based OT (Recommended)

For more control, you can use the RSA-based implementation directly:

```ruby
require 'ot'

# Create sender and receiver
sender = OT.simple_sender
receiver = OT.simple_receiver(1)  # choice = 1

# Sender sets the two messages
sender.set_messages("First option", "Second option")

# Protocol execution
sender_public_key = sender.public_key
blinding_values = receiver.generate_blinding_values(sender_public_key)
sender_response = sender.encrypt_messages(blinding_values[:x0], blinding_values[:x1])
chosen_message = receiver.decrypt_message(sender_response)

puts chosen_message  # => "Second option"
```

### Elliptic Curve-based OT

The library also includes an elliptic curve implementation:

```ruby
require 'ot'

# Create sender and receiver
sender = OT.sender
receiver = OT.receiver(0)  # choice = 0

# Sender sets the two messages
sender.set_messages("Option A", "Option B")

# Protocol execution
sender_params = sender.generate_parameters
receiver_public_key = receiver.generate_public_key(sender_params)
sender_response = sender.process_choice(receiver_public_key, {})
chosen_message = receiver.decrypt_message(sender_response)

puts chosen_message  # => "Option A"
```

### OT Extension (Batch OT)

For efficient batch operations, use OT Extension which allows performing many OTs with the cost of only a few base OTs:

```ruby
require 'ot'

# Prepare multiple message pairs
message_pairs = [
  ["Database record 1A", "Database record 1B"],
  ["Database record 2A", "Database record 2B"],
  ["Database record 3A", "Database record 3B"],
  ["Database record 4A", "Database record 4B"]
]

# Receiver's choices for each pair
choices = [0, 1, 0, 1]

# Perform batch OT extension
results = OT.extension(message_pairs, choices)

puts results[0]  # => "Database record 1A" (choice 0)
puts results[1]  # => "Database record 2B" (choice 1)
puts results[2]  # => "Database record 3A" (choice 0)
puts results[3]  # => "Database record 4B" (choice 1)
```

#### Advanced OT Extension Usage

```ruby
require 'ot'

# Create sender and receiver for manual control
sender = OT.extension_sender
receiver = OT.extension_receiver([0, 1, 0])

# Set up the message pairs
message_pairs = [
  ["Option 1A", "Option 1B"],
  ["Option 2A", "Option 2B"], 
  ["Option 3A", "Option 3B"]
]
sender.set_message_pairs(message_pairs)

# Execute the extension protocol
receiver_choices = receiver.get_choices
sender_response = sender.extend_ots(receiver_choices)
results = receiver.receive_extended_ots(sender_response)

puts results  # => ["Option 1A", "Option 2B", "Option 3A"]
```

## How Oblivious Transfer Works

1-out-of-2 Oblivious Transfer allows a receiver to obtain one of two messages from a sender, without the sender learning which message was chosen, and without the receiver learning anything about the other message.

### Security Properties

- **Receiver Privacy**: The sender doesn't learn which message (0 or 1) the receiver chose
- **Sender Privacy**: The receiver only learns the chosen message, nothing about the other message
- **Correctness**: The receiver always gets the correct message for their choice

## Implementation Details

This library provides multiple OT implementations:

### Basic OT Implementations

#### RSA-based Implementation (`SimpleOT`)
- Uses RSA encryption with 2048-bit keys
- Based on the classic RSA-based OT protocol
- Default implementation used by `OT.simple_ot()`
- More straightforward and reliable

#### Elliptic Curve Implementation (`ObliviousTransfer`)
- Uses Curve25519 elliptic curve cryptography
- Custom elliptic curve point and scalar arithmetic
- Alternative implementation for educational purposes

### OT Extension Implementation (`Extension`)

The OT extension allows performing many OTs efficiently:

- **Based on**: IKNP (Ishai-Kilian-Nissim-Petrank) OT extension
- **Security Parameter**: 128 base OTs for security
- **Correlation-Robust Hash**: SHA256-based hash function
- **Efficiency**: O(n) communication for n OTs vs O(n·k) for n independent base OTs

#### Key Features:
- **Batch Processing**: Handle thousands of OTs efficiently
- **Scalability**: Linear cost in the number of OTs
- **Security**: Maintains the same security properties as base OT
- **Flexibility**: Works with any secure base OT implementation

#### Use Cases:
- Private Set Intersection (PSI)
- Multi-Party Computation (MPC)  
- Private Information Retrieval (PIR)
- Secure Database Queries

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Testing

Run the test suite with:

```bash
bundle exec rspec
```

## Security Notice

This implementation is for educational and research purposes. For production use, please ensure proper security review and consider using established cryptographic libraries.