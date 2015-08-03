require "serhexr" # rbcomser with ruby wrapper
require "em-serialport"

require 'colorize'
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

colors = [ :green, :blue, :magenta, :cyan, :red]
color_index = 0
uniq_objs = {}

x = Bgapi.new("/dev/cu.usbmodem1").beacon_scan do |ble_obj|
  count += 1
  data = {}
  now = Time.now
  elapsed_time = now - t0
  average_rate = count / elapsed_time

  #p ble_obj
  if ble_obj.respond_to?(:adv_bytes) #&& ble_obj.packet_type != 0
    puts "\033[2J" # clear screen

    puts
    puts "BDADDR:   #{ble_obj.sender_address}"
    puts "RSSI:     #{ble_obj.rssi}"
    puts "Packet:   #{ble_obj.packet_type_lookup}"
    puts "Addr:     #{ble_obj.address_type_lookup}"
    puts "Count:    #{count}"
    puts "Time:     #{elapsed_time.round(2)}"
    puts "Avg Rate: #{average_rate.round(2)}"

    uniq_id = "#{ble_obj.sender_address} #{ble_obj.adv_hex[0..30]}"
    data[:mac] = ble_obj.sender_address
    data[:hex] = ble_obj.adv_hex
    data[:count] = count
    data[:color] = uniq_objs[uniq_id] && uniq_objs[uniq_id][:color] || colors[color_index+=1]

    uniq_objs[uniq_id] = data

    (uniq_objs.values.sort{|o1, o2| o1[:mac] <=> o2[:mac]}).each do |data|
      if data[:color] && data[:hex].respond_to?(:red)
        puts "#{data[:count]}: #{data[:mac]} #{data[:hex]}".__send__(data[:color])
      else
        puts "#{data[:count]}: #{data[:mac]} #{data[:hex]}"
      end
    end
    #parsed_objs = Ble::Parser.new(ble_obj.adv_bytes).fetch
    #parsed_objs.each do |o|
    #end
   
    #puts "\033[#{lines+uniq_objs.size+1}A"
  end
end
