require_relative 'rule_seq.rb'
require_relative 'typed_seq.rb'

module Eson
  module EsonGrammars

    extend self

    RuleSeq =  Eson::RuleSeq
    Rule = Eson::Rule

    def proc_prefix_rxp
      /&/
    end

    def string_delimiter_rxp
      /"/
    end

    def attribute_name_rxp
      proc_prefix = proc_prefix_rxp.source
      /\A"[^#{proc_prefix}]+"\z/
    end

    def unreserved_procedure_rxp
      proc_prefix = proc_prefix_rxp.source
      string_delimiter = string_delimiter_rxp.source
      /#{string_delimiter}#{proc_prefix}(.+)#{string_delimiter}\z/
    end

    #@return [R0] eson grammar for lexing keys
    def keys
      reserved = [:let, :ref, :doc]
      RuleSeq.new(make_reserved_keys_rules(reserved))
        .make_terminal_rule(
          :key_delimiter,
          string_delimiter_rxp)
        .make_terminal_rule(
          :unreserved_procedure_identifier,
          unreserved_procedure_rxp)
        .make_alternation_rule(:special_form_identifier, reserved)
        .convert_to_terminal(:special_form_identifier)
        .make_terminal_rule(
          :attribute_name,
          attribute_name_rxp)
        .make_alternation_rule(
          :proc_identifier,
          [:unreserved_procedure_identifier,
           :special_form_identifier])
        .build_cfg("R0")
    end

    def make_reserved_keys_rules(keywords)
      keywords.map do |k|
        if k.is_a?(String) || k.is_a?(Symbol)
          k_name = k.is_a?(Symbol) ? k : k.intern
          k_string = k.is_a?(String) ? k : k.to_s
          Rule.new_terminal_rule(
            k_name,
            Regexp.new(
              string_delimiter_rxp.source
              .concat(proc_prefix_rxp.source)
              .concat(k_string)
              .concat(string_delimiter_rxp.source)))
        end
      end
    end

    # null := "nil";
    def null_rule
      Rule.new_terminal_rule(:null, null_rxp)
    end

    def null_rxp
      /null\z/
    end
    
    # variable_prefix := "$";
    def variable_prefix_rule
      Rule.new_terminal_rule(:variable_prefix, variable_prefix_rxp)
    end

    def variable_prefix_rxp
      /\$/
    end

    def variable_identifier_rxp
      variable_prefix = variable_prefix_rxp.source
      word = word_rxp.source
      /#{variable_prefix}#{word}/
    end
    
    # word := {JSON_char}; (*letters, numbers, '-', '_', '.'*)
    def word_rule
      Rule.new_terminal_rule(:word, word_rxp)
    end

    def word_rxp
      /[a-zA-Z\-_.\d]+/
    end
    
    # whitespace := {" "};
    def whitespace_rule
      Rule.new_terminal_rule(:whitespace, whitespace_rxp)
    end

    def whitespace_rxp
      /[ ]+/
    end

    # empty_word := "";
    def empty_word_rule
      Rule.new_terminal_rule(:empty_word, empty_word_rxp)
    end
    
    def empty_word_rxp
      /^$/
    end

    # other_chars := {JSON_char}; (*characters excluding those found
    #   in variable_prefix, word and whitespace*)
    def other_chars_rule
      Rule.new_terminal_rule(:other_chars, other_chars_rxp)
    end
    
    def other_chars_rxp
      word = word_rxp.source
      variable_prefix = variable_prefix_rxp.source
      whitespace = whitespace_rxp.source
      string_delimiter = string_delimiter_rxp.source
      /[^#{string_delimiter}#{word}#{variable_prefix}#{whitespace}]+/
    end

    # true := "true";
    def true_rule
      Rule.new_terminal_rule(:true, true_rxp)
    end
    
    def true_rxp
      /true\z/
    end
    
    # false := "false";
    def false_rule
      Rule.new_terminal_rule(:false, false_rxp)
    end
    
    def false_rxp
      /false\z/
    end

    # number := JSON_number;
    def number_rule
      Rule.new_terminal_rule(:number, number_rxp)
    end

    def number_rxp
      /\d+/
    end

    # array_start := "[";
    def array_start_rule
      Rule.new_terminal_rule(:array_start, array_start_rxp)
    end

    def array_start_rxp
      /\[/
    end
    
    # array_end := "]";
    def array_end_rule
      Rule.new_terminal_rule(:array_end, array_end_rxp)
    end

    def array_end_rxp
      /\]/
    end
    
    # comma := ",";
    def comma_rule
      Rule.new_terminal_rule(:comma, comma_rxp)
    end

    def comma_rxp
      /\,/
    end

    # declaration_divider := ",";
    def declaration_divider_rule
      Rule.new_terminal_rule(:declaration_divider, comma_rxp)
    end
    
    # colon := ":";
    def colon_rule
      Rule.new_terminal_rule(:colon, colon_rxp)
    end

    def colon_rxp
      /:/
    end
    
    # program_start := "{";
    def program_start_rule
      Rule.new_terminal_rule(:program_start, program_start_rxp)
    end

    def program_start_rxp
      /\{/
    end
    
    # program_end := "}";
    def program_end_rule
      Rule.new_terminal_rule(:program_end, program_end_rxp)
    end

    def program_end_rxp
      /\}/
    end
    
    #@return [E0] the initial eson grammar used for tokenization
    def e0
      rules = [word_rule,
               whitespace_rule,
               empty_word_rule,
               other_chars_rule,
               true_rule,
               false_rule,
               null_rule,
               number_rule,
               array_start_rule,
               array_end_rule,
               comma_rule,
               declaration_divider_rule,
               colon_rule,
               program_start_rule,
               program_end_rule]
      RuleSeq.new(keys.copy_rules.concat(rules))
        .make_terminal_rule(:variable_identifier,
                           variable_identifier_rxp)
        .make_alternation_rule(:word_form,
                               [:whitespace,
                                :word,
                                :empty_word,
                                :other_chars])
        .convert_to_terminal(:word_form)
        .make_alternation_rule(
          :sub_string,
          [:word_form, :variable_identifier])
        .make_repetition_rule(
          :sub_string_list,
          :sub_string)
        .make_terminal_rule(
          :string_delimiter,
          string_delimiter_rxp)
        .make_concatenation_rule(
          :string,
          [:string_delimiter,
           :sub_string_list,
           :string_delimiter])
        .build_cfg("E0")
    end

    #@return [Struct] e5 the sixth language of the compiler
    #@eskimobear.specification
    # Prop : E5 is a struct of eson production rules of E4 with
    #        recursive production rules such as 'value', 'array',
    #        and 'program' added.
    def e5
      e0.copy_rules
        .make_alternation_rule(
          :value,
          [:variable_identifier,
           :true,
           :false,
           :null,
           :string,
           :number,
           :array,
           :program])
        .make_concatenation_rule(
          :element_more_once,
          [:comma, :value])
        .make_repetition_rule(
          :element_more,
          :element_more_once)
        .make_concatenation_rule(
          :element_list,
          [:value, :element_more])
        .make_option_rule(
          :element_set, :element_list)
        .make_concatenation_rule(
          :array,
          [:array_start, :element_set, :array_end])
        .make_concatenation_rule(
          :call,
          [:proc_identifier, :colon, :value])
        .make_concatenation_rule(
          :attribute,
          [:attribute_name, :colon, :value])
        .make_alternation_rule(
          :declaration,
          [:call, :attribute])
        .make_concatenation_rule(
          :declaration_more_once,
          [:declaration_divider, :declaration])
        .make_repetition_rule(
          :declaration_more,
          :declaration_more_once)
        .make_concatenation_rule(
          :declaration_list,
          [:declaration, :declaration_more])
        .make_option_rule(
          :declaration_set, :declaration_list)
        .make_concatenation_rule(
          :program,
          [:program_start, :declaration_set, :program_end])
        .build_cfg("E5", :program)
    end

    #return [Struct] the attribute grammar: Format which applies the
    #                default eson format
    def format
      RuleSeq.assign_attribute_grammar(
        "Format",
        e5,
        [{
           :attr => :line_no,
           :type => :s_attr,
           :action_mod => Module.new,
           :actions => [:assign_attribute],
           :terms => [:All]
         },
         {
           :attr => :indent,
           :type => :s_attr,
           :action_mod => Module.new,
           :actions => [:assign_attribute],
           :terms => [:All]
         },
         {
           :attr => :spaces_after,
           :type => :s_attr,
           :action_mod => Module.new,
           :actions => [:assign_attribute],
           :terms => [:colon]
         }])
    end

    alias_method :tokenizer_lang, :e0
    alias_method :syntax_pass_lang, :e5
  end
end
