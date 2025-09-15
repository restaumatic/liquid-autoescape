require "liquid"
require "liquid/autoescape/liquid_ext/block_body"
require "liquid/autoescape/liquid_ext/capture"
require "liquid/autoescape/liquid_ext/standard_filters"

module Liquid
  module Autoescape
    module Tags

      # A block tag that automatically escapes all variables contained within it
      #
      # All contained variables will have dangerous HTML characters escaped.
      # Any variables that should be exempt from escaping should have the
      # +skip_escape+ filter applied to them.
      #
      # @example
      #   {% assign untrusted = "<script>window.reload();</script>" %}
      #   {% assign trusted = "<strong>Text</strong>" %}
      #
      #   {% autoescape %}
      #     {{ untrusted }}
      #     {{ trusted | skip_escape }}
      #   {% endautoescape %}
      class Autoescape < Block

        def initialize(tag_name, markup, tokens)
          unless markup.empty?
            raise SyntaxError, "Syntax Error in 'autoescape' - Valid syntax: {% autoescape %}"
          end

          super
        end

        def render(context)
          context.stack do
            context[ENABLED_FLAG] = true
            super
          end
        end

      end

      Template.register_tag("autoescape", Autoescape)

    end
  end
end
