require 'spec_helper'

describe FbGraph2::Node do
  let(:klass) { FbGraph2::Node }
  let(:instance) { klass.new 'identifier' }

  describe 'API Versioning' do
    before do
      @original = FbGraph2.api_version
    end

    after do
      FbGraph2.api_version = @original
    end

    describe 'via global setting' do
      before do
        FbGraph2.api_version = 'v2.x'
      end

      describe '#fetch' do
        it 'should use api_version globally' do
          expect do
            instance.fetch
          end.to request_to 'v2.x/identifier', :get, api_version_in_path: true
        end
      end

      describe '#edge' do
        it 'should use api_version globally' do
          expect do
            instance.edge :foo
          end.to request_to 'v2.x/identifier/foo', :get, api_version_in_path: true
        end
      end
    end

    describe 'via per-call option' do
      describe '#fetch' do
        it 'should use api_version locally' do
          expect do
            instance.fetch nil, api_version: 'v2.y'
          end.to request_to 'v2.y/identifier', :get, api_version_in_path: true
          FbGraph2.api_version.should == @original
        end
      end

      describe '#edge' do
        it 'should use api_version locally' do
          expect do
            instance.edge :foo, {}, api_version: 'v2.y'
          end.to request_to 'v2.y/identifier/foo', :get, api_version_in_path: true
          FbGraph2.api_version.should == @original
        end
      end
    end
  end

  context 'class' do
    subject { klass }
    it { should_not respond_to :register_attributes }
    it { should_not respond_to :registered_attributes }
    it { should_not respond_to :registered_attributes= }

    describe '.fetch' do
      it 'should call API' do
        expect do
          klass.fetch 'foo'
        end.to request_to 'foo'
      end
    end
  end

  context 'instance' do
    subject { instance }
    it { should_not respond_to :assign }

    describe '#initialize' do
      its(:id) { should == 'identifier' }
      its(:access_token) { should be_nil }
      its(:raw_attributes) { should be_nil }
    end

    describe '#authenticate' do
      before { instance.authenticate 'access_token' }
      its(:access_token) { should == 'access_token' }
    end

    describe '#destroy' do
      it 'should call API with DELETE method' do
        expect do
          instance.destroy
        end.to request_to 'identifier', :delete
      end
    end

    describe '#handle_response' do
      context 'when error' do
        context 'when valid json' do
          it 'should raise' do
            expect do
              mock_graph :get, 'identifier', 'error/400/2500', status: 400 do
                instance.fetch
              end
            end.to raise_error { |e|
              e.should be_instance_of FbGraph2::Exception::BadRequest
              e.message.should == mock_json('error/400/2500')[:error][:message]
            }
          end
        end

        context 'when invalid json' do
          it 'should raise' do
            expect do
              mock_graph :get, 'identifier', 'error/invalid_format', status: 400 do
                instance.fetch
              end
            end.to raise_error { |e|
              e.should be_instance_of FbGraph2::Exception
              e.message.should == "Unparsable Response: #{mock_json('error/invalid_format')}"
            }
          end
        end
      end
    end
  end
end