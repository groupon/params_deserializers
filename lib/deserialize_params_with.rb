module ParamsDeserializers
  extend ActiveSupport::Concern

  module ClassMethods
    def deserialize_params_with(deserializer, options = {})
      deserialized_params_name = options.delete(:as).try(:to_sym) || :deserialized_params
      attr_reader deserialized_params_name

      before_filter(options) do
        instance_variable_set("@#{deserialized_params_name}", deserializer.new(params).deserialize)
      end
    end
  end
end
