require_relative "lib/serhex" # rbcomser with ruby wrapper
require "em-serialport"

require_relative "./lib/bgapi"
require_relative "./lib/ble"

require 'pp'
found_devices = {}

x = Bgapi.new("/dev/cu.usbmodem1").beacon_scan do |ble_obj|

  if ble_obj.respond_to?(:adv_bytes)
    parsed_objs = Ble::Parser.new(ble_obj.adv_bytes).fetch
    puts "-------"
    puts ble_obj.sender_address
    parsed_objs.each do |o|
      puts o
    end
    puts "------"

  end
end