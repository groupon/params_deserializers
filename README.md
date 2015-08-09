# Params Deserializers

## Purpose

Modeled after [`active_model_serializers`](https://github.com/rails-api/active_model_serializers), this gem allows you to create deserializer classes to modify incoming parameters in your Rails app.

Rails controllers often receive incoming parameters (via JSON payloads, for instance) that are not in the format Rails expects for things like saving models. With Params Deserializers, you can easily transform these incoming parameters into the format you want ([example](#an-example)).

## Getting started

Create a subclass of `ParamsDeserializer`:

```ruby
# app/deserializers/user_params_deserializer.rb

class UserParamsDeserializer < ParamsDeserializer
end
```

To deserialize a hash with your deserializer, instantiate your deserializer with the hash, and call `deserialize` on it:

```ruby
new_hash = UserParamsDeserializer.new(old_hash).deserialize
```

## Listing params

Call the class method `attributes` to list incoming params:

```ruby
class UserParamsDeserializer < ParamsDeserializer
  attributes :first_name, :last_name, :birthday
end
```

This class indicates that it expects `first_name`, `last_name`, and `birthday` keys on an incoming hash. Any other keys in the hash will be discarded.

Keys can also be listed individually using `attribute`:

```ruby
class UserParamsDeserializer < ParamsDeserializer
  attribute :first_name
  attribute :last_name
  attribute :birthday
end
```

## Renaming params

You can pass an options hash to `attribute`. If you include the `:rename_to` key in the options hash, your deserialized params will contain the renamed key instead of the original:

```ruby
class UserParamsDeserializer < ParamsDeserializer
  attribute :firstName, rename_to: :first_name
  attribute :lastName, rename_to: :last_name
  attribute :birthday
end

# Incoming hash: { :firstName => "Grace", :lastName => "Hopper, :birthday => "12/9/1906" }
# Deserialized params: { :first_name => "Grace", :last_name => "Hopper, :birthday => "12/9/1906" }
```

## Changing params case

You can apply snake_case, CamelCase, or lowerCamel cases to all your keys automatically using `format_keys`:

```ruby
class UserParamsDeserializer < ParamsDeserializer
  attributes :firstName, :lastName, :birthday
  format_keys :snake_case # (or :camel_case or :lower_camel)
end

# Incoming hash: { :firstName => "Grace", :lastName => "Hopper, :birthday => "12/9/1906" }
# Deserialized params: { :first_name => "Grace", :last_name => "Hopper, :birthday => "12/9/1906" }
```

## Dealing with a root key

If you expect a root key containing an object with all the other keys, call the `root` class method on your deserializer. Otherwise, it will look for the attributes you've listed at the top level:

```ruby
class UserParamsDeserializer < ParamsDeserializer
  root: :user
  attributes :first_name, :last_name
end

# Incoming hash: { :user => { :first_name => "Grace", :last_name => "Hopper" } }
# Deserialized params: { :user => { :first_name => "Grace", :last_name => "Hopper" } }
```

To discard the root key in your deserialized params, pass `{ discard: true }` as the second argument to `root`:

```ruby
class UserParamsDeserializer < ParamsDeserializer
  root: :user, discard: true
  attributes :first_name, :last_name
end

# Incoming hash: { :user => { :first_name => "Grace", :last_name => "Hopper" } }
# Deserialized params: { :first_name => "Grace", :last_name => "Hopper" }
```

## Deciding whether a key should be present

By default, any key listed via `attribute` or `attributes` will be included in the deserialized params if the key is present in `params`. However, the `attribute` class method takes an options hash. If the hash includes a `:present_if` key with a lambda value, it will execute that lambda to determine whether that key should be present in the deserialized params:

```ruby
class UserParamsDeserializer < ParamsDeserializer
  attribute :first_name
  attribute :last_name, present_if: -> { params[:last_name].length > 5 }
end

# Incoming hash: { :first_name => "Grace", :last_name => "Hop" }
# Deserialized params: { :first_name => "Grace" }
```

The lambda has access to the `params` hash, and can use it to determine whether the key should be present. In the example above, `last_name` is only included when its length is greater than 5.

## Overriding a key's value

If you define a method of the same name as a parameter, that method will be called to provide the parameter's value:

```ruby
class UserParamsDeserializer < ParamsDeserializer
  attribute :birthday

  def birthday
    month, day, year = params[:birthday].split("/")
    Time.new(year.to_i, month.to_i, day.to_i)
  end
end

# Incoming hash: { :birthday => "12/9/1906" }
# Deserialized params: { :birthday => 1906-12-09 00:00:00 -0000 }
```

Note that the method name should equal to the *renamed* parameter name, if the parameter has been renamed. For example, if you had passed `{ rename_to: :birth_date }` to `attribute` in the example above, the method you define would have to be `birth_date` instead of `birthday`.

## Integrating your deserializer with your controller

You can deserialize incoming parameters in two ways:

### Via `deserialize_params_with`

If you `include ParamsDeserializers` in your controller, your controller will have access to a class method called `deserialize_params_with`. By default, `deserialize_params_with` will create an instance variable called `deserialized_params`. Think of this as the `params` instance variable, but transformed according to your deserializer.

```ruby
# /app/controllers/users_controller.rb

class UsersController < ApplicationController
  include ParamsDeserializers
  deserialize_params_with UserParamsDeserializer

  def create
    @user = User.create(deserialized_params)
    render json: @user
  end
end
```

If you'd like a different instance variable name, such as `better_params`, pass an options hash to `deserialize_params_with` that contains an `:as` key:

```ruby
  deserialize_params_with UserParamsDeserializer, as: :better_params
```

`better_params` will now be available to your controller action.

`deserialize_params_with` passes on any remaining keys in the options hash to `before_filter`, which means you can restrict deserialization to only certain controller actions:

```ruby
  deserialize_params_with UserParamsDeserializer, as: :better_params, only: [:create, :update]
```

### Via instantiation of your deserializer

You can also simply instantiate your deserializer with `params` in your controller action, and then call `deserialize` on it to get the deserialized params:

```ruby
# /app/controllers/users_controller.rb

class UsersController < ApplicationController
  def create
    deserialized_params = UserParamsDeserializer.new(params).deserialize
    @user = User.create(deserialized_params)
    render json: @user
  end
end
```

## An example

Create a subclass of `ParamsDeserializer`:

```ruby
# app/deserializers/user_params_deserializer.rb

class UserParamsDeserializer < ParamsDeserializer
  root :user, discard: true

  format_keys :snake_case

  attributes :birthday,
             :firstName,
             :lastName

  attribute :heightInInches,
            rename_to: :height_in_feet,
            present_if: -> { params[:height_in_inches].is_a? Integer }

  def birthday
    month, day, year = params[:birthday].split("/")
    Time.new(year.to_i, month.to_i, day.to_i)
  end

  def height_in_feet
    params[:heightInInches] / 12.0
  end
end
```

Then, include it in your `UsersController`:

```ruby
# app/controllers/users_controller.rb

class UsersController < ApplicationController
  include ParamsDeserializers
  deserialize_params_with UserParamsDeserializer, as: :new_params, only: :create

  def create
    @user = User.create(new_params)
    render json: @user
  end
end
```

Now, when an API user hits `UsersController#create` with the following JSON payload:

```json
{
  "user": {
    "firstName": "Grace",
    "lastName": "Hopper",
    "birthday": "12/9/1906",
    "heightInInches": 66
  }
}
```

...`UsersController#create` will have access to an instance variable called `new_params` with the following contents:

```ruby
{
  :first_name => "Grace",
  :last_name => "Hopper",
  :birthday => 1906-12-09 00:00:00 -0000,
  :height_in_feet => 5.5
}
```

## Development

- Clone this repo.
- `bundle install`
- `bundle exec rspec` (or `bundle exec guard` to watch for changes)

## License

Copyright (c) 2015, Groupon, Inc.  
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
