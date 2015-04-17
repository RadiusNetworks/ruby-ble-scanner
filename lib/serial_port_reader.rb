require "em-serialport"

class SerialPortReader
  def initialize(port)
    @port = port
  end

  def on_data
    EM.run do
      serial = EventMachine.open_serial(@port, 115200, 8, nil, 1)
      serial.on_data do |data|
        yield data
      end
    end
  end

end