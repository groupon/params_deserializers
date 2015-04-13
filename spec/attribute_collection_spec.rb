require_relative '../lib/attribute_collection'

describe AttributeCollection do
  it 'raises an error when there is a name collision' do
    attrs = AttributeCollection.new
    attrs << { final_key: :foo }
    expect do
      attrs << { final_key: :foo }
    end.to raise_error(ParamsDeserializers::AttributeNameCollisionError)
  end
end
