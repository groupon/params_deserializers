class ParamsDeserializer
  class AttributeCollection < Array
    class NameCollisionError < StandardError; end

    def <<(new_attr)
      if any? { |attr| attr.name == new_attr.name }
        raise NameCollisionError,
              "Attribute \"#{new_attr.name}\" was defined multiple times."
      end

      super
    end
  end
end
