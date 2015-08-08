class ParamsDeserializer
  describe AttributeCollection do
    it 'raises an error when there is a name collision' do
      attrs = AttributeCollection.new
      attrs << Attribute.new(:foo)
      expect do
        attrs << Attribute.new(:foo)
      end.to raise_error(AttributeCollection::NameCollisionError)
    end
  end
end
