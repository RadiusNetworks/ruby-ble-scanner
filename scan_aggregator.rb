require_relative "ble_scanner"
require 'pp'

counter = 1

ble_scanner = BleScanner.new("/dev/cu.usbmodem1")

ble_scanner.gap_discover do |bytes|

  puts "#{counter}:  #{bytes}"
  counter += 1
end