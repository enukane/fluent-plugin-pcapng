#
# Fluentd
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#

require 'fluent/input'

module Fluent
  class PcapngInput < Input
    Plugin.register_input('pcapng', self)

    require 'open3'
    require 'csv'
    require 'time'
    require 'shellwords'

    LONG="long"
    DOUBLE="double"
    STRING="string"
    TIME="time"

    def initialize
      super
    end

    config_param :tag, :string, :default => "pcapng"
    config_param :interface, :string, :default => 'ge0'
    config_param :convertdot, :string, :default => nil
    config_param :fields, :default => [] do |val|
      val.split(',')
    end
    config_param :types, :default => [] do |val|
      val.split(',')
    end
    config_param :extra_flags, :array, :default => []

    def configure(conf)
      super

      if @fields != nil and @fields == []
        raise ConfigError, "'fields' option is required on pcapng input"
      end

      if @types and @types.length != @fields.length
        raise ConfigError, "'types' length must be equal to 'fields' length"
      end
    end

    def start
      super

      @thread = Thread.new(&method(:run))
    end

    def shutdown
      if @th_tshark and @th_tshark.alive?
        Process.kill("INT", @th_tshark.pid)
      end
      @thread.join
    rescue => e
      log.error "pcapng failed to shutdown", :error => e.to_s,
        :error_class => e.class.to_s
      log.error_backtrace e.backtrace
    end

    def run
      options = build_options(@fields)
      options += build_extra_flags(@extra_flags)
      cmdline = "tshark -i #{Shellwords.escape(@interface)} -T fields -E separator=\",\" -E quote=d #{options}"
      log.debug format("pcapng: %s", cmdline)
      _stdin, stdout, stderr, @th_tshark = *Open3.popen3(cmdline)

      while @th_tshark.alive?
        collect_tshark_output(stdout)
      end
      stderr.each do |l|
        log.error(l.chomp)
      end
      raise RuntimeError, "tshark is not running"
    rescue => e
      log.error "unexpected error", :error => e.to_s
      log.error_backtrace e.backtrace
    end

    def build_options(fields)
      options = ""
      fields.each do |field|
        options += "-e #{Shellwords.escape(field)} "
      end
      return options
    end

    def build_extra_flags(extra_flags)
      options = ""
      valid_flag_re = /(?:-[a-zA-Z]|--[a-z\-]+)/
      extra_flags.each do |i|
        if !i.match(/^#{valid_flag_re}/)
          raise ArgumentError, format("Invalid flags in extra_flags %s", i)
        end

        # escape given flags here because it is easier to understand, or write,
        # extra_flags in fluentd config.
        (k, v) = i.split(/\s+/, 2)
        options += "#{Shellwords.escape(k)} "
        options += "#{Shellwords.escape(v)} " if v
      end
      return options
    end

    def collect_tshark_output(stdout)
      collected = []
      begin
        readlines_nonblock(stdout).each do |line|
          array = CSV.parse(line).flatten
          collected << array
        end
      rescue => e
        log.error "pcapng failed to read or parse line", :error => e.to_s,
          :error_class => e.class.to_s
      end

      collected.each do |ary|
        router.emit(@tag, Engine.now, generate_record(ary))
      end
    rescue => e
      log.error "pcapng failed to collect output from tshark",
        :error => e.to_s,
        :error_class => e.class.to_s
    end

    def readlines_nonblock(io)
      @nbbuffer = "" if @nbbuffer == nil
      @nbbuffer += io.read_nonblock(65535)
      lines = []
      while idx = @nbbuffer.index("\n")
        lines << @nbbuffer[0..idx-1]
        @nbbuffer = @nbbuffer[idx+1..-1]
      end
      return lines
    rescue
      return []
    end

    def generate_record(array)
      fields = @fields
      if fields.length != array.length
        return {}
      end
      carray = convert_types(array)
      if @convertdot
        fields = fields.map{|field| field.gsub(".", @convertdot)}
      end
      return Hash[[fields, carray].transpose]
    end

    def convert_types(array)
      return [array, @types].transpose.map{|val, type|
        convert_type(val, type)
      }
    end

    def convert_type val, type
      v = val.to_s.gsub("\"", "")
      v = "" if val == nil
      case type
      when LONG
        if v.is_a?(String) and v.match(/^0x[0-9a-fA-F]+$/)
          v = v.hex
        else
          v = v.to_i
        end
      when DOUBLE
        v = v.to_f
      when TIME
        v = Time.parse(v)
      end
      return v
    end
  end
end
