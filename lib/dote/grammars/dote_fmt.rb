module Dote::DoteGrammars

  def dote_fmt
    RuleSeq.assign_attribute_grammar(
      display_fmt,
      [DoteFormat],
      [{
         :attr => :line_feed,
         :type => :s_attr,
         :terms => [:All]
       },
       {
         :attr => :line_start,
         :type => :s_attr,
         :terms => [:All]
       },
       {
         :attr => :to_s,
         :type => :s_attr,
         :terms => [:All]
       }])
  end

  module DoteFormat

    include IObjectCode

    def generate_code(env)
      env[:tree].get_attribute(:to_s)
    end

    def eval_tree_attributes(tree)
      build_tree_to_s(tree)
      tree
    end

    def eval_s_attributes(envs, token, token_seq)
      super
      set_line_feed_true(token, token_seq)
      set_to_s(token)
    end

    def set_line_feed_true(token, token_seq)
      end_line_tokens = [:program_start,
                         :array_start,
                         :element_divider,
                         :declaration_divider]
      start_line_tokens = [:program_end,
                           :array_end]
      if end_line_tokens.include?(token.name)
        token.store_attribute(:line_feed, true)
      elsif start_line_tokens.include?(token.name)
        token_seq.last.store_attribute(:line_feed, true)
        set_to_s(token_seq.last)
      end
    end

    def set_to_s(token)
      lexeme = token.lexeme.to_s
      indent = token.get_attribute(:indent)
      spaces_after = token.get_attribute(:spaces_after)
      line_feed = token.get_attribute(:line_feed)
      line_start = token.get_attribute(:line_start)
      string = "#{indentation(indent, line_start)}" \
               "#{lexeme}" \
               "#{spaces_after.nil? ? "" : " "}" \
               "#{line_feed.eql?(true) ? "\n" : ""}"
      token.store_attribute(:to_s, string)
    end

    def indentation(indent, line_start)
      if line_start
        acc = String.new
        indent.times{acc.concat("  ")}
        acc
      else
        ""
      end
    end

    def build_tree_to_s(tree)
      tree.post_order_traversal do |t|
        unless t.leaf?
          string = t.children.map{|i| i.get_attribute(:to_s)}
                   .reduce(:concat)
          t.store_attribute(:to_s, string)
        end
      end
    end
  end
end
