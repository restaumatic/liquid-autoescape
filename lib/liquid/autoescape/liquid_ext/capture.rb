require "liquid"
require "liquid/autoescape"
require "liquid/autoescape/template_variable"
require "liquid/autoescape/liquid_ext/standard_filters"

module Liquid
  class Capture
    def render_to_output_buffer(context, output)
      context.resource_limits.with_capture do
        captured = context.stack do
          context["in_capture"] = true
          render(context)
        end
        context.scopes.last[@to] = Liquid::Autoescape::SafeString.mark_safe(captured)
      end
      output
    end
  end
end
