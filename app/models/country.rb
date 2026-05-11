class Country < ApplicationRecord
  validates :code, presence: true, uniqueness: { case_sensitive: false }
  validates :title, presence: true

  before_validation :upcase_code

  default_scope { order(:position, :title) }

  def self.ransackable_attributes(auth_object = nil)
    %w[id code title title_ru flag position created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  def self.find_by_code(code)
    where('UPPER(code) = ?', code.to_s.upcase).first
  end

  def display_title
    "#{flag} #{title}".strip
  end

  private

  def upcase_code
    self.code = code.to_s.strip.upcase if code.present?
  end
end