require "serhexr" # rbcomser with ruby wrapper
require "em-serialport"

require_relative "./lib/bgapi"
require_relative "./lib/ble"

require 'pp'
found_devices = {}

# - Position the Cursor:
# \033[<L>;<C>H
# Or
# \033[<L>;<C>f
# puts the cursor at line L and column C.
# - Move the cursor up N lines:
# \033[<N>A
# - Move the cursor down N lines:
# \033[<N>B
# - Move the cursor forward N columns:
# \033[<N>C
# - Move the cursor backward N columns:
# \033[<N>D
#
# - Clear the screen, move to (0,0):
#     \033[2J
# - Erase to end of line:
# \033[K
#
# - Save cursor position:
# \033[s
# - Restore cursor position:
# \033[u

count = 0
t0 = Time.now

x = Bgapi.new("/dev/cu.usbmodem1").beacon_scan do |ble_obj|

  p ble_obj
  if ble_obj.respond_to?(:adv_bytes) #&& ble_obj.packet_type != 0

    # puts
    # puts "BDADDR:  #{ble_obj.sender_address}"
    # puts "RSSI:    #{ble_obj.rssi}"
    # puts "Packet:  #{ble_obj.packet_type_lookup}"
    # puts "Addr:    #{ble_obj.address_type_lookup}"
    # puts "  #{ble_obj.adv_hex}"
    #
    # parsed_objs = Ble::Parser.new(ble_obj.adv_bytes).fetch
    # parsed_objs.each do |o|
    #   puts "    #{o}"
    # end
    #
    # puts "\033[9A"

  end
end