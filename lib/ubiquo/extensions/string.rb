module Ubiquo
  module Extensions
    module String

      # Remove all non-alphanumeric characters from the string, trying to do 
      # a wide conversion (though non complete) of non-english characters 
      def urilize    
        pattern_replacements = [
                                [/[àáâäÀÁÂÄ]/, "a"],
                                [/[èéêëÈÉÊË]/, "e"],      
                                [/[ìíîïÌÍÎÏ]/, "i"],
                                [/[òóôöÒÓÔÖ]/, "o"],
                                [/[ùúûüÙÚÛÜ]/, "u"],
                                [/[\/(){}<>]/, "_"],
                                [/[ñÑ]/, "n"],
                                [/[çÇ]/, "c"],
                                [/[^\w]/, ''], # finally, discard all non-alphanumeric characters 
                               ]
        start_string = self.downcase.strip.gsub(" ", "")    
        pattern_replacements.inject(start_string) do |s, (pattern, replacement)| 
          s.gsub(pattern, replacement)
        end      
      end
    end
  end
end
