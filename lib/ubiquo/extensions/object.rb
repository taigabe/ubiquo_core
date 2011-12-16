module Ubiquo
  module Extensions
    module Object
      def to_bool
        ![false, 'false', '0', 0, 'f', nil].include?(self.respond_to?(:downcase) ? self.downcase : self)
      end
    end
  end
end
