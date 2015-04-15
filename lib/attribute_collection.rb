require_relative 'errors'

class ParamsDeserializer
  class AttributeCollection < Array
    def <<(new_attr)
      if any? { |attr| attr.name == new_attr.name }
        raise AttributeNameCollisionError,
              "Attribute \"#{new_attr.name}\" was defined multiple times."
      end

      super
    end
  end
end
