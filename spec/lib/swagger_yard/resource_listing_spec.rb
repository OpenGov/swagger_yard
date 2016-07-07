require 'spec_helper'
require 'tempfile'

RSpec.describe SwaggerYard::ResourceListing, "reparsing" do
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

  it "reparses after changes to a file" do
    File.open(filename, "w") { |f| f.write first_pass }
    hash1 = resource_listing.to_h

    expect(hash1['paths'].keys).to contain_exactly('/hello')

    File.open(filename, "w") { |f| f.write second_pass }
    hash2 = resource_listing.to_h

    expect(hash2['paths'].keys).to contain_exactly('/hello', '/hello/{msg}')

    File.unlink filename
  end

  it "supports array arguments for paths" do
    hash = multi_resource_listing.to_h

    expect(hash['paths'].keys).to contain_exactly('/bonjour', '/goodbye')
  end

  describe 'invalid YARD' do
    let(:error_fixture_files) do
      error_fixtures = FIXTURE_PATH + 'error_handling'
      [
        error_fixtures + 'controller.rb',
        error_fixtures + 'model.rb'
      ]
    end

    let(:error_fixture_listing) { described_class.new(error_fixture_files, nil) }

    it 'gives error messages and the method' do
      hash = error_fixture_listing.to_h
    end
  end
end
