module BgapiParser

  def self.hexdump(bytes)
    bytes.map{|b| sprintf("%02X", b.ord) }.join(" ")
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
      packet_class = interesting_bytes(1).last.ord
      #puts "packet class: #{packet_class}"

      # resets the bytes of interest to just the event payload
      # rather than including all the header bytes
      @bytes_of_interest = @unprocessed_bytes.take(payload_length)
      #update_bytes(payload_length)

      #p @bytes_of_interest
      # @sp_enum = ConsumeArray.new(@sp_enum.take(payload_length))
      # #p next_bytes
      # #next_bytes = @sp_enum[0]
      # #p @sp_enum
      #
      # @bytes_so_far.concat( next_bytes )
      # packet_class = next_bytes[0].ord
      #
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

      packet_command = interesting_bytes(1).first.ord

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
      @all_bytes[4].unpack('c').first
    end

    def packet_type
      @all_bytes[5].ord
    end

    def sender_address
      hexdump(@all_bytes[6..11].reverse).split(" ").join(":")
    end

    def address_type
      @all_bytes[12].ord
    end

    def bond
      @all_bytes[13].ord
    end

    def scan_response_length
      @all_bytes[14].ord
    end

    def next_obj
      @bytes_of_interest =  interesting_bytes(11)
      BgapiParser::AdvBytes.new(self).next_obj
    end
  end

  class AdvBytes < ScanResponseHeader

    def adv_bytes
      # grabs the last
      hexdump(@bytes_of_interest.last(scan_response_length))
    end

    def next_obj
       #@bytes_of_interest.take(scan_response_length)
      #@bytes_of_interest.length
      #p scan_response_length
      interesting_bytes(scan_response_length)
      #p @bytes_of_interest.length
      #puts hexdump(@bytes_of_interest)
      self
    end
  end
end