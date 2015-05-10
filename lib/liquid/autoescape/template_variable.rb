module Liquid
  module Autoescape
    class TemplateVariable

      # @return [String] The name of the variable
      attr_reader :name

      # @return [Array<Symbol>] The filters applied to the variable
      attr_reader :filters

      class << self

        # Create a wrapper for a Liquid variable instance
        #
        # This normalizes the variable's information, since Liquid 2 and 3 handle
        # variable names using different data structures.
        #
        # @param [Liquid::Variable] variable A Liquid variable as used in a template
        # @return [Liquid::Autoescape::TemplateVariable]
        def from_liquid_variable(variable)
          name = normalize_variable_name(variable)
          filters = variable.filters.map { |f| f.first.to_sym }

          new(:name => name, :filters => filters)
        end

      private

        # Normalize the name of a Liquid variable
        #
        # Liquid 2 exposes the full variable name directly on the
        # `Liquid::Variable` instance, while Liquid 3 manages it via a
        # `Liquid::VariableLookup` instance that tracks both the base name and
        # any lookup paths involved.
        #
        # @param [Liquid::Variable] variable A Liquid variable as used in a template
        # @return [String] The name of the Liquid variable
        def normalize_variable_name(variable)
          lookup_name = variable.name.instance_variable_get("@name")
          return variable.name unless lookup_name

          parts = [lookup_name]
          variable.name.instance_variable_get("@lookups").each do |lookup|
            parts << lookup
          end
          parts.join(".")
        end

      end

      # Create a new wrapper around a Liquid variable used in a template
      #
      # @options options [String] :name The name of the variable
      # @options options [Array<Symbol>] :filters The filters applied to the variable
      def initialize(options={})
        @name = options.fetch(:name)
        @filters = options[:filters] || []
      end

    end
  end
end
