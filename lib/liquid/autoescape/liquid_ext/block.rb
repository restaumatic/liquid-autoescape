require "liquid"
require "liquid/autoescape"
require "liquid/autoescape/template_variable"
require "liquid/autoescape/safe_string"

module Liquid
  class BlockBody

    def render_node(context, output, node)
      if !node.is_a? Variable
        output << BlockBody.render_node(context, +"", node)
        return
      end

      # render to [] instead of "" to retain the SafeString status
      os = BlockBody.render_node(context, [], node)

      os.each do |o|
        if context["in_capture"]
          output << o
          return
        end

        if !Autoescape.configuration.global? && !context[Autoescape::ENABLED_FLAG]
          output << o
          return
        end

        variable = Autoescape::TemplateVariable.from_liquid_variable(node)

        is_exempt = Autoescape.configuration.exemptions.apply?(variable)

        if is_exempt
          output << o
          return
        end

        output << escape_if_unsafe(o)
      end
    end

    private

    def escape_if_unsafe(str)
      if Liquid::Autoescape::SafeString.is_safe? str
        str.to_s
      else
        Liquid::StandardFilters.escape(str)
      end
    end
  end
end
