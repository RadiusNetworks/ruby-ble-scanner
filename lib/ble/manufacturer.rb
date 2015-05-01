module Ble
  class Manufacturer < Base

    attr_reader :manufacturer

    def initialize(sc_bytes)
      super(sc_bytes)
      @manufacturer = lookup_manufacturer_id( sc_bytes[0..1] )
    end

    def lookup_manufacturer_id(id_bytes)
      id = Ble.hexdump(id_bytes).downcase
      BluetoothCompanyIds.new.find_by_id(id)
    end
  end
end