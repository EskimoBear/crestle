#!/usr/bin/env ruby

require 'rubygems'
require 'commander/import'
require_relative '../lib/dote.rb'

CLI_USAGE = "Usage: dote --COMMAND [ARGS]\n"\
            "Hint: pass a file to compile\n"
GEMSPEC_PATH = File.expand_path('../../dote.gemspec', __FILE__)

gemspec = Gem::Specification::load(GEMSPEC_PATH)

program :name, gemspec.name.to_s
program :version, gemspec.version.to_s
program :description, 'Compiler for the Dote language'
program :help_formatter, :compact

default_command :usage

command :usage do |c|
  c.action do
    say CLI_USAGE
  end
end

command 'fmt' do |c|
  c.syntax = 'dote fmt [input_file] [output_file]'
  c.summary = 'Formats Dote programs'
  c.description = 'Formats Dote programs passed as input_file,'\
                  ' rewriting input_file in the process.'\
                  ' If an output_file is passed as well the formatted'\
                  ' program is written to output_file.'
  c.action do |args, options|
    def parse_file_paths(args)
    {:input_file => args.first,
     :output_file => args[1]}
    end
    files = parse_file_paths(args)
    if files[:input_file]
      if files[:output_file].nil?
        program = File.open(files[:input_file]).read
        grammar = Dote::DoteGrammars.esonf
        token_sequence = Dote::TokenPass.tokenize_program(program, grammar)
                         .verify_special_forms
        tree = Dote::SyntaxPass.build_tree(token_sequence, grammar)
        Dote::CodeGen.make_file(tree,
                                grammar,
                                File.dirname(files[:input_file]),
                                File.basename(files[:input_file]))
      end
    end
  end
end
