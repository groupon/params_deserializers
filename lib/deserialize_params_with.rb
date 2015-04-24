module ParamsDeserializers
  extend ActiveSupport::Concern

  included do
    attr_reader :deserialized_params
  end

  module ClassMethods
    def deserialize_params_with(deserializer, options = {})
      before_filter(options) do
        @deserialized_params = deserializer.new(params)
                                           .deserialize
                                           .with_indifferent_access
      end
    end
  end
end
