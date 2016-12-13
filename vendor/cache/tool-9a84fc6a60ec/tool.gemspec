# -*- encoding: utf-8 -*-
# stub: tool 0.2.3 ruby lib

Gem::Specification.new do |s|
  s.name = "tool".freeze
  s.version = "0.2.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Konstantin Haase".freeze]
  s.date = "2016-12-13"
  s.description = "general purpose Ruby library used by Sinatra 2.0, Mustermann and related projects".freeze
  s.email = "konstantin.mailinglists@googlemail.com".freeze
  s.extra_rdoc_files = ["README.md".freeze]
  s.files = [".gitignore".freeze, ".rspec".freeze, ".travis.yml".freeze, "Gemfile".freeze, "LICENSE".freeze, "README.md".freeze, "Rakefile".freeze, "examples/frank.rb".freeze, "lib/tool/decoration.rb".freeze, "lib/tool/equality_map.rb".freeze, "lib/tool/thread_local.rb".freeze, "lib/tool/version.rb".freeze, "lib/tool/warning_filter.rb".freeze, "spec/decoration_spec.rb".freeze, "spec/equality_map_spec.rb".freeze, "spec/support/coverage.rb".freeze, "spec/thread_local_spec.rb".freeze, "tool.gemspec".freeze]
  s.homepage = "https://github.com/rkh/tool".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0.0".freeze)
  s.rubygems_version = "2.5.2".freeze
  s.summary = "general purpose library".freeze
  s.test_files = ["spec/decoration_spec.rb".freeze, "spec/equality_map_spec.rb".freeze, "spec/support/coverage.rb".freeze, "spec/thread_local_spec.rb".freeze]

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0.0.beta"])
      s.add_development_dependency(%q<simplecov>.freeze, [">= 0"])
      s.add_development_dependency(%q<coveralls>.freeze, [">= 0"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    else
      s.add_dependency(%q<rspec>.freeze, ["~> 3.0.0.beta"])
      s.add_dependency(%q<simplecov>.freeze, [">= 0"])
      s.add_dependency(%q<coveralls>.freeze, [">= 0"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<rspec>.freeze, ["~> 3.0.0.beta"])
    s.add_dependency(%q<simplecov>.freeze, [">= 0"])
    s.add_dependency(%q<coveralls>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
  end
end
