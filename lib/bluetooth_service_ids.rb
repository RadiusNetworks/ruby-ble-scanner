class BluetoothServiceIds
  def initialize(filename=nil)
    @service_list = {}
    filename = filename || "#{File.dirname(__FILE__)}/bluetooth_service_ids.txt"
    File.open(filename).each do |line|
      # get rid of an ugly unicode issue
      line_byte_array = line.chars.map{|c| c.ord == 8203 ? "" : c }

      line = line_byte_array.join


      items = line.split(",")
      list_id = items[0]
      name = items[1]

      id = spaced_hex(list_id)
      @service_list[id] = name.strip
    end
  end

  def spaced_hex(id)
    byte_strs = id.scan(/.{2}/)
    byte_strs.join(" ").downcase
  end

  def service_list
    @service_list
  end

  def find_by_id(id)
    @service_list[id] || "Unknown"
  end
end
