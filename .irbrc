
require "irb/completion"

module Enumerable
  def progress
    return to_enum(__method__) unless block_given?
    progress = 0
    out_of = self.size
    return self.each do |item|
      progress += 1
      if STDOUT.isatty
        print "\r#{progress} out of #{out_of}"
        print "\n" if progress == out_of
      end
      yield item
    end
  end
end

class Object
  def interesting_methods
    return self.methods - Object.new.methods
  end
end
