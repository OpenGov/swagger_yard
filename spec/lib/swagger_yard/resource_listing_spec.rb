require 'spec_helper'
require 'tempfile'
require 'stringio'

RSpec.describe SwaggerYard::ResourceListing, 'reparsing' do
  let(:fixture_files) do
    fixtures = FIXTURE_PATH + 'resource_listing'
    [
      fixtures + 'hello_controller.rb',
      fixtures + 'goodbye_controller.rb'
    ]
  end

  let(:multi_resource_listing) { described_class.new(fixture_files, nil) }
  let(:filename) { (t = Tempfile.new(['test_resource', '.rb'])).path.tap { t.close! } }

  def resource_listing
    described_class.new filename, nil
  end

  let(:first_pass) do
    <<-SRC
      # @resource Greeting
      class GreetingController
        # @path [GET] /hello
        def index
        end
      end
    SRC
  end

  let(:second_pass) do
    <<-SRC
      # @resource Greeting
      class GreetingController
        # @path [GET] /hello
        def index
        end

        # @path [GET] /hello/{msg}
        # @parameter msg [String] a custom message
        def show
        end
      end
    SRC
  end

  it 'reparses after changes to a file' do
    File.open(filename, 'w') { |f| f.write first_pass }
    hash1 = resource_listing.to_h

    expect(hash1['paths'].keys).to contain_exactly('/hello')

    File.open(filename, 'w') { |f| f.write second_pass }
    hash2 = resource_listing.to_h

    expect(hash2['paths'].keys).to contain_exactly('/hello', '/hello/{msg}')

    File.unlink filename
  end

  it 'supports array arguments for paths' do
    hash = multi_resource_listing.to_h

    expect(hash['paths'].keys).to contain_exactly('/bonjour', '/goodbye')
  end

  describe 'logging' do
    before(:each) do
      ::YARD::Registry.clear # have to otherwise tests will fail
      @log_string = StringIO.new
      logger = ::Logger.new @log_string
      logger.level = ::Logger::WARN
      SwaggerYard.config.logger = logger
    end

    it 'gives warnings for tags that will not be correctly parsed' do
      described_class.new(
        [
          FIXTURE_PATH + 'malformed_files' + 'malformed_controller.rb'
        ], nil
      ).to_h

      expect(@log_string.string).to include('Tag, property, not recognized in file')
    end

    it 'gives a warning about an invalid controller' do
      described_class.new(
        [
          FIXTURE_PATH + 'malformed_files' + 'invalid_controller.rb'
        ], nil
      ).to_h

      expect(@log_string.string).to include('Invalid controller object in file')
    end

    it 'gives a warning about an invalid model' do
      described_class.new(
        [
          FIXTURE_PATH + 'malformed_files' + 'good_controller.rb'
        ],
        [
          FIXTURE_PATH + 'malformed_files' + 'malformed_model.rb'
        ]
      ).to_h
      expect(@log_string.string).to include('Tag, parameter, not recognized in file')
    end
  end
end
