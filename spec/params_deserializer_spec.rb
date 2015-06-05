require_relative '../lib/params_deserializer'

describe ParamsDeserializer do
  describe '#deserialize' do
    it 'returns a HashWithIndifferentAccess' do
      deserializer = Class.new(ParamsDeserializer).new({})
      expect(deserializer.deserialize).to be_a ::ActiveSupport::HashWithIndifferentAccess
    end
  end

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
      new_params = subject.new(params).deserialize
      expect(new_params[:id]).to eql(params[:id])
      expect(new_params[:name]).to eql(params[:name])
    end
  end

  describe 'overrides' do
    subject do
      Class.new(ParamsDeserializer) do
        attributes :foo
        def foo; 'bar'; end
      end
    end

    it 'allows method access for params?' do
      instance = subject.new({foo: 'baz'})
      new_params = instance.deserialize

      expect(new_params[:foo]).to eql('bar')
    end
  end

  describe 'overrides with context' do
    subject do
      Class.new(ParamsDeserializer) do
        attributes :foo
        def foo; params[:foo] << 'baz'; end
      end
    end

    it 'allows methods to access params' do
      instance = subject.new({foo: 'bar'})
      new_params = instance.deserialize

      expect(new_params[:foo]).to eql('barbaz')
    end
  end

  describe 'single attribute' do
    context 'without a rename' do
      subject do
        Class.new(ParamsDeserializer) do
          def bar; 'baz'; end
          attributes :foo, :bar
        end
      end

      it 'copies an old param to a new param' do
        new_params = subject.new({ foo: 'bar' }).deserialize
        expect(new_params[:foo]).to eql('bar')
      end

      it 'does not overwrite an override method when it is defined before `attribute` is called' do
        new_params = subject.new({ bar: 'quux' }).deserialize
        expect(new_params[:bar]).to eql('baz')
      end
    end

    context 'with a rename' do
      subject do
        Class.new(ParamsDeserializer) do
          def new_quux; 'corge'; end
          attribute :foo, rename_to: :foo_bar
          attribute :quux, rename_to: :new_quux
        end
      end

      it 'allows an attribute to be renamed' do
        new_params = subject.new({ foo: 'baz' }).deserialize

        expect(new_params[:foo_bar]).to eql('baz')
        expect(new_params[:foo]).to be_nil
      end

      it 'does not overwrite an override method when it is defined before `attribute` is called' do
        new_params = subject.new({ quux: 'grault' }).deserialize
        expect(new_params[:new_quux]).to eql('corge')
      end

      it 'creates and calls the post-rename method' do
        deserializer = subject.new({ foo: 'baz' })
        expect(deserializer).to receive(:foo_bar)
        expect(deserializer).to_not respond_to(:foo)
        deserializer.deserialize
      end
    end
  end

  describe 'has_many' do
    context 'with overrides' do
      subject do
        Class.new(ParamsDeserializer) do
          has_many :foos, rename_to: :foos_attributes
        end
      end

      it 'puts the new key in to new_params' do
        instance = subject.new(foos: [{bar: 1}])
        new_params = instance.deserialize

        expect(new_params).to have_key :foos_attributes
        expect(new_params).not_to have_key :foos
      end
    end

    context 'without overrides' do
      subject do
        Class.new(ParamsDeserializer) do
          has_many :foos
        end
      end

      it 'defaults to the key provided' do
        instance = subject.new(foos: [{bar: 1}])
        new_params = instance.deserialize

        expect(new_params).to have_key :foos
      end
    end

    context 'with a child deserializer' do
      it 'uses a provided child deserializer for each item in a has_many relationship' do
        deserializer = Class.new(ParamsDeserializer) do
          child_deserializer = Class.new(ParamsDeserializer) do
            attributes :baz
          end

          has_many :foos, deserializer: child_deserializer
        end

        new_params = deserializer.new(foos: [{ bar: 1, baz: 2},
                                             { bar: 3, baz: 4 }]).deserialize

        expected = [{ baz: 2 }, { baz: 4 }].map(&:with_indifferent_access)
        expect(new_params[:foos]).to eql expected
      end
    end

    context 'with a nil value for the has_many relationship' do
      it 'returns nil without a child deserializer' do
        deserializer = Class.new(ParamsDeserializer) do
          has_many :foos
        end

        expect(deserializer.new(foos: nil).deserialize[:foos]).to be_nil
      end

      it 'returns nil with a child deserializer' do
        deserializer = Class.new(ParamsDeserializer) do
          child_deserializer = Class.new(ParamsDeserializer) do
            attributes :baz
          end

          has_many :foos, deserializer: child_deserializer
        end

        expect(deserializer.new(foos: nil).deserialize[:foos]).to be_nil
      end
    end
  end

  describe 'formatting keys' do
    it 'formats both root keys and child keys' do
      deserializer = Class.new(ParamsDeserializer) do
        format_keys :snake_case
        root :fooBar
        attributes :bazQuux
      end
      new_params = deserializer.new(fooBar: { bazQuux: 'corge' }).deserialize

      expect(new_params[:fooBar]).to be_nil
      expect(new_params[:foo_bar][:bazQuux]).to be_nil
      expect(new_params[:foo_bar][:baz_quux]).to eql 'corge'
    end

    it 'does not format keys of a child deserializer' do
      deserializer = Class.new(ParamsDeserializer) do
        format_keys :snake_case

        child_deserializer = Class.new(ParamsDeserializer) do
          attributes :bazQuux
        end

        has_many :fooBars, deserializer: child_deserializer
      end

      new_params = deserializer.new(fooBars: [{ bazQuux: 'corge' }]).deserialize

      expect(new_params[:foo_bars][0][:bazQuux]).to eql('corge')
      expect(new_params[:foo_bars][0][:baz_quux]).to be_nil
    end

    it 'allows different key formats for parent and child deserializers' do
      deserializer = Class.new(ParamsDeserializer) do
        format_keys :snake_case

        child_deserializer = Class.new(ParamsDeserializer) do
          format_keys :lower_camel
          attributes :baz_quux
        end

        has_many :fooBars, deserializer: child_deserializer
      end

      new_params = deserializer.new(fooBars: [{ baz_quux: 'corge' }]).deserialize

      expect(new_params[:foo_bars][0][:bazQuux]).to eql('corge')
      expect(new_params[:foo_bars][0][:baz_quux]).to be_nil
    end

    describe 'with no format option passed in' do
      subject do
        Class.new(ParamsDeserializer) do
          attributes :camelCase
        end
      end

      it 'does not transform key case' do
        new_params = subject.new(camelCase: 'foo').deserialize
        expect(new_params[:camelCase]).to eql('foo')
        expect(new_params[:CamelCase]).to be_nil
        expect(new_params[:camel_case]).to be_nil
      end
    end

    describe 'snake_case' do
      subject do
        Class.new(ParamsDeserializer) do
          attributes :camelCase
          format_keys :snake_case
        end
      end

      it 'transforms all keys to snake_case' do
        new_params = subject.new(camelCase: 'foo').deserialize
        expect(new_params[:camel_case]).to eql('foo')
        expect(new_params[:camelCase]).to be_nil
      end
    end

    describe 'CamelCase' do
      subject do
        Class.new(ParamsDeserializer) do
          attributes :snake_case
          format_keys :camel_case
        end
      end

      it 'transforms all keys to CamelCase' do
        new_params = subject.new(snake_case: 'foo').deserialize
        expect(new_params[:SnakeCase]).to eql('foo')
        expect(new_params[:snake_case]).to be_nil
      end
    end

    describe 'lowerCamel' do
      subject do
        Class.new(ParamsDeserializer) do
          attributes :snake_case
          format_keys :lower_camel
        end
      end

      it 'transforms all keys to lowerCamel' do
        new_params = subject.new(snake_case: 'foo').deserialize
        expect(new_params[:snakeCase]).to eql('foo')
        expect(new_params[:snake_case]).to be_nil
      end
    end
  end

  context 'with a root key' do
    let(:deserializer) do
      Class.new(ParamsDeserializer) do
        root :foo
        attributes :bar
      end
    end

    it 'keeps the root key by default' do
      new_params = deserializer.new(foo: { bar: 'baz' }).deserialize

      expect(new_params[:foo][:bar]).to eql('baz')
    end

    describe 'when the incoming params are missing the root key' do
      it 'raises a MissingRootKey exception' do
        expect do
          deserializer.new(bar: 'baz').deserialize
        end.to raise_error ParamsDeserializer::MissingRootKeyError
      end
    end

    context 'when the discard option is true' do
      before { deserializer.root :foo, discard: true }

      it 'discards the root key when the discard option is true' do
        new_params = deserializer.new(foo: { bar: 'baz' }).deserialize

        expect(new_params[:foo]).to be_nil
        expect(new_params[:bar]).to eql('baz')
      end
    end
  end

  describe 'present_if' do
    context 'without present_if' do
      subject do
        Class.new(ParamsDeserializer) do
          attributes :id, :name
        end
      end

      let(:params) do
        { id: 5, name: 'foo' }
      end

      it 'leaves undefined params undefined' do
        params.delete(:name)
        new_params = subject.new(params).deserialize
        expect(new_params).to_not have_key :name
      end

      it 'leaves nil params nil' do
        params[:name] = nil
        new_params = subject.new(params).deserialize
        expect(new_params).to have_key :name
        expect(new_params[:name]).to be_nil
      end
    end

    context 'with present_if' do
      subject do
        Class.new(ParamsDeserializer) do
          attributes :id
          attribute :name, present_if: -> { true }
          attribute :age, present_if: -> { params[:bar] == 'baz' }
          def name; 'foo'; end
        end
      end

      it 'allows deserialization of a param that does not exist' do
        new_params = subject.new({}).deserialize
        expect(new_params[:name]).to eql('foo')
      end

      it 'uses the present_if proc to determine whether a key should be present' do
        params = { bar: 'baz', age: 25 }
        new_params = subject.new(params).deserialize
        expect(new_params[:age]).to eql(25)

        params[:bar] = 'quux'
        new_params = subject.new(params).deserialize
        expect(new_params).to_not have_key :age
      end
    end
  end
end
