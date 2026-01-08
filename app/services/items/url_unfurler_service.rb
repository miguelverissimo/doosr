# frozen_string_literal: true

require "meta_inspector"
require "timeout"

class Items::UrlUnfurlerService
  # Service for unfurling URLs in item titles.
  #
  # This service:
  # - Detects if item title contains a URL
  # - Fetches page metadata (title, description, image)
  # - Replaces item title with page title
  # - Downloads and attaches preview image via ActiveStorage
  # - Stores original URL and metadata in extra_data
  #
  # Returns: { success: Boolean, error: String }

  URL_REGEX = %r{https?://[^\s]+}i
  METADATA_TIMEOUT = 5
  IMAGE_DOWNLOAD_TIMEOUT = 5

  attr_reader :item

  def initialize(item)
    @item = item
  end

  def self.call(item)
    new(item).call
  end

  def call
    # Only unfurl if title contains a URL
    url = detect_url
    unless url
      ::Rails.logger.debug("URL unfurling: No URL detected in title: #{item.title}")
      return success_result
    end

    ::Rails.logger.info("URL unfurling: Detected URL in item #{item.id}: #{url}")
    ::Rails.logger.info("URL unfurling: URL length: #{url.length}")

    # Normalize URL (ensure it's properly formatted)
    normalized_url = normalize_url(url)
    ::Rails.logger.info("URL unfurling: Normalized URL: #{normalized_url}")

    # Fetch metadata with timeout
    page = fetch_metadata(normalized_url)
    unless page
      ::Rails.logger.warn("URL unfurling: Failed to fetch metadata for #{normalized_url}")
      return success_result(error: "Failed to fetch metadata")
    end

    ::Rails.logger.info("URL unfurling: Successfully fetched metadata for #{normalized_url}")

    # Update item with unfurled data
    unfurl_item(page, normalized_url)

    success_result
  rescue StandardError => e
    # Log error but don't fail - item creation should succeed regardless
    ::Rails.logger.error("URL unfurling failed for item #{item.id}: #{e.message}")
    ::Rails.logger.error(e.backtrace.join("\n"))
    success_result(error: e.message)
  end

  private

  def detect_url
    match = item.title.match(URL_REGEX)
    return nil unless match

    url = match[0]

    # Only unfurl HTTP/HTTPS URLs
    return nil unless url.match?(/\Ahttps?:\/\//i)

    # Remove trailing punctuation that might have been captured
    url = url.chomp(".").chomp(",").chomp(")").chomp("]").chomp("}")

    url
  end

  def normalize_url(url)
    # Ensure URL is properly formatted
    # Remove any whitespace
    url = url.strip

    # Validate it's a proper URI
    begin
      uri = ::URI.parse(url)
      # Reconstruct URL to ensure proper encoding
      normalized = uri.to_s
      ::Rails.logger.debug("URL unfurling: Normalized from #{url.length} to #{normalized.length} chars")
      normalized
    rescue ::URI::InvalidURIError => e
      ::Rails.logger.warn("URL unfurling: Invalid URI #{url}: #{e.message}")
      # Return original if parsing fails
      url
    end
  end

  def fetch_metadata(url)
    ::Rails.logger.info("URL unfurling: Attempting to fetch metadata from #{url}")
    start_time = ::Time.current

    result = ::Timeout.timeout(METADATA_TIMEOUT) do
      ::MetaInspector.new(
        url,
        connection: {
          headers: {
            "User-Agent" => "DooserApp/1.0 (URL Unfurler)"
          }
        },
        # Follow redirects
        allow_redirections: true,
        # Don't fail on missing images
        warn_level: :store
      )
    end

    elapsed = ((::Time.current - start_time) * 1000).round
    ::Rails.logger.info("URL unfurling: Successfully fetched metadata in #{elapsed}ms")
    result
  rescue ::Timeout::Error => e
    ::Rails.logger.warn("URL unfurling: Timeout after #{METADATA_TIMEOUT}s while fetching #{url}")
    nil
  rescue ::MetaInspector::RequestError => e
    ::Rails.logger.warn("URL unfurling: Request error for #{url}: #{e.message}")
    ::Rails.logger.warn("URL unfurling: Error class: #{e.class}")
    nil
  rescue ::MetaInspector::ParserError => e
    ::Rails.logger.warn("URL unfurling: Parser error for #{url}: #{e.message}")
    nil
  rescue StandardError => e
    ::Rails.logger.error("URL unfurling: Unexpected error fetching #{url}: #{e.class} - #{e.message}")
    ::Rails.logger.error("URL unfurling: Backtrace: #{e.backtrace.first(5).join("\n")}")
    nil
  end

  def unfurl_item(page, original_url)
    # Extract metadata
    title = extract_title(page)
    description = extract_description(page)
    image_url = extract_image_url(page)

    ::Rails.logger.info("URL Unfurling - Title: #{title}")
    ::Rails.logger.info("URL Unfurling - Description: #{description&.truncate(50)}")
    ::Rails.logger.info("URL Unfurling - Image URL: #{image_url}")

    # Update item
    ::ActiveRecord::Base.transaction do
      # Replace title with page title
      item.title = title

      # Store metadata in extra_data
      item.extra_data = (item.extra_data || {}).merge(
        "unfurled_url" => original_url,
        "unfurled_title" => title,
        "unfurled_description" => description,
        "unfurled_at" => ::Time.current.iso8601
      )

      # Download and attach image if available
      if image_url.present?
        ::Rails.logger.info("URL Unfurling - Attempting to download image...")
        attach_preview_image(image_url)
        ::Rails.logger.info("URL Unfurling - Image attached: #{item.preview_image.attached?}")
      else
        ::Rails.logger.warn("URL Unfurling - No image URL found")
      end

      # Save changes
      item.save!
    end
  end

  def extract_title(page)
    # Try multiple sources for title
    title = page.best_title.presence ||
            page.title.presence ||
            "Untitled"

    # Handle arrays (MetaInspector sometimes returns arrays)
    title = title.is_a?(Array) ? title.first : title
    title = title.to_s unless title.is_a?(String)

    # Clean up title (remove extra whitespace, newlines)
    title.strip.gsub(/\s+/, " ")
  end

  def extract_description(page)
    # Try multiple sources for description
    description = page.description.presence ||
                  page.meta_tags["property"]&.dig("og:description")

    return nil unless description

    # Handle arrays (MetaInspector sometimes returns arrays for meta tags)
    description = description.is_a?(Array) ? description.first : description
    return nil unless description.is_a?(String)

    # Clean up description
    description.strip.gsub(/\s+/, " ")
  end

  def extract_image_url(page)
    # Try to get Open Graph image first, then fallback to other images
    image_url = page.images.best.presence

    return nil unless image_url

    # Ensure it's an absolute URL
    image_url = page.url.merge(image_url).to_s if image_url.start_with?("/")

    image_url
  rescue StandardError => e
    ::Rails.logger.warn("Failed to extract image URL: #{e.message}")
    nil
  end

  def attach_preview_image(image_url)
    ::Timeout.timeout(IMAGE_DOWNLOAD_TIMEOUT) do
      # Download image
      uri = ::URI.parse(image_url)
      downloaded_image = uri.open(
        "User-Agent" => "DooserApp/1.0 (URL Unfurler)",
        redirect: true
      )

      # Extract filename from URL
      filename = ::File.basename(uri.path).presence || "preview.jpg"

      # Attach to item
      item.preview_image.attach(
        io: downloaded_image,
        filename: filename
      )
    end
  rescue ::Timeout::Error, ::OpenURI::HTTPError, StandardError => e
    # Continue without image if download fails
    ::Rails.logger.warn("Failed to download preview image from #{image_url}: #{e.message}")
  end

  def success_result(error: nil)
    { success: true, error: error }
  end
end
