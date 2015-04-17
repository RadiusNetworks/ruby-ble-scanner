require_relative "ble_scanner"

ble_scanner = BleScanner.new("/dev/cu.usbmodem1")
ble_scanner.gap_discover {|bytes| puts bytes}