require_relative 'base_generator'
require_relative 'serializers/rspec_dumper'
require_relative 'serializers/rspec_dumper_full'

require 'puppet'
require 'puppet/pops'

module Retrospec
  module Puppet
    module Generators
      class ResourceBaseGenerator < Retrospec::Puppet::Generators::BaseGenerator
        # retrospec will initilalize this class so its up to you
        # to set any additional variables you need to get the job done.
        def initialize(module_path, spec_object = {})
          super
          raise "NoManifestFileError" unless spec_object[:manifest_file]
          @context = OpenStruct.new(:manifest_file => spec_object[:manifest_file], :content => nil)
        end

        def singular_name
          unless @singular_name
            raise NotImplementedError
          end
          @singular_name
        end

        def plural_name
          unless @plural_name
            raise NotImplementedError
          end
          @plural_name
        end

        def spec_template_file
          NotImplementedError
        end

        # used to display subcommand options to the cli
        # the global options are passed in for your usage
        # http://trollop.rubyforge.org
        # all options here are available in the config passed into config object
        # returns the parameters
        def self.run_cli(global_opts, args=ARGV)
          sub_command_opts = Trollop.options(args) do
            banner <<-EOS
            ""
            EOS
          end
          unless sub_command_opts[:manifest_file]
            Trollop.educate
            exit 1
          end
          plugin_data = global_opts.merge(sub_command_opts)
          plugin_data
        end

        def self.manifest_files(module_path)
          Dir.glob(File.join(module_path, 'manifests', '*.pp'))
        end

        def self.generate_spec_files(module_path)
          manifests = manifest_files(module_path)
          files = Retrospec::Puppet::Generators::HostClassGenerator.generate_spec_files(module_path)
          files << Retrospec::Puppet::Generators::DefinitionGenerator.generate_spec_files(module_path)
          files.flatten
        end

        def generate_spec_file
          template_file = File.join(template_dir,spec_template_file )
          context.content = generate_content
          safe_create_template_file(item_spec_path, template_file, context)
          item_spec_path
        end

        def manifest_file
          context.manifest_file
        end

        def generate_content
          class_def = ast.body
          parameters = class_def.parameters
          dumper = Retrospec::Puppet::RspecDumper.new
          content = dumper.dump(ast)
        end

        # run is the main method that gets called automatically
        def run
          generate_spec_file
        end

        def item_path
          File.join(lib_path, "#{item_name}.pp")
        end

        def spec_path
          File.join(module_path, 'spec', plural_name)
        end

        def lib_path
          File.join(module_path, 'manifests')
        end

        def resource_type
          ast.eContents.first.class
        end
        # returns the name of the first time found in the file
        # for files that have multiple types, we just don't care since it doesn't
        # follow the style guide
        def type_name
          ast.eContents.first.name
        end

        # returns the filename of the type
        def generate_file_name(type_name)
          tokens = type_name.split('::')
          file_name = tokens.pop
          "#{file_name}_spec.rb"
        end

        # generates a file path for spec tests based on the resource name.  An added option
        # is to generate directory names for each parent resource as a default option
        def item_spec_path
          file_name = generate_file_name(type_name)
          tokens = type_name.split('::')
          # if there are only two tokens ie. tomcat::params we dont need to create a subdirectory
          if tokens.count > 2
            # this is a deep level resource ie. tomcat::config::server::connector
            # however we don't need the tomcat directory so we can just remove it
            # this should leave us with config/server/connector_spec.rb
            tokens.delete_at(0)
            # remove the last token since its the class name
            tokens.pop
            # so lets make a directory structure out of it
            dir_name = File.join(tokens) # config/server
            dir_name = File.join(spec_path, dir_name, file_name) # spec/classes/tomcat/config/server
          else
            dir_name = File.join(spec_path, file_name)
          end
          dir_name
        end

        def ast
          unless @ast
            parser = ::Puppet::Pops::Parser::EvaluatingParser.new
            result = parser.parse_file(manifest_file)
            @ast = result.current
          end
          @ast
        end
      end
    end
  end
end
