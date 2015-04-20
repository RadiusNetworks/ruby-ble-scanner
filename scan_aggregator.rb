require_relative "ble_scanner"
require 'pp'

def beacon_string_to_i(b_a)
  b_a[0].to_i(16)+
  b_a[1].to_i(16) * 256 +
  b_a[2].to_i(16) * 256**2 +
  b_a[3].to_i(16) * 256**3
end

start = Time.now
iterations = 10
iteration_duration = 20 #seconds
counter = 1
beacon_counter_history = [0]
aggregator = {}
ble_scanner = BleScanner.new("/dev/cu.usbmodem1")
ble_scanner.gap_discover do |bytes|
  # beacon_counter = beacon_string_to_i( bytes.split(" ").last(5)[0..3] )
  # last_beacon_counter = beacon_counter_history[1]
  # beacon_counter_history.push beacon_counter
  # if beacon_counter_history.size > 3
  #   beacon_counter_history.shift
  # end
  # if beacon_counter_history[1] && ( beacon_counter - beacon_counter_history[1]) != 1
  #   puts "~~ #{beacon_counter_history[1]} - #{beacon_counter} ~~"
  # end
  puts "#{counter}:  #{bytes}"
  counter += 1
  # a = bytes.split(" ")
  # mac = a[6..11].reverse.join
  # if aggregator[mac]
  #   aggregator[mac][:current_count] += 1
  # else
  #   aggregator[mac] = { current_count: 1, past_counts: [] }
  # end
  #
  # dur = Time.now() - start
  #
  # if dur > iteration_duration
  #   aggregator.each do |mac, data|
  #     data[:past_counts] << data[:current_count]
  #     data[:current_count] = 0
  #   end
  #   pp aggregator
  #   start = Time.now()
  #
  #   iterations -= 1
  #   if iterations <= 0
  #     exit
  #   end
  # end

end