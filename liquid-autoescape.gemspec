lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

require "liquid/autoescape/version"

Gem::Specification.new do |s|
  s.name         = "liquid-autoescape"
  s.version      = Liquid::Autoescape::VERSION
  s.summary      = "Autoescape support for Liquid"
  s.description  = "Apply HTML escaping to all variables in a Liquid block"
  s.authors      = ["Within3"]
  s.email        = ["it-operations@within3.com"]
  s.homepage     = "https://github.com/Within3/liquid-autoescape"
  s.license      = "MIT"

  s.required_ruby_version = ">= 2.1.0"

  s.files        = %w[LICENSE README.md]
  s.files       += Dir.glob("lib/**/*")
  s.files       += Dir.glob("spec/**/*")
  s.test_files   = Dir.glob("spec/**/*")

  s.add_dependency "liquid", ">= 2.0", "< 4.0"

  s.add_development_dependency "appraisal", "~> 2.0"
  s.add_development_dependency "rake", "~> 12.0"
  s.add_development_dependency "rspec", "~> 3.0"
  s.add_development_dependency "rubocop", "~> 0.52"
  s.add_development_dependency "yard", "~> 0.9.11"
end
