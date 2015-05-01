module Ble
  class Flags < Base

    Settings = {
        1 => "Limited Discoverable Mode",
        2 => "General Discoverable Mode",
        4 => "BR/EDR Not Supported",
        8 => "Simultaneous LE and BR/EDR (Controller)",
        16 => "Simultaneous LE and BR/EDR (Controller)"
    }

    attr_reader :settings, :flag_val

    def initialize(flag_bytes)
      super(flag_bytes)
      @flag_val = flag_bytes[0].ord
      @settings = parse_flag(@flag_val)
    end

    def parse_flag(flag_val)
      settings = []
      Settings.keys.each do |setting_flag|
        settings << Settings[flag_val & setting_flag]
      end
      settings.compact
    end

    def to_s
      "#{self.class.name}: #{@flag_val} [ #{@settings.join(', ')} ]"
    end
  end
end
