require_relative "../lib/bluetooth_company_ids"

%w{base flags service manufacturer unknown}.each do |dep|
  require_relative "./ble/#{dep}"
end

 module Ble

   def self.hexdump(bytes)
     bytes.map{|b| sprintf("%02X", b.ord) }.join(" ")
   end

   EIR_DATA_TYPES = {
       0x01 => Ble::Flags,
       0x02 => Ble::Service, #ServiceClassUUID16Partial,
       0x03 => Ble::Service, #ServiceClassUUID16,
       0x04 => Ble::Service, #ServiceClassUUID32Partial,
       0x05 => Ble::Service, #ServiceClassUUID32,
       0x06 => Ble::Service, #ServiceClassUUID128Partial,
       0x07 => Ble::Service, #ServiceClassUUID128,
#       0x08 => Ble::LocalNameShort,
#       0x09 => Ble::LocalName,
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
#       0x16 => Ble::ServiceData,
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
      len = ble_bytes.shift.ord

      while size>0 && len>0
        next_type(len, ble_bytes)
        len_bytes = ble_bytes.shift
        len = (len_bytes && len_bytes.ord) || 0
      end
    end

    def next_type(len, bytes)
      #puts("type id: #{Ble.hexdump([bytes[0]])}")
      type_id = bytes.shift.ord
      type_data = bytes.shift(len-1)
      eir_type(type_id, type_data)
    end

    def eir_type(type_id, type_data)
      #puts "type id: #{type_id}  type_data: #{type_data}"
      if EIR_DATA_TYPES.include?(type_id) && type_data
        type_klass = EIR_DATA_TYPES[type_id]
        @ble_objs << type_klass.new(type_data)
      else
        @ble_objs << Unknown.new(type_data)
      end
    end

    def fetch
      @ble_objs
    end
  end

end