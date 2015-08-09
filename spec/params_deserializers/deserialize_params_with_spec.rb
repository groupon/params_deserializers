# Copyright (c) 2015, Groupon, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require 'rails_helper'

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
