require 'minitest/autorun'
require 'minitest/pride'
require_relative '../lib/eson.rb'
require_relative './test_helpers.rb'

class TestEsonParser <  MiniTest::Unit::TestCase

  include TestHelpers
  
  def setup
    @valid_eson = get_valid_eson
  end

  def test_asm_generated
  end
  
end
