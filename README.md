# Ote

Pure Ruby implementation of Oblivious Transfer (OT) protocols. This library provides 1-out-of-2 Oblivious Transfer implementations using both elliptic curve cryptography and RSA-based approaches.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ote'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install ote

## Usage

### Simple 1-out-of-2 Oblivious Transfer

The simplest way to use the library is with the `simple_ot` method:

```ruby
require 'ote'

# Messages for the OT protocol
message0 = "Secret message 0"
message1 = "Secret message 1"

# Receiver chooses which message to receive (0 or 1)
choice = 1

# Perform the OT protocol
chosen_message = Ote.simple_ot(message0, message1, choice)
puts chosen_message  # => "Secret message 1"
```

### RSA-based OT (Recommended)

For more control, you can use the RSA-based implementation directly:

```ruby
require 'ote'

# Create sender and receiver
sender = Ote.simple_sender
receiver = Ote.simple_receiver(1)  # choice = 1

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
require 'ote'

# Create sender and receiver
sender = Ote.sender
receiver = Ote.receiver(0)  # choice = 0

# Sender sets the two messages
sender.set_messages("Option A", "Option B")

# Protocol execution
sender_params = sender.generate_parameters
receiver_public_key = receiver.generate_public_key(sender_params)
sender_response = sender.process_choice(receiver_public_key, {})
chosen_message = receiver.decrypt_message(sender_response)

puts chosen_message  # => "Option A"
```

## How Oblivious Transfer Works

1-out-of-2 Oblivious Transfer allows a receiver to obtain one of two messages from a sender, without the sender learning which message was chosen, and without the receiver learning anything about the other message.

### Security Properties

- **Receiver Privacy**: The sender doesn't learn which message (0 or 1) the receiver chose
- **Sender Privacy**: The receiver only learns the chosen message, nothing about the other message
- **Correctness**: The receiver always gets the correct message for their choice

## Implementation Details

This library provides two OT implementations:

### RSA-based Implementation (`SimpleOT`)
- Uses RSA encryption with 2048-bit keys
- Based on the classic RSA-based OT protocol
- Default implementation used by `Ote.simple_ot()`
- More straightforward and reliable

### Elliptic Curve Implementation (`ObliviousTransfer`)
- Uses Curve25519 elliptic curve cryptography
- Custom elliptic curve point and scalar arithmetic
- Alternative implementation for educational purposes

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Testing

Run the test suite with:

```bash
bundle exec rspec
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/ote.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Security Notice

This implementation is for educational and research purposes. For production use, please ensure proper security review and consider using established cryptographic libraries.