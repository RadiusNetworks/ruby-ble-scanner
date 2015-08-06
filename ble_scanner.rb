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
max_buffer_size = 60 #seconds

colors = [ :green, :blue, :magenta, :cyan, :light_magenta, :light_cyan, :red, :light_black, :light_red, :light_green, :yellow, :light_blue, :white, :light_white]
color_index = 0
uniq_objs = {}
obj_values = []
current_size = 0



def window10s(now, time_hash)
  time_hash.select{|t, data| now-t < 10 }
end

def array_average(arr)
  return "" if arr.empty?
  arr.inject{ |sum, el| sum + el }.to_f / arr.size
end

def sorted(objs)
  objs.values.sort{|o1, o2| o1[:mac] <=> o2[:mac]}
end

x = Bgapi.new("/dev/cu.usbmodem1").beacon_scan do |ble_obj|
  count += 1
  data = {}
  now = Time.now
  elapsed_time = now - t0
  average_rate = count / elapsed_time


  #p ble_obj
  if ble_obj.respond_to?(:adv_bytes) #&& ble_obj.packet_type != 0

    uniq_id = "#{ble_obj.sender_address} #{ble_obj.adv_hex[0..36]}"
    this_data = uniq_objs[uniq_id] ||= {}
    this_data[:data_window] ||= {}
    this_data[:data_window][now] = ble_obj.rssi
    this_data[:packet] = ble_obj.packet_type_lookup

    this10s = window10s(now, this_data[:data_window])

    this_data[:count10s] = this10s.size
    this_data[:time10s] = this10s.keys.last - this10s.keys.first

    this_data[:rate10s] = this_data[:count10s]/this_data[:time10s].to_f

    # delete old buffer data
    this_data[:data_window].delete_if{ |t, data| now-t > max_buffer_size}

    this_data[:window_rate] = this_data[:data_window].size/max_buffer_size.to_f

    this_data[:mac] = ble_obj.sender_address
    this_data[:hex] = ble_obj.adv_hex
    this_data[:main_count] = count
    this_data[:color] = uniq_objs[uniq_id] && uniq_objs[uniq_id][:color] || colors[color_index+=1]
    this_data[:my_count] ||= 0
    this_data[:my_count] += 1
    this_data[:my_rate] = this_data[:my_count]/elapsed_time

    # set cursor home
    puts "\33[0;0H"

    #clear screen
    puts "\033[2J"

    puts "BDADDR:   #{ble_obj.sender_address}"
    puts "RSSI:     #{ble_obj.rssi}"
    puts "Addr:     #{ble_obj.address_type_lookup}"
    puts "Count:    #{count}"
    puts "Time:     #{elapsed_time.round(2)}"
    puts "Avg Rate: #{average_rate.round(2)}"
    puts "Uniq:     #{uniq_objs.size}"
    lines = 9


    if current_size != uniq_objs.size
      obj_values = sorted(uniq_objs)
      current_size = uniq_objs.size
    end

    # puts "\33[9;0H"
    #puts "\033[2J" # clear screen
    obj_values.each do |data|
      #printf("|%15s|%6d|\n", "Cathy", 15)

      if data[:color] && data[:hex].respond_to?(:red)
        puts "#{data[:mac]}".__send__(data[:color])
        puts "  PACKET: #{data[:packet]}".__send__(data[:color])
        printf("  RATE  10s: %6.2f, window: %6.2f, rate: %6.2f\n".__send__(data[:color]), data[:rate10s], data[:window_rate], data[:my_rate])
        printf("  COUNT 10s: %3d(%5.2f), window: %4d, my total: %6d, aggr total: %7d\n".__send__(data[:color]), data[:count10s], data[:time10s], data[:data_window].size, data[:my_count], data[:main_count])
        printf("  RSSI  10s: %6.2f, window: %6.2f\n".__send__(data[:color]), array_average(this10s.values), array_average(this_data[:data_window].values))
        puts "    #{data[:hex]}".__send__(data[:color])
        #lines = lines + 5
      else # no color support
        puts "#{data[:mac]} #{data[:hex]}"
      #
      #   #lines = lines + 1
      end
    end

    #parsed_objs = Ble::Parser.new(ble_obj.adv_bytes).fetch
    #parsed_objs.each do |o|
    #end
    #p lines
    #puts "\033[#{lines}A"
  end
end
