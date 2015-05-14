require_relative "../lib/bluetooth_company_ids"
require_relative "../lib/bluetooth_service_ids"

%w{base flags service service/service_class service/data_16 manufacturer local_name unknown}.each do |dep|
  require_relative "./ble/#{dep}"
end

 module Ble

   def self.hexdump(bytes)
     bytes.map{|b| sprintf("%02X", b.ord) }.join(" ")
   end

   EIR_DATA_TYPES = {
       0x01 => Ble::Flags,
       0x02 => Ble::Service::ServiceClass, #ServiceClassUUID16Partial,
       0x03 => Ble::Service::ServiceClass, #ServiceClassUUID16,
       0x04 => Ble::Service::ServiceClass, #ServiceClassUUID32Partial,
       0x05 => Ble::Service::ServiceClass, #ServiceClassUUID32,
       0x06 => Ble::Service::ServiceClass, #ServiceClassUUID128Partial,
       0x07 => Ble::Service::ServiceClass, #ServiceClassUUID128,
       0x08 => Ble::LocalName, # short version
       0x09 => Ble::LocalName,
#       0x0a => Ble::TxPowerLevel,
#
#       0x0d => Ble::DeviceClass,
#       0x0e => Ble::Pairing::Hash::C192,
#       0x0f => Ble::Pairing::Randomizer::R192,
#       0x10 => Ble::SecurityManager::TkValue,
#       0x11 => Ble::SecurityManager::OOBFlags,
#       0x12 => Ble::SlaveConnectionIntervalRange,
#
#       0x14 => Ble::ServiceSolicitationUUID16,
#       0x15 => Ble::ServiceSolicitationUUID128,
        0x16 => Ble::Service::Data16,
#       0x17 => Ble::TargetAddress::Public,
#       0x18 => Ble::TargetAddress::Random,
#       0x19 => Ble::Appearance,
#
#       0x1a => Ble::AdvertisingInterval,
#       0x1b => Ble::DeviceAddress,
#       0x1c => Ble::Role,
#       0x1d => Ble::Pairing::Hash::C256,
#       0x1e => Ble::Pairing::Random::R256,
#       0x1f => Ble::ServiceSolicitationUUID32,
#       0x20 => Ble::ServiceDataUUID32,
#       0x21 => Ble::ServiceDataUUID128,
#       0x22 => Ble::SecureConnections::ConfirmationValue,
#       0x23 => Ble::SecureConnections::RandomValue,
#
#       0x3d => Ble::Information3D,
#
       0xFF => Ble::Manufacturer
  }

  class Parser
    attr_accessor :ble_objs

    def initialize(ble_bytes)
      @ble_objs = []
      size = ble_bytes.size
      len_byte = ble_bytes.shift
      len = (len_byte && len_byte.ord) || 0

      while size>0 && len>0
        @ble_objs << next_type(len, ble_bytes)

        len_bytes = ble_bytes.shift
        len = (len_bytes && len_bytes.ord) || 0
      end
    end

    def next_type(len, bytes)
      #puts("type id: #{Ble.hexdump([bytes[0]])}")
      type_id_bytes = bytes.shift
      return "unkown" unless type_id_bytes
      type_id = type_id_bytes.ord
      type_data = bytes.shift(len-1)
      eir_type(len, type_id, type_data)
    end

    def eir_type(len, type_id, type_data)
      #puts "type id: #{type_id}  type_data: #{type_data}"
      type = nil
      if EIR_DATA_TYPES.include?(type_id) && type_data
        type_klass = EIR_DATA_TYPES[type_id]
        type = type_klass.new(type_data)
      else
        type = Unknown.new(len, type_id, type_data)
      end
      type
    end

    def fetch
      @ble_objs
    end
  end

end