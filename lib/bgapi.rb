require_relative "serhex" # rbcomser with ruby wrapper
require_relative "serial_port_reader"
require_relative "bgapi_parser"


class Bgapi
  def initialize(port)
    @port = port
    @serial_port_reader = SerialPortReader.new(@port)
  end

  def pack(a)
    a.pack("C*")
  end

  def send_cmd(cmd, resp_len, port=@port)
    resp = Array.new(resp_len, 0).pack("C*")
    cmd_bytes = pack(cmd)
    Serhex.set_rblog_level(:error)
    Serhex.send_cmd(port, cmd_bytes, cmd_bytes.size, resp)
    sleep 0.1
    resp
  end

  # BGAPI command
  def gap_discover(serial_port_reader=@serial_port_reader)
    mode = 1
    cmd = [0,1,6,2, mode]
    resp_len = 80
    resp = send_cmd(cmd, resp_len)
    serial_port_reader.on_data { |data| yield data }
  end

  def beacon_scan
    gap_discover { |bytes| yield BgapiParser::Start.new( BgapiParser::Base.new([], bytes.chars) ).next_obj }

  end

  def raw_scan
    gap_discover {|bytes| yield bytes.chars.map{|b| sprintf("%02X", b.ord) }.join(" ")}
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
