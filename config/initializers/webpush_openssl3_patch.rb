# frozen_string_literal: true

# Monkey patch for webpush gem to work with OpenSSL 3.0
# The webpush gem v1.1.0 has issues with OpenSSL 3.0's immutable keys

module Webpush
  class VapidKey
    # Override from_keys to work with OpenSSL 3.0
    def self.from_keys(public_key, private_key)
      Rails.logger.info "VapidKey.from_keys PATCHED METHOD CALLED"
      # Decode the keys
      public_key_bytes = Webpush.decode64(public_key)
      private_key_bytes = Webpush.decode64(private_key)

      # Build EC private key in SEC1 format, then wrap in PKCS8
      # SEC1 ECPrivateKey without explicit public key - let OpenSSL derive it
      ec_private_key = OpenSSL::ASN1::Sequence([
        OpenSSL::ASN1::Integer(1),
        OpenSSL::ASN1::OctetString(private_key_bytes),
        OpenSSL::ASN1::ObjectId("prime256v1", 0, :EXPLICIT)
      ])

      # PKCS8 wrapper
      ec_params = OpenSSL::ASN1::Sequence([
        OpenSSL::ASN1::ObjectId("id-ecPublicKey"),
        OpenSSL::ASN1::ObjectId("prime256v1")
      ])

      pkcs8 = OpenSSL::ASN1::Sequence([
        OpenSSL::ASN1::Integer(0),
        ec_params,
        OpenSSL::ASN1::OctetString(ec_private_key.to_der)
      ])

      der = pkcs8.to_der
      pem = "-----BEGIN PRIVATE KEY-----\n"
      pem += Base64.strict_encode64(der).scan(/.{1,64}/).join("\n")
      pem += "\n-----END PRIVATE KEY-----\n"

      # Create instance and set curve from PEM
      key = allocate
      curve = OpenSSL::PKey.read(pem)

      # Verify the derived public key matches what we expect
      derived_public = curve.public_key.to_bn.to_s(2)
      unless derived_public == public_key_bytes
        Rails.logger.error "Public key mismatch in VapidKey.from_keys!"
        Rails.logger.error "Expected: #{Webpush.encode64(public_key_bytes)}"
        Rails.logger.error "Got: #{Webpush.encode64(derived_public)}"
      end

      key.instance_variable_set(:@curve, curve)
      key
    end

    # Override public_key= to avoid mutation
    def public_key=(key)
      # This shouldn't be called with from_keys, but if it is, we need to rebuild
      raise "Cannot set public_key after initialization with OpenSSL 3.0"
    end

    # Override private_key= to avoid mutation
    def private_key=(key)
      # This shouldn't be called with from_keys, but if it is, we need to rebuild
      raise "Cannot set private_key after initialization with OpenSSL 3.0"
    end
  end

  # Patch Encryption module for OpenSSL 3.0 compatibility
  module Encryption
    extend self

    def encrypt(message, p256dh, auth)
      assert_arguments(message, p256dh, auth)

      group_name = "prime256v1"
      salt = Random.new.bytes(16)

      # OpenSSL 3.0 compatible: use generate instead of new + generate_key
      server = OpenSSL::PKey::EC.generate(group_name)
      server_public_key_bn = server.public_key.to_bn

      group = OpenSSL::PKey::EC::Group.new(group_name)
      client_public_key_bn = OpenSSL::BN.new(Webpush.decode64(p256dh), 2)
      client_public_key = OpenSSL::PKey::EC::Point.new(group, client_public_key_bn)

      shared_secret = server.dh_compute_key(client_public_key)

      client_auth_token = Webpush.decode64(auth)

      info = "WebPush: info\0" + client_public_key_bn.to_s(2) + server_public_key_bn.to_s(2)
      content_encryption_key_info = "Content-Encoding: aes128gcm\0"
      nonce_info = "Content-Encoding: nonce\0"

      prk = HKDF.new(shared_secret, salt: client_auth_token, algorithm: "SHA256", info: info).next_bytes(32)

      content_encryption_key = HKDF.new(prk, salt: salt, info: content_encryption_key_info).next_bytes(16)

      nonce = HKDF.new(prk, salt: salt, info: nonce_info).next_bytes(12)

      ciphertext = encrypt_payload(message, content_encryption_key, nonce)

      serverkey16bn = convert16bit(server_public_key_bn)
      rs = ciphertext.bytesize
      raise ArgumentError, "encrypted payload is too big" if rs > 4096

      aes128gcmheader = "#{salt}" + [ rs ].pack("N*") + [ serverkey16bn.bytesize ].pack("C*") + serverkey16bn

      aes128gcmheader + ciphertext
    end

    private

    def encrypt_payload(plaintext, content_encryption_key, nonce)
      cipher = OpenSSL::Cipher.new("aes-128-gcm")
      cipher.encrypt
      cipher.key = content_encryption_key
      cipher.iv = nonce
      text = cipher.update(plaintext)
      padding = cipher.update("\2\0")
      e_text = text + padding + cipher.final
      e_tag = cipher.auth_tag

      e_text + e_tag
    end

    def convert16bit(key)
      [ key.to_s(16) ].pack("H*")
    end

    def assert_arguments(message, p256dh, auth)
      raise ArgumentError, "message cannot be blank" if blank?(message)
      raise ArgumentError, "p256dh cannot be blank" if blank?(p256dh)
      raise ArgumentError, "auth cannot be blank" if blank?(auth)
    end

    def blank?(value)
      value.nil? || value.empty?
    end
  end
end
