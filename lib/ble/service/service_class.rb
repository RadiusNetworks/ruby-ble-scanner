module Ble
  module Service
    class ServiceClass < Ble::Service::Base

      attr_reader :uuid

      def initialize(sc_bytes)
        super(sc_bytes)
        @uuid = parse_uuid(sc_bytes)
      end

      def parse_uuid(sc_bytes)
        Ble.hexdump(sc_bytes)
      end

      def to_s
        "#{self.class.name}: #{@uuid} ( #{@service_name} )"
      end
    end
  end
end