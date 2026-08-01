# frozen_string_literal: true

require "rqrcode"
require "base64"

# Генерирует QR-код с данными туриста для PDF-приглашения (чистый Ruby, без
# нативных расширений — rqrcode + chunky_png).
#
# Отдаём PNG как data-URI (а не SVG): SVG, растеризованный headless-Chrome,
# теряет чёткость границ модулей и не сканируется; растровый PNG с «тихой зоной»
# читается надёжно.
#
# Уровень коррекции :m (~15%) — оптимум для нашего payload: круглое лого в
# центре перекрывает лишь ~7% площади, что укладывается в бюджет M с запасом,
# зато QR получается меньшей версии (крупнее модули), чем при :q/:h, и надёжно
# сканируется даже при низком разрешении — проверено на растре реального PDF
# при 110/150/300 dpi (в т.ч. «экранное» 110 dpi).
class QrCodeGenerator
  DEFAULT_LEVEL   = :m
  DEFAULT_SIZE    = 600  # px, крупно — печатается чётко при любом масштабе
  DEFAULT_BORDER  = 4    # модулей «тихой зоны» (обязательна для сканирования)

  def self.data_uri(text, **options)
    new(text, **options).data_uri
  end

  def initialize(text, level: DEFAULT_LEVEL, size: DEFAULT_SIZE, border_modules: DEFAULT_BORDER)
    @text           = text.to_s
    @level          = level
    @size           = size
    @border_modules = border_modules
  end

  # PNG QR-кода в виде data-URI для вставки в <img src="...">.
  def data_uri
    png = RQRCode::QRCode.new(@text, level: @level).as_png(
      size:           @size,
      border_modules: @border_modules,
      fill:           "white",
      color:          "black"
    )
    "data:image/png;base64,#{Base64.strict_encode64(png.to_s)}"
  end
end
