require "serhexr" # rbcomser with ruby wrapper
require "em-serialport"

require 'doze'
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

@colors = [ :green, :blue, :magenta, :cyan, :red, :yellow, :white]
@color_index = 0
uniq_objs = {}
obj_values = []
current_size = 0



screen = Doze::Screen.instance

win0 = Doze::Window.new(lines: 10, scroll: false)
win0.window.nodelay = true
@last_win_pos = nil

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

def new_ble_pane
  @last_win_pos ||= 11
  pane = Doze::Window.new(lines: 7, scroll: false, pos: @last_win_pos)
  @last_win_pos += 7
  return pane
end

def next_color
  color = @colors[@color_index]
  @color_index += 1
  @color_index = 0 if @color_index == @colors.size
  color
end

win0.out "Waiting for scan data"

x = Bgapi.new("/dev/cu.usbmodem1").beacon_scan do |ble_obj|
  win0.set_pos([0,0])

  data = {}
  now = Time.now
  elapsed_time = now - t0
  average_rate = count / elapsed_time

  # win0.prep "BDADDR: "
  # win0.prep "RSSI: "
  # win0.prep "Addr Type: "
  # win0.prep "Count:    #{count}"
  # win0.prep "Time:     #{elapsed_time.round(2)}"
  # win0.prep "Avg Rate: #{average_rate.round(2)}"
  # win0.prep "Uniq:     #{uniq_objs.size}"
  # win0.refresh

  count += 1


  #p ble_obj
  ble_wins = 0
  if ble_obj.respond_to?(:adv_bytes) #&& ble_obj.packet_type != 0
    win0.set_pos([0,0])

    win0.prep "BDADDR:   #{ble_obj.sender_address}"
    win0.prep "RSSI:     #{ble_obj.rssi}"
    win0.prep "Addr:     #{ble_obj.address_type_lookup}"
    win0.prep "Count:    #{count}"
    win0.prep "Time:     #{elapsed_time.round(2)}"
    win0.prep "Avg Rate: #{average_rate.round(2)}"
    win0.prep "Uniq:     #{uniq_objs.size}"
    win0.refresh
    status_pos_end = 10

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
    this_data[:color] = uniq_objs[uniq_id] && uniq_objs[uniq_id][:color] || next_color
    this_data[:my_count] ||= 0
    this_data[:my_count] += 1
    this_data[:my_rate] = this_data[:my_count]/elapsed_time
    this_data[:pane] ||= new_ble_pane

    # # set cursor home
    # puts "\33[0;0H"
    #
    # #clear screen
    # puts "\033[2J"





    if current_size != uniq_objs.size
      obj_values = sorted(uniq_objs)
      current_size = uniq_objs.size
    end

    # puts "\33[9;0H"
    #puts "\033[2J" # clear screen
    obj_values.each do |data|

      data[:pane].prep("  #{data[:mac]}", data[:color])
      data[:pane].prep("  PKT TYPE: #{data[:packet]}", data[:color])
      data[:pane].prep("  RATE  10s: %6.2f, window: %6.2f, rate: %6.2f" %[data[:rate10s], data[:window_rate], data[:my_rate]], data[:color])
      data[:pane].prep("  COUNT 10s: %3d(%5.2f), window: %4d, my total: %6d, aggr total: %7d" % [data[:count10s], data[:time10s], data[:data_window].size, data[:my_count], data[:main_count]], data[:color])
      data[:pane].prep("  RSSI  10s: %6.2f, window: %6.2f" % [array_average(this10s.values), array_average(this_data[:data_window].values)], data[:color])
      data[:pane].prep("    #{data[:hex]}", data[:color])
      data[:pane].refresh
      #lines = lines + 5
    end


    input = win0.getch
    if input == "r"
      #reset
      @last_win_pos = 11
      screen.clear
      uniq_objs = {}
      count = 0
      t0 = Time.now
      @color_index = 0

      screen.refresh

    end

  end
end
