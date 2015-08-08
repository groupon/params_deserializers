describe 'deserialize_params_with', type: :controller do
  context 'without an explicit method name' do
    controller do
      include ParamsDeserializers

      deserializer = Class.new(ParamsDeserializer) do
        attributes :foo
      end

      deserialize_params_with deserializer, only: :update

      def update
        render text: ''
      end
    end

    it 'can call the deserialized_params getter' do
      routes.draw { get 'update' => 'anonymous#update' }
      put :update

      expect(controller).to respond_to :deserialized_params
    end

    it 'gets deserialized params when calling the deserialized_params getter' do
      routes.draw { get 'update' => 'anonymous#update' }
      put :update, foo: 'bar', baz: 'quux'

      expected = { foo: 'bar' }.with_indifferent_access
      expect(controller.deserialized_params).to eql expected
    end
  end

  context 'with an explicit method name' do
    controller do
      include ParamsDeserializers

      deserializer = Class.new(ParamsDeserializer) do
        attributes :foo
      end

      deserialize_params_with deserializer, as: :deserialized_params_foo, only: :update

      def update
        render text: ''
      end
    end

    it 'can call the deserialized_params getter' do
      routes.draw { get 'update' => 'anonymous#update' }
      put :update

      expect(controller).not_to respond_to :deserialized_params
      expect(controller).to respond_to :deserialized_params_foo
    end
  end
end
