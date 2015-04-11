class ActionController::Base
  def self.deserialize_params_with(deserializer, options = {})
    include DeserializeParams

    before_filter(options) do
      deserialize_params(deserializer)
    end
  end
end

module DeserializeParams
  private

  def deserialize_params(deserializer)
    params.define_singleton_method(:deserialized) do
      @deserialized ||= deserializer.new(self).deserialize
    end
  end
end
