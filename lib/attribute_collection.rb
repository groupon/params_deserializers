require_relative 'errors'

class AttributeCollection < Array
  def <<(new_attr)
    if any? { |attr| attr[:final_key] == new_attr[:final_key] }
      raise ParamsDeserializers::AttributeNameCollisionError,
            "Attribute \"#{new_attr[:final_key]}\" was defined multiple times."
    end

    super
  end
end
