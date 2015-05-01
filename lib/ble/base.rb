module Ble
  class Base

    alias_method :base_to_s, :to_s

    attr_accessor :data, :bytes

    def initialize(bytes)
      @data = Ble.hexdump(bytes)
      @bytes = bytes
    end

    def inspect
      base_to_s
    end

    def to_s
      "#{self.class.name}: #{@data}"
    end

  end
end