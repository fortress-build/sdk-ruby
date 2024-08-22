require 'openssl'
require 'base64'
require 'digest'
require 'hmac'
require 'hmac-sha1'

module Fortress
  # Crypto provides methods to encrypt and decrypt data using the ECIES algorithm.
  module Crypto
    # Decrypts the ciphertext using the provided private key.
    def self.decrypt(private_key, ciphertext)
      # Format the private key
      formated_private_key = "-----BEGIN EC PRIVATE KEY-----\n#{private_key}\n-----END EC PRIVATE KEY-----"

      # Load the private key
      private_key = OpenSSL::PKey::EC.new(formated_private_key)
      private_key.check_key

      # Decode the ciphertext
      ciphertext = Base64.decode64(ciphertext)

      # Extract the ephemeral public key
      ephemeral_size = ciphertext[0].ord
      ephemeral_public_key = ciphertext[1, ephemeral_size]

      # Extract the MAC and AES-GCM ciphertext
      sha1_size = 20
      aes_size = 16
      ciphertext = ciphertext[(1 + ephemeral_size)..-1]

      # Verify the ciphertext length
      raise 'Invalid ciphertext' if ciphertext.length < sha1_size + aes_size

      # Derive the public key
      eph_pub = OpenSSL::PKey::EC::Point.new(OpenSSL::PKey::EC::Group.new('prime256v1'),
                                             OpenSSL::BN.new(ephemeral_public_key, 2))

      # Perform the ECDH key exchange
      shared_key = private_key.dh_compute_key(eph_pub)

      # Derive the shared key
      shared = Digest::SHA256.digest(shared_key)

      # Verify the MAC
      tag_start = ciphertext.length - sha1_size
      hmac = HMAC::SHA1.new(shared[16, 16])
      hmac.update(ciphertext[0, tag_start])
      mac = hmac.digest

      raise 'Invalid MAC' unless mac == ciphertext[tag_start..-1]

      # Decrypt the ciphertext using AES-CBC
      cipher = OpenSSL::Cipher.new('aes-128-cbc')
      cipher.decrypt
      cipher.key = shared[0, 16]
      cipher.iv = ciphertext[0, aes_size]
      cipher.padding = 0

      plaintext = cipher.update(ciphertext[aes_size, tag_start - aes_size]) + cipher.final

      # Remove padding
      padding_length = plaintext[-1].ord
      plaintext = plaintext[0...-padding_length]

      plaintext.force_encoding('UTF-8')
    end
  end
end
