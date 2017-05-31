require "helper"
require "fluent/test/driver/input"

class PcapngInputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    id pcap_input
    tag pcap.dns.query
    interface em0
    fields frame.time_epoch,dns.qry.name,dns.qry.type,dns.qry.class,dns.id,ip.src,ip.dst
    extra_flags [ "-Y dns.flags.response == 0", "-f port 53" ]
    types double,string,long,long,long,string,string
    convertdot :
  ]
  def create_driver(config = CONFIG)
    Fluent::Test::Driver::Input.new(Fluent::PcapngInput).configure(config)
  end

  def test_configure
    instance = create_driver.instance
    assert_equal "em0", instance.interface
    assert_equal ["frame.time_epoch", "dns.qry.name", "dns.qry.type",
                  "dns.qry.class", "dns.id", "ip.src", "ip.dst"],
                  instance.fields
    assert_equal ["-Y dns.flags.response == 0", "-f port 53"], instance.extra_flags
  end

  def test_build_extra_flags
    instance = create_driver.instance
    assert_equal "-Y dns.flags.response\\ \\=\\=\\ 0 -f port\\ 53 ", instance.build_extra_flags(instance.extra_flags)
  end

  def test_build_extra_flags_with_long_flag_no_value
    config = %[
      fields frame.time_epoch,dns.qry.name,dns.qry.type,dns.qry.class,dns.id,ip.src,ip.dst
      extra_flags [ "--long-flag" ]
      types double,string,long,long,long,string,string
    ]
    instance = create_driver(config).instance
    assert_equal "--long-flag ", instance.build_extra_flags(instance.extra_flags)
  end

  def test_build_extra_flags_with_long_flag_value
    config = %[
      fields frame.time_epoch,dns.qry.name,dns.qry.type,dns.qry.class,dns.id,ip.src,ip.dst
      extra_flags [ "--long-flag     value" ]
      types double,string,long,long,long,string,string
    ]
    instance = create_driver(config).instance
    assert_equal "--long-flag value ", instance.build_extra_flags(instance.extra_flags)
  end

  def test_build_extra_flags_with_invalid_flag
    config = %[
      fields frame.time_epoch,dns.qry.name,dns.qry.type,dns.qry.class,dns.id,ip.src,ip.dst
      extra_flags [ "not-valid" ]
      types double,string,long,long,long,string,string
    ]
    instance = create_driver(config).instance
    assert_raise ArgumentError do instance.build_extra_flags(instance.extra_flags) end
  end

  def test_build_extra_flags_with_invalid_flag_and_value
    config = %[
      fields frame.time_epoch,dns.qry.name,dns.qry.type,dns.qry.class,dns.id,ip.src,ip.dst
      extra_flags [ "not-valid value" ]
      types double,string,long,long,long,string,string
    ]
    instance = create_driver(config).instance
    assert_raise ArgumentError do instance.build_extra_flags(instance.extra_flags) end
  end

  def test_build_options_with_valid_flags
    instance = create_driver.instance
    assert_equal "-e frame.time_epoch -e dns.qry.name -e dns.qry.type -e dns.qry.class -e dns.id -e ip.src -e ip.dst ", instance.build_options(instance.fields)
  end
end
