class Ring < Array
  attr_reader :max_size

  def initialize(enum = nil, size:)
    @max_size = size
    enum.each { |e| self << e } if enum
  end

  def <<(el)
    if self.size < @max_size || @max_size.nil?
      super
    else
      self.shift
      self.push(el)
    end
  end

  alias :push :<<
end
