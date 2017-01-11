require 'irb/completion'
require 'pp'
IRB.conf[:AUTO_INDENT]=true

class Object
  def interesting_methods
    self.methods - Object.new.methods
  end
end

class Module
  def interesting_methods
    self.methods - Math.methods
  end
end

class Class
  def interesting_methods
    self.methods - Class.methods
  end
end

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

class Integer
  def magic_number
    return self.to_s(16).chars.each_slice(2).to_a.map(&:join).map{|d|d.to_i(16)}.map(&:chr).join
  end
end

class String
  def magic_number
    return self.chars.mpa(&:ord).map{|c|c.to_i(16)}.join.to_i(16)
  end
end
