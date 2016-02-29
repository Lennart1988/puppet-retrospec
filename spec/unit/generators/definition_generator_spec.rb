require 'spec_helper'

describe Retrospec::Puppet::Generators::DefinitionGenerator do

  after(:each) do
    FileUtils.rm(spec_file) if File.exists?(spec_file)
  end

  let(:generator_opts) do
    {:manifest_file => sample_file, :template_dir => retrospec_templates_path}
  end

  let(:sample_file) do
    File.join(module_path, 'manifests','one_define.pp')
  end

  let(:context) do
    generator.load_context_data
  end

  let(:spec_files_path) do
    File.join(module_path, 'spec', 'defines')
  end

  let(:module_path) do
    File.join(fake_fixture_modules, 'one_resource_module')
  end

  let(:spec_file) do
    path = File.join(module_path, 'spec', 'defines', 'one_define_spec.rb')
  end

  let(:generator) do
    Retrospec::Puppet::Generators::DefinitionGenerator.new(module_path, generator_opts)
  end

  let(:spec_file_contents) do
    File.read(generator.generate_spec_file)
  end

  it 'should create spec file' do
    expect(generator.run).to eq(spec_file)
    expect(File.exists?(spec_file)).to eq(true)
  end

  it 'should produce correct file name' do
    expect(generator.item_spec_path).to eq(spec_file)
  end

  it 'should have a name' do
    expect(context.type_name).to eq('one_resource::one_define')
  end

  it 'should have a resource_type_name' do
    expect(context.resource_type_name).to eq('one_resource::one_define')
  end

  it 'should have a type' do
    expect(context.resource_type).to eq(Puppet::Pops::Model::ResourceTypeDefinition)
  end

  it 'should have parameters' do
    expect(context.parameters).to be_instance_of(String)
    expect(context.parameters.split(',').count).to eq(1)
    # if the test returns more than the expected count there is an extra comma
    # although technically it doesn't matter
  end

  it 'should have resources' do
    resources = ['one']
    expect(context.resources).to eq(resources)
  end

  describe 'content' do
    let(:data) do
      "require 'spec_helper'\nrequire 'shared_contexts'\n\ndescribe 'one_resource::one_define' do\n  # by default the hiera integration uses hiera data from the shared_contexts.rb file\n  # but basically to mock hiera you first need to add a key/value pair\n  # to the specific context in the spec/shared_contexts.rb file\n  # Note: you can only use a single hiera context per describe/context block\n  # rspec-puppet does not allow you to swap out hiera data on a per test block\n  #include_context :hiera\n\n  let(:title) { 'XXreplace_meXX' }\n\n  # below is the facts hash that gives you the ability to mock\n  # facts on a per describe/context block.  If you use a fact in your\n  # manifest you should mock the facts below.\n  let(:facts) do\n    {}\n  end\n  # below is a list of the resource parameters that you can override.\n  # By default all non-required parameters are commented out,\n  # while all required parameters will require you to add a value\n  let(:params) do\n    {\n      #:one => \"one_value\"\n  \n    }\n  end\n  # add these two lines in a single test block to enable puppet and hiera debug mode\n  # Puppet::Util::Log.level = :debug\n  # Puppet::Util::Log.newdestination(:console)\nend\n"
    end
    it 'should generate the content' do
      expect(spec_file_contents).to eq(data)
    end
    it 'should generate the content' do
      expect(spec_file_contents).to eq('')
    end
  end


  describe 'spec files' do
    let(:generated_files) do
      [File.join(spec_files_path, 'one_define_spec.rb')]
    end
    it 'should generate a bunch of files' do
      files = Retrospec::Puppet::Generators::DefinitionGenerator.generate_spec_files(module_path)
      expect(files).to eq(generated_files)
    end
  end

end
