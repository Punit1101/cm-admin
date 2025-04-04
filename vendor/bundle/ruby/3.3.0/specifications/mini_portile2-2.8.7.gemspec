# -*- encoding: utf-8 -*-
# stub: mini_portile2 2.8.7 ruby lib

Gem::Specification.new do |s|
  s.name = "mini_portile2".freeze
  s.version = "2.8.7".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Luis Lavena".freeze, "Mike Dalessio".freeze, "Lars Kanis".freeze]
  s.date = "2024-05-31"
  s.description = "Simple autoconf and cmake builder for developers. It provides a standard way to compile against\ndependency libraries without requiring system-wide installation. It also simplifies\nvendoring and cross-compilation by providing a consistent build interface.\n".freeze
  s.email = "mike.dalessio@gmail.com".freeze
  s.homepage = "https://github.com/flavorjones/mini_portile".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3.0".freeze)
  s.rubygems_version = "3.5.10".freeze
  s.summary = "Simple autoconf and cmake builder for developers".freeze

  s.installed_by_version = "3.5.22".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, ["~> 2.2".freeze])
  s.add_development_dependency(%q<minitar>.freeze, ["~> 0.9".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.15".freeze])
  s.add_development_dependency(%q<minitest-hooks>.freeze, ["~> 1.5".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0".freeze])
  s.add_development_dependency(%q<webrick>.freeze, ["~> 1.7".freeze])
end
