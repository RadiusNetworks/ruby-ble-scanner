require 'ffi'

module Serhex
  extend FFI::Library

  enum :rblog_levels, [
      :undef, 0,
      :error,
      :warn,
      :info,
      :debug
  ]

  ffi_lib 'c'
  ffi_lib './ext/native/serhex/serhex.so'
  attach_function :configure_port, [:int, :int], :int
  attach_function :open_port, [:string], :int
  attach_function :send_cmd, [:string, :pointer, :int, :pointer], :int
  attach_function :send_cmd_with_delay, [:string, :pointer, :int, :pointer, :int], :int
  attach_function :set_rblog_level, [ :rblog_levels ], :void
end



