require 'spec_helper'

describe FbGraph2::User do
  describe '.me' do
    let(:klass) { FbGraph2::User }

    it 'should not call API' do
      expect do
        me = klass.me 'token'
        me.should be_instance_of klass
      end.not_to request_to 'me'
    end

    context 'when fetched' do
      it 'should call API' do
        me = mock_graph :get, 'me', 'user/me' do
          klass.me('token').fetch
        end
        me.should be_instance_of klass
      end
    end
  end
end