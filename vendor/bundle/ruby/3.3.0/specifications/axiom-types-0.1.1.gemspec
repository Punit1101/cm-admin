# -*- encoding: utf-8 -*-
# stub: axiom-types 0.1.1 ruby lib

Gem::Specification.new do |s|
  s.name = "axiom-types".freeze
  s.version = "0.1.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Dan Kubb".freeze]
  s.date = "2014-03-27"
  s.description = "Define types with optional constraints for use within axiom and other libraries.".freeze
  s.email = "dan.kubb@gmail.com".freeze
  s.extra_rdoc_files = ["LICENSE".freeze, "README.md".freeze, "CONTRIBUTING.md".freeze, "TODO".freeze]
  s.files = ["CONTRIBUTING.md".freeze, "LICENSE".freeze, "README.md".freeze, "TODO".freeze]
  s.homepage = "https://github.com/dkubb/axiom-types".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3".freeze)
  s.rubygems_version = "2.2.2".freeze
  s.summary = "Abstract types for logic programming".freeze

  s.installed_by_version = "3.5.22".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<descendants_tracker>.freeze, ["~> 0.0.4".freeze])
  s.add_runtime_dependency(%q<ice_nine>.freeze, ["~> 0.11.0".freeze])
  s.add_runtime_dependency(%q<thread_safe>.freeze, ["~> 0.3".freeze, ">= 0.3.1".freeze])
  s.add_development_dependency(%q<bundler>.freeze, ["~> 1.5".freeze, ">= 1.5.3".freeze])
end
