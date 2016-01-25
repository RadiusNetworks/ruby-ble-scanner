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
@shutdown_t0 = Time.now
max_buffer_size = 60 #seconds

@colors = [ :green, :blue, :magenta, :cyan, :red, :yellow, :white]
@color_index = 0
uniq_objs = {}
obj_values = []
current_size = 0
mac_filter = nil
user_input = nil

ARGV.each do |arg|
  if arg.match /[0-9a-zA-Z]{2}:[0-9a-zA-Z]{2}:[0-9a-zA-Z]{2}:[0-9a-zA-Z]{2}:[0-9a-zA-Z]{2}:[0-9a-zA-Z]{2}/
    mac_filter = (mac_filter && mac_filter.unshift(arg)) || [arg]
  end
end
mac_filter.uniq! if mac_filter

screen = Doze::Screen.instance

win0 = Doze::Window.new(lines: 8, scroll: false)
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
  @last_win_pos ||= 8
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

# shutdown after an hour of no activity
def shutdown?
  Time.now - @shutdown_t0 > 3600
end

def user_activity
  @shutdown_t0 = Time.now
end

def shutdown
  puts 'Shutdown timer expired, exiting'
  yield
  exit(0)
end

win0.out "Waiting for scan data"

x = Bgapi.new("/dev/cu.usbmodem1").beacon_scan do |ble_obj|
  shutdown{ puts "Need to shutdown curses gracefully" } if shutdown?

  if mac_filter
    next unless ble_obj
    next unless ble_obj.respond_to? :sender_address
    next unless mac_filter.include? ble_obj.sender_address
  end

  win0.set_pos([0,0])

  data = {}
  now = Time.now
  elapsed_time = now - t0

  # win0.prep "BDADDR: "
  # win0.prep "RSSI: "
  # win0.prep "Addr Type: "
  # win0.prep "Count:    #{count}"
  # win0.prep "Time:     #{elapsed_time.round(2)}"
  # win0.prep "Avg Rate: #{average_rate.round(2)}"
  # win0.prep "Uniq:     #{uniq_objs.size}"
  # win0.refresh


  #p ble_obj
  ble_wins = 0
  if ble_obj.respond_to?(:adv_bytes) #&& ble_obj.packet_type != 0
    count += 1
    average_rate = count / elapsed_time

    win0.set_pos([0,0])

    win0.prep "BDADDR:   #{ble_obj.sender_address}"
    win0.prep "RSSI:     #{ble_obj.rssi}"
    win0.prep "Addr:     #{ble_obj.address_type_lookup}"
    win0.prep "Count:    #{count}"
    win0.prep "Time:     #{elapsed_time.round(2)}"
    win0.prep "Avg Rate: #{average_rate.round(2)}"
    win0.prep "Uniq:     #{uniq_objs.size}"
    win0.refresh

    uniq_id = "#{ble_obj.sender_address} #{ble_obj.adv_hex}"
    this_data = uniq_objs[uniq_id] ||= {}
    this_data[:all] = BgapiParser.hexdump(ble_obj.all_bytes)
    this_data[:bg_class] = ble_obj.packet_class
    this_data[:bg_command] = ble_obj.packet_command
    this_data[:data_window] ||= {}
    this_data[:data_window][now] = ble_obj.rssi
    this_data[:packet] = ble_obj.packet_type_lookup
    this_data[:address_type] = ble_obj.address_type_lookup

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

    if current_size != uniq_objs.size
      obj_values = sorted(uniq_objs)
      current_size = uniq_objs.size
    end

    # puts "\33[9;0H"
    #puts "\033[2J" # clear screen
    obj_values.each do |data|

      data[:pane].prep("  #{data[:mac]}", data[:color])
      data[:pane].prep("  PKT TYPE: #{data[:packet]}   #{data[:address_type]}", data[:color])
      data[:pane].prep("  RATE  10s: %6.2f, window: %6.2f, rate: %6.2f" %[data[:rate10s], data[:window_rate], data[:my_rate]], data[:color])
      data[:pane].prep("  COUNT 10s: %3d(%5.2f), window: %4d, my total: %6d, aggr total: %7d" % [data[:count10s], data[:time10s], data[:data_window].size, data[:my_count], data[:main_count]], data[:color])
      data[:pane].prep("  RSSI  10s: %6.2f, window: %6.2f" % [array_average(this10s.values), array_average(this_data[:data_window].values)], data[:color])
      data[:pane].prep("    #{data[:hex]}", data[:color])
      # data[:pane].prep("    #{data[:bg_class]} #{data[:bg_command]}: #{data[:all]}", data[:color])
      data[:pane].refresh
      #lines = lines + 5
    end
  end

  # put into separate task
  user_input = win0.getch
  if user_input == "r"
    #reset
    user_activity
    @last_win_pos = 11
    screen.clear
    uniq_objs = {}
    count = 0
    t0 = Time.now
    @color_index = 0
    screen.refresh
  end
end
