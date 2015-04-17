class BluetoothCompanyIds
  def initialize(filename=nil)
    @company_list = {}
    filename = filename || "#{File.dirname(__FILE__)}/bluetooth_company_ids.txt"
    File.open(filename).each do |line|
      # get rid of an ugly unicode issue
      line_byte_array = line.chars.map{|c| c.ord == 8203 ? "" : c }

      line = line_byte_array.join


      items = line.split("\t")
      ids = items[1].match(/.*0x([0-9a-zA-Z]{2}).*([0-9a-zA-Z]{2})/)
      name = items[2]

      id = ids[2] + " " + ids[1]
      id.downcase!
      @company_list[id] = name.strip
    end
  end

  def company_list
    @company_list
  end
end
