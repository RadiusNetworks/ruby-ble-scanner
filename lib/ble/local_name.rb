module Ble
  class LocalName < Base

    attr_reader :local_name

    def initialize(bytes)
      super(bytes)
      @local_name = local_name(bytes)
    end

    def local_name(name_bytes)
      name_bytes.join
    end

    def to_s
      "#{self.class.name}: ( #{@local_name} )"
    end
  end
end