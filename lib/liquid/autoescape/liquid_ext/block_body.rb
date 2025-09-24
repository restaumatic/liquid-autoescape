require "liquid"
require "liquid/autoescape"
require "liquid/autoescape/template_variable"
require "liquid/autoescape/safe_string"

module Liquid
  class BlockBody

    def render_node(context, output, node)
      not_variable = !node.is_a?(Variable)
      not_enabled = !Autoescape.configuration.global? && !context[Autoescape::ENABLED_FLAG]

      if not_variable || not_enabled || is_exempt?(node)
        BlockBody.render_node(context, output, node)
        return
      end

      # render to [] instead of "" to retain the SafeString status
      os = BlockBody.render_node(context, [], node)
      os.each do |o|
        output << escape_if_unsafe(o)
      end
    end

    private

    def is_exempt?(node)
      variable = Autoescape::TemplateVariable.from_liquid_variable(node)
      Autoescape.configuration.exemptions.apply?(variable)
    end

    def escape_if_unsafe(str)
      if Liquid::Autoescape::SafeString.is_safe? str
        str.to_s
      else
        Liquid::StandardFilters.escape(str)
      end
    end
  end
end
