require 'mac_vendor'

class MacVendorLookup
  def initialize
    @mac_vendor = MacVendor.new :use_local => true
    @mac_vendor.preload_cache_via_local_data
  end

  def mac(mac_address)
    @mac_vendor.lookup(mac_address)
  end
end
