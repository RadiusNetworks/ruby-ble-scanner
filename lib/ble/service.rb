module Ble
  module Service

    class Base < Ble::Base
      attr_reader :service_name

      def initialize(service_bytes)
        super(service_bytes)
        @lookup = BluetoothServiceIds.new
        @service_name = lookup_service_id(service_bytes)
      end

      def fix_id(id_bytes)
        Ble.hexdump(id_bytes).downcase
      end

      def lookup_service_id(id_bytes)
        id = fix_id(id_bytes)
        p @lookup
        @lookup.find_by_id(id.downcase)
      end
    end
  end
end