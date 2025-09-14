require "liquid"
require "liquid/autoescape/template_variable"

module Liquid
  module Autoescape
    describe TemplateVariable do

      it "requires a variable name" do
        expect { TemplateVariable.new }.to raise_error(KeyError)
        expect { TemplateVariable.new(:name => "variable") }.to_not raise_error
      end

      it "exposes its variable name" do
        data = TemplateVariable.new(:name => "variable")
        expect(data.name).to eq("variable")
      end

      it "can accept variable names describing a lookup" do
        data = TemplateVariable.new(:name => "hash.key")
        expect(data.name).to eq("hash.key")
      end

      it "can accept a list of filters applied to the variable" do
        data = TemplateVariable.new(:name => "variable", :filters => [:downcase])
        expect(data.filters).to match_array([:downcase])
      end

      describe ".from_liquid_variable" do

        let(:liquid_variable) { Liquid::Variable.new(variable_name, Liquid::ParseContext.new) }
        let(:variable_name) { nil }

        let(:wrapper) { TemplateVariable.from_liquid_variable(liquid_variable) }

        context "with an unfiltered Liquid variable" do
          let(:variable_name) { "from_liquid" }

          it "resolves the variable name" do
            expect(wrapper.name).to eq("from_liquid")
          end

          it "has an empty list of filters" do
            expect(wrapper.filters).to be_empty
          end
        end

        context "with a filtered Liquid variable" do
          let(:variable_name) { "from_liquid | downcase | capitalize" }

          it "resolves the variable name" do
            expect(wrapper.name).to eq("from_liquid")
          end

          it "exposes a list of filters" do
            expect(wrapper.filters).to eq([:downcase, :capitalize])
          end

        end

        context "with a lookup-style Liquid variable" do
          let(:variable_name) { "hash.key" }

          it "exposes the full variable name" do
            expect(wrapper.name).to eq("hash.key")
          end
        end

        context "with a deep lookup-style Liquid variable" do
          let(:variable_name) { "trunk.branch.leaf" }

          it "exposes the full variable name" do
            expect(wrapper.name).to eq("trunk.branch.leaf")
          end
        end

      end

    end
  end
end
