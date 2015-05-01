require_relative 'rule_seq.rb'

module Eson
  module EsonGrammars

    extend self

    RuleSeq =  Eson::RuleSeq
    Rule = Eson::Rule

    # null := "nil";
    def null_rule
      Rule.new_terminal_rule(:null, null_rxp)
    end

    def null_rxp
      /null/
    end
    
    # variable_prefix := "$";
    def variable_prefix_rule
      Rule.new_terminal_rule(:variable_prefix, variable_prefix_rxp)
    end

    def variable_prefix_rxp
      /\$/
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
      /[^#{word}#{variable_prefix}#{whitespace}]+/
    end

    # true := "true";
    def true_rule
      Rule.new_terminal_rule(:true, true_rxp)
    end
    
    def true_rxp
      /true/
    end
    
    # false := "false";
    def false_rule
      Rule.new_terminal_rule(:false, false_rxp)
    end
    
    def false_rxp
      /false/
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

    # end_of_line := ",";
    def end_of_line_rule
      Rule.new_terminal_rule(:end_of_line, comma_rxp)
    end

    # proc_prefix := "&";
    def proc_prefix_rule
      Rule.new_terminal_rule(:proc_prefix, proc_prefix_rxp)
    end

    def proc_prefix_rxp
      /&/
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
    
    # key_string := {JSON_char}; (*all characters excluding proc_prefix*)
    def key_string_rule
      Rule.new_terminal_rule(:key_string, all_chars_rxp)
    end

    def make_special_form_rules(keywords)
      keywords.map do |k|
        if k.is_a?(String) || k.is_a?(Symbol)
          k_name = k.is_a?(Symbol) ? k : k.intern
          k_string = k.is_a?(String) ? k : k.to_s
          Rule.new_terminal_rule(
            k_name,
            Regexp.new(k_string.concat("\\z")))
        end
      end
    end

    def all_chars_rxp
      /.+/
    end

    #@return [R0] grammar composed of the reserved keywords
    #  in eson.
    def reserved_keys
      reserved = [:let, :ref, :doc]
      RuleSeq.new(make_special_form_rules(reserved))
        .make_alternation_rule(:special_form, reserved)
        .make_terminal_rule(
          :unreserved_special_form,
          all_chars_rxp)
        .make_alternation_rule(
          :any_special_form,
          [:special_form, :unreserved_special_form])
        .build_cfg("R0")
    end

    #@return [E0] the initial compiler language used by Tokenizer
    #@eskimobear.specification
    #
    # The following EBNF rules describe the eson grammar, E0:
    # variable_prefix := "$";
    # word := {JSON_char}; (*letters, numbers, '-', '_', '.'*)
    # whitespace := {" "};
    # other_chars := {JSON_char}; (*characters excluding those found
    #   in variable_prefix, word and whitespace*)
    # true := "true";
    # false := "false";
    # number := JSON_number;
    # null := "null";
    # array_start := "[";
    # array_end := "]";
    # comma := ",";
    # end_of_line := ",";
    # proc_prefix := "&";
    # colon := ":";
    # program_start := "{";
    # program_end := "}";
    # key_string := {JSON_char}; (*all characters excluding proc_prefix*)
    # special_form := let | ref | doc;
    # word_form := whitespace | variable_prefix | word | other_chars;
    # variable_identifier := variable_prefix, word;
    def e0
      rules = [variable_prefix_rule,
               word_rule,
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
               end_of_line_rule,
               proc_prefix_rule,
               colon_rule,
               program_start_rule,
               program_end_rule,
               key_string_rule]
      RuleSeq.new(reserved_keys
                   .copy_rules
                   .concat(rules))
        .make_alternation_rule(:word_form, [:whitespace, :variable_prefix, :word, :empty_word, :other_chars])
        .make_concatenation_rule(:variable_identifier, [:variable_prefix, :word])
        .make_concatenation_rule(:proc_identifier, [:proc_prefix, :special_form])
        .build_cfg("E0")
    end

    #@return e1 the second language of the compiler
    #@eskimobear.specification
    #  Prop : E1 is a struct of eson production rules of
    #         E0 with 'unreserved_special_form' removed  
    def e1
      e0.copy_rules
        .remove_rules([:unreserved_special_form])
        .build_cfg("E1")
    end

    #@return e2 the third language of the compiler
    #@eskimobear.specification
    #  Prop : E2 is a struct of eson production rules
    #         of E1 with 'variable_identifier' and 'proc identifier'
    #         converted to terminals.
    def e2
      e1.copy_rules
        .convert_to_terminal(:variable_identifier)
        .convert_to_terminal(:proc_identifier)
        .remove_rules([:let, :ref, :doc, :proc_prefix, :special_form])
        .build_cfg("E2")
    end

    #@return e3 the fourth language of the compiler
    #@eskimobear.specification
    #  Prop : E3 is a struct of eson production rules of E2 with
    #         'word_form' tokenized and
    #         'whitespace', 'variable_prefix', 'word' and 
    #         'other_chars' removed.    
    def e3
      e2.copy_rules
        .convert_to_terminal(:word_form)
        .remove_rules([:other_chars, :variable_prefix, :word, :empty_word, :whitespace])
        .build_cfg("E3")
    end

    #@return e4 the fifth language of the compiler
    #@eskimobear.specification
    # Prop : E4 is a struct of eson production rules of E3 with
    #        'sub_string' production rule added.
    def e4
      e3.copy_rules
        .make_alternation_rule(:sub_string, [:word_form, :variable_identifier])
        .make_terminal_rule(:string_delimiter, /"/)
        .make_repetition_rule(:sub_string_list, :sub_string)
        .make_concatenation_rule(:string, [:string_delimiter, :sub_string_list, :string_delimiter])
        .build_cfg("E4")
    end

    #@return e5 the sixth language of the compiler
    #@eskimobear.specification
    # Prop : E5 is a struct of eson production rules of E4 with
    #        recursive production rules such as 'value', 'array',
    #        and 'program' added.
    def e5
      e4.copy_rules
        .make_alternation_rule(:value, [:variable_identifier, :true, :false,
                                        :null, :string, :number, :array, :program])
        .make_concatenation_rule(:element_more_once, [:comma, :value])
        .make_repetition_rule(:element_more, :element_more_once)
        .make_concatenation_rule(:element_list, [:value, :element_more])
        .make_option_rule(:element_set, :element_list)
        .make_concatenation_rule(:array, [:array_start, :element_set, :array_end])
        .make_concatenation_rule(:attribute, [:key_string, :colon, :value])
        .make_concatenation_rule(:call, [:proc_identifier, :colon, :value])
        .make_alternation_rule(:declaration, [:call, :attribute])
        .make_concatenation_rule(:declaration_more_once, [:end_of_line, :declaration])
        .make_repetition_rule(:declaration_more, :declaration_more_once)
        .make_concatenation_rule(:declaration_list, [:declaration, :declaration_more])
        .make_option_rule(:declaration_set, :declaration_list)
        .make_concatenation_rule(:program, [:program_start, :declaration_set, :program_end])
        .build_cfg("E5", :program)
    end

    alias_method :tokenizer_lang, :e0
    alias_method :syntax_pass_lang, :e5
    alias_method :verified_special_forms_lang, :e1
    alias_method :tokenize_variable_identifier_lang, :e2
    alias_method :tokenize_word_form_lang, :e3
    alias_method :label_sub_string_lang, :e4
    alias_method :insert_string_delimiter_lang, :e4
  end
end
