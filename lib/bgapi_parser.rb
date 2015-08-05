
require_relative "bluetooth_company_ids"
require_relative "mac_vendor_lookup"

module BgapiParser
  Company_Bluetooth_Ids = BluetoothCompanyIds.new.company_list
  MacLookup = MacVendorLookup.new

  def self.hexdump(bytes)
    bytes.map{|b| sprintf("%02X", b.ord) }.join(" ")
  end

  # make sure the order is network byte order, so the order the raw bytes appear over the air
  def self.company_bluetooth_name(id_byte_array)
    id = hexdump(id_byte_array).downcase
    BgapiParser::Company_Bluetooth_Ids[id] || "Unknown"
  end

  class Base
    attr_accessor :bytes_of_interest, :unprocessed_bytes, :all_bytes

    def initialize(bytes_of_interest, unprocessed_bytes)
      @bytes_of_interest = bytes_of_interest
      @unprocessed_bytes = unprocessed_bytes
      @all_bytes = @unprocessed_bytes.dup
    end

    def interesting_bytes(n)
      @bytes_of_interest += @unprocessed_bytes.shift(n)
    end

    def hexdump(bytes)
      BgapiParser.hexdump(bytes)
    end
  end

  class Start < Base
    def initialize(prev_obj)
      @bytes_of_interest = prev_obj.bytes_of_interest
      @unprocessed_bytes = prev_obj.unprocessed_bytes
      @all_bytes = prev_obj.all_bytes
    end

    def fix_missing_initial_byte
      # assume event response
      @bytes_of_interest = []
      @all_bytes.unshift(0x80)
      @unprocessed_bytes = @all_bytes.dup
    end

    def payload_length
      @all_bytes[1].ord
    end

    def next_obj
      interesting_bytes(2)

      stream_type = @bytes_of_interest[0].ord

      case stream_type
        when 0
          BgapiParser::Response.new(self).next_obj
        when 128
          BgapiParser::Event.new(self).next_obj
        else
          # for some reason the first byte can be missed, this
          # will try and recover from that
          if @bytes_of_interest[1] = 0x06
            #fix_missing_initial_byte
            bytes = [0x80].concat @all_bytes
            BgapiParser::Start.new( BgapiParser::Base.new([], bytes))
          else
            self
          end
      end
    end
  end

  class Response < Start
    def next_obj
      self
    end
  end

  class Event < Start

    def next_obj
      #packet_class = interesting_bytes(1).last.ord
      #puts "packet class: #{packet_class}"

      def packet_class
        @all_bytes[2].ord
      end

      def packet_command
        @all_bytes[3].ord
      end

      # resets the bytes of interest to just the event payload
      # rather than including all the header bytes
      def event_bytes
        @all_bytes.last(payload_length)
      end

      case packet_class
        when 0x06
          BgapiParser::Gap.new(self).next_obj
        else
          self
      end
    end
  end

  class Gap < Event

    def next_obj
      case packet_command
        when 0x00
          BgapiParser::ScanResponseHeader.new(self).next_obj
        else
          self
      end
    end
  end

  class ScanResponseHeader < Gap
    def rssi
      # unpack as a signed byte
      event_bytes[0].unpack('c').first
    end

    def packet_type
      event_bytes[1].ord
    end

    def packet_type_lookup
      case packet_type
        when 0
          "advertisement"
        when 4
          "scan response"
        else
         "unknown: #{packet_type}"
      end
    end

    def sender_address
      hexdump(event_bytes[2..7].reverse).split(" ").join(":")
    end

    def hardware_manufacturer
      MacLookup.mac(sender_address)[:name]
    end

    def address_type
      event_bytes[8].ord
    end

    def address_type_lookup
      case address_type
        when 0
          "public"
        when 1
          "random"
        else
          "unknown: #{address_type}"
      end
    end

    def bond
      event_bytes[9].ord
    end

    def scan_response_length
      event_bytes[10].ord
    end

    def next_obj
      @bytes_of_interest =  interesting_bytes(11)
      BgapiParser::AdvBytes.new(self).next_obj
    end
  end

  class AdvBytes < ScanResponseHeader

    def adv_bytes
      # grabs the last
      event_bytes.last(scan_response_length)
    end

    def adv_hex
      hexdump(adv_bytes)
    end

    def beacon_company_id
      adv_bytes[5..6]
    end

    def beacon_company_name
      BgapiParser.company_bluetooth_name(beacon_company_id)
    end

    def next_obj
      interesting_bytes(scan_response_length)
      self
    end
  end
end