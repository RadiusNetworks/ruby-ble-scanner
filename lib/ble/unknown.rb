module Ble
  class Unknown < Base

    def initialize(len, type_id, type_data)
      @len = len
      @type_id = type_id
      super(type_data)
    end

    def to_s
      "#{self.class.name}: len: #{@len} type id: #{@type_id} data: #{@data}"
    end
  end
end