class ActionController::Base
  def self.deserialize_params_with(deserializer, options = {})
    attr_reader :deserialized_params

    before_filter(options) do
      @deserialized_params = deserializer.new(params).deserialize
    end
  end
end
