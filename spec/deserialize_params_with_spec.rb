require 'spec_helper'

class StubController < ActionController::Base
  deserialize_params_with Class.new(ParamsDeserializer) do
    attributes :foo
  end
end

describe StubController do
  it "has a deserialize method on the params object"
end
