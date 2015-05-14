module Ble
  module Service
    class Data16 < Service::Base

      attr_reader :service_data

      def initialize(sd_bytes)
        super(sd_bytes)

        uuid_bytes = sd_bytes[0..1]

        @uuid = parse_uuid( uuid_bytes )

        @service_data = parse_service_data( sd_bytes[2..-1] )
        @service_name = lookup_service_id( uuid_bytes )
      end

      def parse_uuid(uuid_bytes)
        Ble.hexdump(uuid_bytes)
      end

      def parse_service_data(sdd_bytes)
        Ble.hexdump( sdd_bytes )
      end

      def to_s
        "#{self.class.name}: #{@uuid} ( #{@service_name} ) [ #{@service_data} ]"
      end
    end
  end
end