# frozen_string_literal: true

require "digest"

module Banking
  class RecurringDetectionService
    Result = Struct.new(:success, :groups_created, :groups_updated, :transactions_linked, :errors, keyword_init: true)

    AMOUNT_TOLERANCE = 0.10
    DESCRIPTION_SIMILARITY_THRESHOLD = 0.80
    MIN_OCCURRENCES = 3
    INTERVAL_TOLERANCE_DAYS = 5

    INTERVALS = {
      weekly: 7,
      monthly: 30,
      yearly: 365
    }.freeze

    def initialize(user)
      @user = user
      @groups_created = 0
      @groups_updated = 0
      @transactions_linked = 0
      @errors = []
    end

    def call
      detect_recurring_patterns
      Result.new(
        success: @errors.empty?,
        groups_created: @groups_created,
        groups_updated: @groups_updated,
        transactions_linked: @transactions_linked,
        errors: @errors
      )
    rescue StandardError => e
      Result.new(
        success: false,
        groups_created: @groups_created,
        groups_updated: @groups_updated,
        transactions_linked: @transactions_linked,
        errors: [ "Detection failed: #{e.message}" ]
      )
    end

    private

    def detect_recurring_patterns
      transactions = @user.bank_transactions
        .where(recurring_group_id: nil)
        .order(date: :asc)
        .to_a

      return if transactions.empty?

      clusters = cluster_similar_transactions(transactions)

      clusters.each do |cluster|
        next if cluster.size < MIN_OCCURRENCES

        detected_frequency = detect_frequency(cluster)
        next unless detected_frequency

        create_or_update_recurring_group(cluster, detected_frequency)
      end
    end

    def cluster_similar_transactions(transactions)
      clusters = []
      used = Set.new

      transactions.each do |transaction|
        next if used.include?(transaction.id)

        cluster = [ transaction ]
        used.add(transaction.id)

        transactions.each do |other|
          next if used.include?(other.id)
          next unless similar?(transaction, other)

          cluster << other
          used.add(other.id)
        end

        clusters << cluster if cluster.size >= MIN_OCCURRENCES
      end

      clusters
    end

    def similar?(t1, t2)
      description_similar?(t1.description, t2.description) &&
        amount_similar?(t1.value, t2.value)
    end

    def description_similar?(desc1, desc2)
      similarity_score(normalize_description(desc1), normalize_description(desc2)) >= DESCRIPTION_SIMILARITY_THRESHOLD
    end

    def normalize_description(desc)
      desc.to_s.downcase.gsub(/[^a-z0-9\s]/, "").gsub(/\s+/, " ").strip
    end

    def similarity_score(s1, s2)
      return 1.0 if s1 == s2
      return 0.0 if s1.empty? || s2.empty?

      longer = [ s1.length, s2.length ].max.to_f
      distance = levenshtein_distance(s1, s2)
      (longer - distance) / longer
    end

    def levenshtein_distance(s1, s2)
      m = s1.length
      n = s2.length
      return m if n == 0
      return n if m == 0

      d = Array.new(m + 1) { Array.new(n + 1) }

      (0..m).each { |i| d[i][0] = i }
      (0..n).each { |j| d[0][j] = j }

      (1..m).each do |i|
        (1..n).each do |j|
          cost = s1[i - 1] == s2[j - 1] ? 0 : 1
          d[i][j] = [ d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + cost ].min
        end
      end

      d[m][n]
    end

    def amount_similar?(v1, v2)
      return true if v1 == v2 && v1.zero?
      return false if v1.zero? || v2.zero?
      return false if v1.positive? != v2.positive?

      avg = (v1.abs + v2.abs) / 2.0
      diff = (v1.abs - v2.abs).abs
      (diff / avg) <= AMOUNT_TOLERANCE
    end

    def detect_frequency(cluster)
      return nil if cluster.size < MIN_OCCURRENCES

      sorted = cluster.sort_by(&:date)
      intervals = []

      sorted.each_cons(2) do |t1, t2|
        intervals << (t2.date - t1.date).to_i
      end

      return nil if intervals.empty?

      avg_interval = intervals.sum.to_f / intervals.size

      INTERVALS.each do |frequency, expected_days|
        if (avg_interval - expected_days).abs <= INTERVAL_TOLERANCE_DAYS ||
           (avg_interval - expected_days).abs <= (expected_days * 0.2)
          return frequency.to_s
        end
      end

      nil
    end

    def create_or_update_recurring_group(cluster, frequency)
      sorted = cluster.sort_by(&:date)
      pattern = generate_description_pattern(cluster)
      avg_amount = cluster.map { |t| t.value.to_f }.sum / cluster.size

      existing = @user.recurring_groups.find_by(description_pattern: pattern)

      if existing
        update_existing_group(existing, sorted, avg_amount)
      else
        create_new_group(pattern, sorted, avg_amount, frequency)
      end
    end

    def generate_description_pattern(cluster)
      first = normalize_description(cluster.first.description)
      return first if cluster.size == 1

      words = first.split
      return first if words.empty?

      cluster[1..].each do |transaction|
        other_words = normalize_description(transaction.description).split
        words = words.select { |w| other_words.include?(w) }
      end

      words.any? ? words.join(" ") : normalize_description(cluster.first.description)
    end

    def create_new_group(pattern, sorted_transactions, avg_amount, frequency)
      group = @user.recurring_groups.create!(
        name: generate_name(pattern),
        description_pattern: pattern,
        average_amount: avg_amount.round(2),
        frequency: frequency,
        last_occurrence: sorted_transactions.last.date,
        expected_next: calculate_expected_next(sorted_transactions.last.date, frequency),
        occurrence_count: sorted_transactions.size,
        active: true
      )

      sorted_transactions.each { |t| t.update!(recurring_group: group) }

      @groups_created += 1
      @transactions_linked += sorted_transactions.size
    rescue ActiveRecord::RecordInvalid => e
      @errors << "Failed to create group for '#{pattern}': #{e.message}"
    end

    def update_existing_group(group, sorted_transactions, avg_amount)
      new_transactions = sorted_transactions.reject { |t| t.recurring_group_id == group.id }
      return if new_transactions.empty?

      new_transactions.each { |t| t.update!(recurring_group: group) }

      all_transactions = group.bank_transactions.reload
      new_avg = all_transactions.map { |t| t.value.to_f }.sum / all_transactions.size
      last_date = all_transactions.maximum(:date)

      group.update!(
        average_amount: new_avg.round(2),
        last_occurrence: last_date,
        expected_next: calculate_expected_next(last_date, group.frequency),
        occurrence_count: all_transactions.size
      )

      @groups_updated += 1
      @transactions_linked += new_transactions.size
    rescue ActiveRecord::RecordInvalid => e
      @errors << "Failed to update group '#{group.name}': #{e.message}"
    end

    def generate_name(pattern)
      pattern.split.map(&:capitalize).join(" ").truncate(50)
    end

    def calculate_expected_next(last_date, frequency)
      case frequency.to_s
      when "weekly"
        last_date + 7.days
      when "monthly"
        last_date + 1.month
      when "yearly"
        last_date + 1.year
      else
        nil
      end
    end
  end
end
