require "serhexr" # rbcomser with ruby wrapper
require_relative "serial_port_reader"
require_relative "bgapi_parser"

class BgapiError < StandardError; end
class BgapiError::Timeout < BgapiError; end


class Bgapi

  def seconds_to_ble_interval(sec)
    val = (1000*sec/(0.625)).to_i
    [val & 0xff, (val >> 8) & 0xff]
  end

  def initialize(port)
    @port = port
    @serial_port_reader = SerialPortReader.new(@port)
    gap_set_scan_parameters(0.040, 0.040, 1)
  end

  def pack(a)
    a.pack("C*")
  end

  def protocol_error(resp_bytes)
    case Ble.hexdump(resp_bytes[5..6])
      when /85 01/
        raise BgapiError::Timeout, "Command or Procedure failed due to timeout"
      else
        resp_bytes
    end
  end

  def parse_response(resp_bytes)
    case Ble.hexdump(resp_bytes)
      when /^06 80 02 00/
        protocol_error(resp_bytes)
      else resp_bytes
    end
  end

  def send_cmd(cmd, resp_len, port=@port)
    resp = Array.new(resp_len, 0).pack("C*")
    cmd_bytes = pack(cmd)
    p Ble.hexdump (cmd_bytes.chars)
    Serhexr.set_rblog_level(:error)
    Serhexr.send_cmd(port, cmd_bytes, cmd_bytes.size, resp)
    sleep 0.1
    parse_response(resp.chars)
  end

  def gap_set_scan_parameters(scan_interval_s, scan_window_s, active)
    scan_interval_bytes = seconds_to_ble_interval(scan_interval_s)
    scan_window_bytes = seconds_to_ble_interval(scan_window_s)
    active_int = active ? 1 : 0
    cmd = [0, 5, 6, 7,
           scan_interval_bytes[0], scan_interval_bytes[1],
           scan_window_bytes[0], scan_window_bytes[1],
           active_int
    ]
    resp_len = 80
    resp = send_cmd(cmd, resp_len)
    #p "gap_set_scan_parameters response: #{Ble.hexdump(resp.chars)}"
  end

  # BGAPI command
  def gap_discover(serial_port_reader=@serial_port_reader)
    mode = 2
    cmd = [0,1,6,2, mode]
    resp_len = 80
    resp = send_cmd(cmd, resp_len)
    serial_port_reader.on_data { |data| yield data }
  end

  def beacon_scan
    gap_discover { |bytes| yield BgapiParser::Start.new( BgapiParser::Base.new([], bytes.chars) ).next_obj }

  end

  def raw_scan
    gap_discover {|byte_str| yield byte_str.chars}
  end

  def hex_scan
    raw_scan{ |bytes| yield bytes.map{|b| sprintf("%02X", b.ord) }.join(" ") }
  end
end


#x = Bgapi.new("/dev/cu.usbmodem1").raw_scan{|data| puts data}

# x = Bgapi.new("/dev/cu.usbmodem1").beacon_scan do |parsed_obj|
#   if parsed_obj.is_a? BgapiParser::AdvBytes
#     puts "#{parsed_obj.beacon_company_name}, #{parsed_obj.hardware_manufacturer}, #{parsed_obj.rssi}, #{parsed_obj.sender_address} #{parsed_obj.adv_hex}"
#   else
#     puts "== skipped: #{parsed_obj.class} #{BgapiParser::hexdump parsed_obj.all_bytes}=="
#   end
# end
