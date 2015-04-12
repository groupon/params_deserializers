require 'spec_helper'

class StubController < ActionController::Base
  deserialize_params_with(Class.new(ParamsDeserializer) do
    attributes :foo
  end, only: :update)

  def update
    render text: ''
  end
end

describe StubController, type: :controller do
  around :each do |example|
    Rails.application.routes.draw { get '/stub_controller' => 'stub#update' }
    example.run
    Rails.application.reload_routes!
  end

  it 'can call the deserialized method on the params object' do
    put :update
    expect(controller.params).to respond_to :deserialized
  end

  it 'gets deserialized params when calling deserialized' do
    put :update, foo: 'bar', baz: 'quux'
    expect(controller.params.deserialized).to eql(foo: 'bar')
  end
end
