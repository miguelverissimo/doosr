# frozen_string_literal: true

require "openssl"

module Journals
  class MnemonicService
    WORD_COUNT = 12
    WORDLIST_PATH = Rails.root.join("lib/bip39_english.txt")
    PBKDF2_ITERATIONS = 2048
    KEY_LENGTH = 32

    class InvalidMnemonicError < StandardError; end

    def self.generate
      new.generate
    end

    def self.validate(phrase)
      new.validate(phrase)
    end

    def self.derive_key(phrase, salt)
      new.derive_key(phrase, salt)
    end

    def self.wordlist
      new.wordlist
    end

    def generate
      words = Array.new(WORD_COUNT) { wordlist.sample }
      words.join(" ")
    end

    def validate(phrase)
      return false if phrase.blank?

      words = phrase.strip.downcase.split(/\s+/)
      return false unless words.length == WORD_COUNT

      words.all? { |word| wordlist.include?(word) }
    end

    def derive_key(phrase, salt)
      raise InvalidMnemonicError, "Invalid mnemonic phrase" unless validate(phrase)

      normalized_phrase = phrase.strip.downcase.split(/\s+/).join(" ")

      OpenSSL::PKCS5.pbkdf2_hmac(
        normalized_phrase,
        salt,
        PBKDF2_ITERATIONS,
        KEY_LENGTH,
        OpenSSL::Digest::SHA256.new
      )
    end

    def wordlist
      @wordlist ||= File.readlines(WORDLIST_PATH).map(&:strip).reject(&:empty?)
    end
  end
end
