require_relative "serhex" # rbcomser with ruby wrapper
require "em-serialport"

class BleScanner
  def initialize(port=nil)
    @port = port || "/dev/cu.usbmodem1"
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

  def gap_discover(port=@port)
    mode = 1
    cmd = [0,1,6,2, mode]
    resp_len = 80
    resp = send_cmd(cmd, resp_len)
    EM.run do
      serial = EventMachine.open_serial(port, 115200, 8, nil, 1)
      serial.on_data do |data|
        yield data.chars.map{|b| sprintf("%02X", b.ord) }.join(" ")
      end
    end
  end
end
