class EnumeratorIO
  attr_accessor :enum

  def initialize(enum)
    @enum = enum
  end

  def read(length, outbuf=nil)
    @enum.next
  rescue StopIteration
    nil
  end
end