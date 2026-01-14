# frozen_string_literal: true

require "test_helper"

class Journals::MnemonicServiceTest < ActiveSupport::TestCase
  def setup
    @service = Journals::MnemonicService.new
    @salt = SecureRandom.hex(32)
  end

  test "wordlist has 2048 words" do
    assert_equal 2048, @service.wordlist.length
  end

  test "wordlist contains expected words" do
    assert_includes @service.wordlist, "abandon"
    assert_includes @service.wordlist, "zoo"
    assert_includes @service.wordlist, "ability"
  end

  test "generate returns 12-word phrase" do
    phrase = @service.generate

    words = phrase.split(" ")
    assert_equal 12, words.length
  end

  test "generate returns only valid BIP39 words" do
    phrase = @service.generate

    words = phrase.split(" ")
    words.each do |word|
      assert_includes @service.wordlist, word, "Word '#{word}' not in wordlist"
    end
  end

  test "generate produces unique phrases" do
    phrases = Array.new(10) { @service.generate }

    assert_equal 10, phrases.uniq.length, "Expected 10 unique phrases"
  end

  test "validate returns true for valid phrase" do
    phrase = @service.generate

    assert @service.validate(phrase)
  end

  test "validate returns true for phrase with extra whitespace" do
    phrase = "  abandon   ability   able   about   above   absent   absorb   abstract   absurd   abuse   access   accident  "

    assert @service.validate(phrase)
  end

  test "validate returns true for uppercase phrase" do
    phrase = "ABANDON ABILITY ABLE ABOUT ABOVE ABSENT ABSORB ABSTRACT ABSURD ABUSE ACCESS ACCIDENT"

    assert @service.validate(phrase)
  end

  test "validate returns false for empty string" do
    assert_not @service.validate("")
  end

  test "validate returns false for nil" do
    assert_not @service.validate(nil)
  end

  test "validate returns false for wrong word count" do
    phrase = "abandon ability able"

    assert_not @service.validate(phrase)
  end

  test "validate returns false for invalid words" do
    phrase = "abandon ability able about above absent absorb abstract absurd abuse access invalidword"

    assert_not @service.validate(phrase)
  end

  test "derive_key returns key for valid phrase" do
    phrase = @service.generate
    key = @service.derive_key(phrase, @salt)

    assert key.is_a?(String)
    assert_equal 32, key.bytesize
  end

  test "derive_key produces consistent key for same phrase and salt" do
    phrase = @service.generate

    key1 = @service.derive_key(phrase, @salt)
    key2 = @service.derive_key(phrase, @salt)

    assert_equal key1, key2
  end

  test "derive_key produces different keys for different phrases" do
    phrase1 = @service.generate
    phrase2 = @service.generate

    key1 = @service.derive_key(phrase1, @salt)
    key2 = @service.derive_key(phrase2, @salt)

    assert_not_equal key1, key2
  end

  test "derive_key produces different keys for different salts" do
    phrase = @service.generate
    salt1 = SecureRandom.hex(32)
    salt2 = SecureRandom.hex(32)

    key1 = @service.derive_key(phrase, salt1)
    key2 = @service.derive_key(phrase, salt2)

    assert_not_equal key1, key2
  end

  test "derive_key raises error for invalid phrase" do
    invalid_phrase = "invalid words here"

    assert_raises(Journals::MnemonicService::InvalidMnemonicError) do
      @service.derive_key(invalid_phrase, @salt)
    end
  end

  test "derive_key normalizes phrase before deriving" do
    phrase = "abandon ability able about above absent absorb abstract absurd abuse access accident"
    phrase_with_spaces = "  ABANDON   ABILITY   able   ABOUT   above   ABSENT   absorb   abstract   absurd   abuse   access   accident  "

    key1 = @service.derive_key(phrase, @salt)
    key2 = @service.derive_key(phrase_with_spaces, @salt)

    assert_equal key1, key2
  end

  test "class methods work as expected" do
    phrase = Journals::MnemonicService.generate
    assert Journals::MnemonicService.validate(phrase)

    key = Journals::MnemonicService.derive_key(phrase, @salt)
    assert_equal 32, key.bytesize
  end

  test "generated key can be used with encryption service" do
    phrase = @service.generate
    key = @service.derive_key(phrase, @salt)

    plaintext = "Secret message encrypted with mnemonic-derived key"
    encrypted = Journals::EncryptionService.encrypt(plaintext, key)
    decrypted = Journals::EncryptionService.decrypt(
      encrypted[:ciphertext],
      encrypted[:iv],
      key,
      auth_tag: encrypted[:auth_tag]
    )

    assert_equal plaintext, decrypted
  end
end
