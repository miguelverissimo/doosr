# frozen_string_literal: true

module MarkdownHelper
  def render_markdown(text)
    return "" if text.blank?

    html = ::Commonmarker.to_html(text,
      options: {
        parse: { smart: true },
        render: { unsafe: false }  # Sanitize for XSS protection
      }
    )

    # Additional sanitization with allowed tags
    sanitize(html, tags: %w[
      p br strong em ul ol li blockquote code pre a h1 h2 h3 h4 h5 h6
      table thead tbody tr th td hr del ins mark
    ], attributes: %w[href title])
  end
end
