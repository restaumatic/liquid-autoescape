require "liquid/autoescape"

describe "{% autoescape %}" do

  def verify_template_output(template, expected, context={})
    rendered = Liquid::Template.parse(template).render!(context)
    expect(rendered).to eq(expected)
  end

  it "handles empty content" do
    verify_template_output(
      "{% autoescape %}{% endautoescape %}",
      ""
    )
  end

  it "handles non-variable content" do
    verify_template_output(
      "{% autoescape %}Static{% endautoescape %}",
      "Static"
    )
  end

  it "escapes all dangerous HTML characters" do
    verify_template_output(
      "{% autoescape %}{{ variable }}{% endautoescape %}",
      "&lt;tag&gt; &amp; &quot;quote&quot;",
      "variable" => '<tag> & "quote"'
    )
  end

  it "applies HTML escaping to all variables inside the block tag" do
    verify_template_output(
      "{% autoescape %}{{ one }} {{ two }} {{ three }}{% endautoescape %}",
      "&lt;tag&gt; &amp; &quot;quote&quot;",
      "one" => "<tag>", "two" => "&", "three" => '"quote"'
    )
  end

  it "applies HTML escaping to a filtered variable" do
    verify_template_output(
      "{% autoescape %}{{ filtered | downcase | capitalize }}{% endautoescape %}",
      "A &lt;strong&gt; tag",
      "filtered" => "A <STRONG> Tag"
    )
  end

  it "does not double-escape variables" do
    verify_template_output(
      "{% autoescape %}{{ escaped | escape }}{% endautoescape %}",
      "HTML &amp; CSS",
      "escaped" => "HTML & CSS"
    )
  end

  it "does not escape variables outside the block tag" do
    verify_template_output(
      "{{ variable }} {% autoescape %}{{ variable }}{% endautoescape %} {{ variable }}",
      "& &amp; &",
      "variable" => "&"
    )
  end

  it "does not double-escape variables assigned using assign" do
    verify_template_output(
      "{% autoescape %}{% assign variable = \"&\" %}{{ variable }}{% endautoescape %}",
      "&amp;"
    )
  end

  it "can be called multiple times" do
    verify_template_output(
      "{% autoescape %}{{ var }}{% endautoescape %} {{ var }} {% autoescape %}{{ var }}{% endautoescape %}",
      "&amp; & &amp;",
      "var" => "&"
    )
  end

  it "does not escape variables with the skip_escape filter applied" do
    verify_template_output(
      "{% autoescape %}{{ variable | skip_escape }}{% endautoescape %}",
      "<strong>&amp;</strong>",
      "variable" => "<strong>&amp;</strong>"
    )
  end

  it "raises an error when called with arguments" do
    invalid = "{% autoescape on %}{% endautoescape %}"
    expect { Liquid::Template.parse(invalid) }.to raise_error(Liquid::SyntaxError)
  end

  describe "configuration options" do

    after(:each) { Liquid::Autoescape.reconfigure }

    context "with global mode enabled" do

      before(:each) do
        Liquid::Autoescape.configure do |config|
          config.global = true
        end
      end

      it "escapes variables outside of an autoescape block" do
        verify_template_output(
          "{{ variable }}",
          "&amp;",
          "variable" => "&"
        )
      end

      it "escapes variables in an autoescape block" do
        verify_template_output(
          "{% autoescape %}{{ variable }}{% endautoescape %}",
          "&amp;",
          "variable" => "&"
        )
      end

      it "respects escaping filters" do
        verify_template_output(
          "{{ variable | skip_escape }}{% autoescape %}{{ variable | skip_escape }}{% endautoescape %}",
          "&&",
          "variable" => "&"
        )
      end

      it "does not double-escape variables assigned using assign" do
        verify_template_output(
          "{% assign variable = \"&\" %}{{ variable }}",
          "&amp;"
        )
      end

    end

    context "with custom exemptions" do

      let(:exemptions) do
        Module.new do
          def exemption(variable)
            variable.name == "module"
          end
        end
      end

      before(:each) do
        Liquid::Autoescape.configure do |config|
          config.exemptions.add { |variable| variable.name == "filter" }
          config.exemptions.import(exemptions)
        end
      end

      it "does not escape exempt variables" do
        verify_template_output(
          "{% autoescape %}{{ filter }} {{ module }} {{ other }}{% endautoescape %}",
          "<a> <b> &lt;i&gt;",
          "filter" => "<a>", "module" => "<b>", "other" => "<i>"
        )
      end

      it "can handle exemptions with lookup-style variable names" do
        Liquid::Autoescape.configure do |config|
          config.exemptions.add { |variable| variable.name == "root.one" }
          config.exemptions.add { |variable| variable.name == "trunk.branch.leaf" }
        end

        verify_template_output(
          "{% autoescape %}{{ root.one }} {{ root.two }} {{ trunk.branch.leaf }}{% endautoescape %}",
          "<a> &lt;b&gt; <i>",
          "root" => {"one" => "<a>", "two" => "<b>"},
          "trunk" => {"branch" => {"leaf" => "<i>"}}
        )
      end

      it "respects the default exemptions" do
        verify_template_output(
          "{% autoescape %}{{ filter | skip_escape }} {{ other }}{% endautoescape %}",
          "<a> &lt;b&gt;",
          "filter" => "<a>", "other" => "<b>"
        )
      end

    end

    context "with trusted filters" do

      before(:each) do
        Liquid::Autoescape.configure do |config|
          config.trusted_filters << :downcase
        end
      end

      it "does not forget the default escaping filters" do
        verify_template_output(
          "{% autoescape %}{{ one | skip_escape }} {{ two | escape }}{% endautoescape %}",
          "<a> &lt;b&gt;",
          "one" => "<a>", "two" => "<b>"
        )
      end

      it "exempts variables that use one of the trusted filters" do
        verify_template_output(
          "{% autoescape %}{{ variable | downcase }} {{ variable | capitalize }}{% endautoescape %}",
          "r&d R&amp;d",
          "variable" => "R&D"
        )
      end

    end

  end

  it "does not escape objects" do
    verify_template_output(
      "{% autoescape %}{% assign obj2 = obj %}{{ obj2.foo }}{% endautoescape %}",
      "bar",
      "obj" => { "foo" => "bar" }
    )
  end

  it "does not escape before truncate" do
    verify_template_output(
      "{% autoescape %}{% assign foo = \"<div class='foo'>\" %}{{ foo | truncate: 6 }}{% endautoescape %}",
      "&lt;di...",
    )
  end

  it "does not escape literals from {% capture %}" do
    verify_template_output(
      "{% autoescape %}{% capture foo %}<div>{% endcapture %}{{ foo }}{% endautoescape %}",
      "<div>",
    )
  end

  it "escapes output of {% capture %} if a filter is applied" do
    verify_template_output(
      "{% autoescape %}{% capture foo %}<div>{% endcapture %}{{ foo | capitalize }}{% endautoescape %}",
      "&lt;div&gt;",
    )
  end

  it "escapes in {% capture %}" do
    verify_template_output(
      "{% autoescape %}{% capture foo %}It's {{ dangerous }}!{% endcapture %}{{ foo }}{% endautoescape %}",
      "It's &lt;div&gt;!",
      "dangerous" => "<div>"
    )
  end

  it "escapes in nested blocks in {% capture %}" do
    verify_template_output(
      "{% autoescape %}{% capture foo %}{% if true %}It's {{ dangerous }}{% endif %}!{% endcapture %}{{ foo }}{% endautoescape %}",
      "It's &lt;div&gt;!",
      "dangerous" => "<div>"
    )
  end

  it "doesnt break other nested tags" do
    verify_template_output(
      "{% autoescape %}{% if obj.foo != blank %}{{ obj.foo }}{% endif %}{% endautoescape %}",
      "bar",
      "obj" => { "foo" => "bar" }
    )
  end

  it "doesn't break blocks with multiple nodes" do
    verify_template_output(
      "{% autoescape %}{% if obj.foo != blank %}.test { a: func({{ obj.foo }}, {{ obj.baz }}); } {% endif %}{% endautoescape %}",
      ".test { a: func(bar, asd); } ",
      { "obj" => { "foo" => "bar", "baz" => "asd" } }
    )
  end


end
