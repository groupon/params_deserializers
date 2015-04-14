require_relative '../lib/attribute'
require_relative '../lib/attribute_collection'

describe AttributeCollection do
  it 'raises an error when there is a name collision' do
    attrs = AttributeCollection.new
    attrs << Attribute.new(:foo)
    expect do
      attrs << Attribute.new(:foo)
    end.to raise_error(ParamsDeserializers::AttributeNameCollisionError)
  end
end
