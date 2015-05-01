require_relative "lib/serhex" # rbcomser with ruby wrapper
require "em-serialport"

require_relative "./lib/bgapi"

found_devices = {}

x = Bgapi.new("/dev/cu.usbmodem1").beacon_scan do |parsed_obj|
  found_devices[parsed_obj.sender_address] = parsed_obj

  found_devices.each do |mac, data|
    print "#{mac}: #{data.adv_hex}\n"
  end

  found_devices.each do
    print "\r\e[1A"
  end

end