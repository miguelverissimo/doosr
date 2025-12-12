# frozen_string_literal: true

class Views::Layouts::AuthLayout < Views::Base
  include Phlex::Rails::Layout

  private

  def render_flash_toasts
    Rails.logger.debug "=== FLASH DEBUG START (AUTH) ==="
    Rails.logger.debug "Flash notice: #{view_context.flash[:notice].inspect}"
    Rails.logger.debug "Flash alert: #{view_context.flash[:alert].inspect}"
    Rails.logger.debug "Flash toast: #{view_context.flash[:toast].inspect}"
    Rails.logger.debug "Flash keys: #{view_context.flash.keys.inspect}"
    
    return unless view_context.flash[:notice].present? || view_context.flash[:alert].present? || view_context.flash[:toast].present?

    # Create a unique key for this flash message
    flash_key = "#{view_context.flash[:notice]}#{view_context.flash[:alert]}#{view_context.flash[:toast]}".hash.to_s
    
    script_content = "if (!window.flashToastKeys) { window.flashToastKeys = {}; } "
    script_content += "if (window.flashToastKeys['#{flash_key}']) { } else { "
    script_content += "window.flashToastKeys['#{flash_key}'] = true; "
    script_content += "(function() { "
    script_content += "function showFlashToast() { "
    script_content += "var attempts = 0; "
    script_content += "var maxAttempts = 50; "
    script_content += "function tryShowToast() { "
    script_content += "attempts++; "
    script_content += "if (typeof window.toast !== 'undefined' && window.toast) { "
    
    # Handle flash[:toast] with full options
    if view_context.flash[:toast].present?
      toast_data = view_context.flash[:toast]
      Rails.logger.debug "Processing flash[:toast]: #{toast_data.inspect}"
      if toast_data.is_a?(Hash)
        message = toast_data[:message] || toast_data["message"] || ""
        description = toast_data[:description] || toast_data["description"] || ""
        type = toast_data[:type] || toast_data["type"] || "default"
        position = toast_data[:position] || toast_data["position"] || "top-center"
        
        script_content += "window.toast(#{message.to_json}, { type: #{type.to_json}, description: #{description.to_json}, position: #{position.to_json} }); "
      else
        script_content += "window.toast(#{toast_data.to_json}); "
      end
    end
    
    # Handle flash[:notice] as success toast
    if view_context.flash[:notice].present?
      Rails.logger.debug "Processing flash[:notice]: #{view_context.flash[:notice].inspect}"
      script_content += "window.toast(#{view_context.flash[:notice].to_json}, { type: 'success' }); "
    end
    
    # Handle flash[:alert] as danger toast
    if view_context.flash[:alert].present?
      Rails.logger.debug "Processing flash[:alert]: #{view_context.flash[:alert].inspect}"
      script_content += "window.toast(#{view_context.flash[:alert].to_json}, { type: 'danger' }); "
    end
    
    script_content += "} else if (attempts < maxAttempts) { "
    script_content += "setTimeout(tryShowToast, 100); "
    script_content += "} "
    script_content += "} "
    script_content += "tryShowToast(); "
    script_content += "} "
    script_content += "var flashToastListenerAdded = false; "
    script_content += "function addFlashToastListener() { "
    script_content += "if (flashToastListenerAdded) { return; } "
    script_content += "flashToastListenerAdded = true; "
    script_content += "if (typeof Turbo !== 'undefined') { "
    script_content += "document.addEventListener('turbo:load', showFlashToast, { once: true }); "
    script_content += "} else if (document.readyState === 'loading') { "
    script_content += "document.addEventListener('DOMContentLoaded', showFlashToast, { once: true }); "
    script_content += "} else { "
    script_content += "setTimeout(showFlashToast, 50); "
    script_content += "} "
    script_content += "} "
    script_content += "addFlashToastListener(); "
    script_content += "})(); "
    script_content += "}"

    Rails.logger.debug "Generated script content length: #{script_content.length}"
    Rails.logger.debug "=== FLASH DEBUG END (AUTH) ==="

    raw "<script type=\"text/javascript\">#{script_content}</script>".html_safe
  end

  def view_template
    doctype
    html do
      head do
        title { yield(:title).presence || "Doosr" }
        meta(name: "viewport", content: "width=device-width,initial-scale=1")
        meta(name: "apple-mobile-web-app-capable", content: "yes")
        meta(name: "apple-mobile-web-app-status-bar-style", content: "default")
        meta(name: "application-name", content: "Doosr")
        meta(name: "mobile-web-app-capable", content: "yes")
        meta(name: "theme-color", content: "#ffffff")
        raw(view_context.csrf_meta_tags)
        raw(view_context.csp_meta_tag)
        yield(:head)
        link(rel: "icon", href: "/icon.png", type: "image/png")
        link(rel: "icon", href: "/icon.svg", type: "image/svg+xml")
        link(rel: "apple-touch-icon", href: "/icon.png")
        link(rel: "manifest", href: pwa_manifest_path)
        raw(view_context.stylesheet_link_tag("tailwind", "data-turbo-track": "reload"))
        raw(view_context.stylesheet_link_tag("checkbox_fix", "data-turbo-track": "reload"))
        raw(view_context.javascript_importmap_tags)
      end

      body(data: { controller: "pwa" }, class: "dark") do
        render Components::Toast.new

        # Main content area with padding
        div(class: "mx-auto max-w-4xl px-4 py-8") do
          yield
        end
      end
    end
  end
end

