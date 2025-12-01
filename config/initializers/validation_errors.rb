module ActiveModel
  class Errors
    def messages_single
      messages.to_hash.transform_values do |error|
        error.is_a?(Array) ? error[0] : error
      end
    end
  end
end
