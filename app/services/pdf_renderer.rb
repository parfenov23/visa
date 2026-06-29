# frozen_string_literal: true

require "ferrum"

# Renders an HTML string to a PDF (binary string) using headless Chrome via Ferrum.
# Replaces the previous wkhtmltopdf/wicked_pdf pipeline.
class PdfRenderer
  # CDP Page.printToPDF options (snake_case keys are camelCased by Ferrum).
  # Margins are in inches; 0.2in ≈ 5mm, matching the old WickedPdf config.
  DEFAULT_PDF_OPTIONS = {
    format: :A4,
    landscape: false,
    # scale MUST stay 1.0 so CSS millimetre sizes (e.g. the 40 mm seal) print
    # true-to-size 1:1. The template is laid out to fit A4 at 100%.
    scale: 1.0,
    print_background: true,
    prefer_css_page_size: false,
    margin_top: 0.2,
    margin_bottom: 0.2,
    margin_left: 0.2,
    margin_right: 0.2
  }.freeze

  def self.render(html, **options)
    new.render(html, **options)
  end

  def render(html, **options)
    browser = build_browser
    browser.content = html
    browser.pdf(encoding: :binary, **DEFAULT_PDF_OPTIONS.merge(options))
  ensure
    browser&.quit
  end

  private

  def build_browser
    opts = {
      headless: true,
      timeout: 20,
      process_timeout: 20,
      # Required when running as root inside a container.
      browser_options: { "no-sandbox" => nil }
    }
    path = ENV["FERRUM_BROWSER_PATH"].presence
    opts[:browser_path] = path if path

    Ferrum::Browser.new(**opts)
  end
end