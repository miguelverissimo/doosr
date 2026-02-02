# frozen_string_literal: true

module Banking
  class TransactionRowHashService
    def self.generate(date:, description:, value:)
      normalized_value = value.to_s("F")
      data = "#{date.iso8601}|#{description.downcase}|#{normalized_value}"
      Digest::SHA256.hexdigest(data)
    end

    def self.generate_from_transaction(transaction)
      date_str = transaction.date&.iso8601 || ""
      desc_str = transaction.description&.downcase || ""
      normalized_value = transaction.value&.to_s("F") || "0"
      data = "#{date_str}|#{desc_str}|#{normalized_value}"
      Digest::SHA256.hexdigest(data)
    end
  end
end
