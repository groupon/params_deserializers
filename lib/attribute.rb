class Attribute
  attr_reader :name, :present_if

  def initialize(original_name, name = original_name, present_if = nil)
    @original_name, @name, @present_if = original_name, name, present_if
    @present_if ||= -> { params_root.has_key?(original_name) }
  end
end
