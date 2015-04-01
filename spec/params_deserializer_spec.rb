require_relative '../lib/params_deserializer'

describe ParamsDeserializer do
  describe 'basic' do

    subject do
      Class.new(ParamsDeserializer) do
        attributes :id, :name
      end
    end

    let(:params) do
      { id: 5, name: 'foo' }
    end

    it 'copies an old param to a new param' do
      instance = subject.new(params)
      new_params = instance.deserialize
      expect(new_params[:id]).to eql(params[:id])
      expect(new_params[:name]).to eql(params[:name])
    end
  end

  describe 'pseudo-params' do
    subject do
      Class.new(ParamsDeserializer) do
        attributes :id, :name
        def name; 'foo'; end
      end
    end

    let(:params) do
      { id: 5 }
    end

    it 'allows deserialization of a param that does not exist' do
      instance = subject.new(params)
      new_params = instance.deserialize
      expect(new_params[:id]).to eql(params[:id])
      expect(new_params[:name]).to eql('foo')
    end
  end

  describe 'overrides' do
    subject do
      Class.new(ParamsDeserializer) do
        attributes :foo

        def foo
          "bar"
        end
      end
    end

    it 'allows method access for params?' do
      instance = subject.new({foo: 'baz'})
      new_params = instance.deserialize

      expect(new_params[:foo]).to eql('bar')
    end
  end

  describe 'has_many' do
    subject do
      Class.new(ParamsDeserializer) do
        has_many :foos, to: :foos_attributes
      end
    end

    it 'puts the new key in to new_params' do
      instance = subject.new(foos: [{bar: 1}])
      new_params = instance.deserialize

      expect(new_params[:foos_attributes]).to eql([{bar: 1}])
    end
  end
end
