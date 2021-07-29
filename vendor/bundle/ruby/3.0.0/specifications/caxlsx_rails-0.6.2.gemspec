# -*- encoding: utf-8 -*-
# stub: caxlsx_rails 0.6.2 ruby lib

Gem::Specification.new do |s|
  s.name = "caxlsx_rails".freeze
  s.version = "0.6.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Noel Peden".freeze]
  s.date = "2019-12-19"
  s.description = "Caxlsx_Rails provides an Caxlsx renderer so you can move all your spreadsheet code from your controller into view files. Partials are supported so you can organize any code into reusable chunks (e.g. cover sheets, common styling, etc.) You can use it with acts_as_caxlsx, placing the to_xlsx call in a view and adding ':package => xlsx_package' to the parameter list. Now you can keep your controllers thin!".freeze
  s.email = ["noel@peden.biz".freeze]
  s.homepage = "https://github.com/caxlsx/caxlsx_rails".freeze
  s.rubygems_version = "3.2.3".freeze
  s.summary = "A simple rails plugin to provide an xlsx renderer using the caxlsx gem.".freeze

  s.installed_by_version = "3.2.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<actionpack>.freeze, [">= 3.1"])
    s.add_runtime_dependency(%q<caxlsx>.freeze, [">= 3.0"])
    s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    s.add_development_dependency(%q<rspec-rails>.freeze, [">= 0"])
    s.add_development_dependency(%q<guard-rspec>.freeze, [">= 0"])
    s.add_development_dependency(%q<capybara>.freeze, [">= 0"])
    s.add_development_dependency(%q<roo>.freeze, [">= 0"])
    s.add_development_dependency(%q<rubyzip>.freeze, [">= 0"])
    s.add_development_dependency(%q<growl>.freeze, [">= 0"])
    s.add_development_dependency(%q<rb-fsevent>.freeze, [">= 0"])
    s.add_development_dependency(%q<coveralls>.freeze, [">= 0"])
    s.add_development_dependency(%q<pry>.freeze, [">= 0"])
    s.add_development_dependency(%q<pry-nav>.freeze, [">= 0"])
  else
    s.add_dependency(%q<actionpack>.freeze, [">= 3.1"])
    s.add_dependency(%q<caxlsx>.freeze, [">= 3.0"])
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<rspec-rails>.freeze, [">= 0"])
    s.add_dependency(%q<guard-rspec>.freeze, [">= 0"])
    s.add_dependency(%q<capybara>.freeze, [">= 0"])
    s.add_dependency(%q<roo>.freeze, [">= 0"])
    s.add_dependency(%q<rubyzip>.freeze, [">= 0"])
    s.add_dependency(%q<growl>.freeze, [">= 0"])
    s.add_dependency(%q<rb-fsevent>.freeze, [">= 0"])
    s.add_dependency(%q<coveralls>.freeze, [">= 0"])
    s.add_dependency(%q<pry>.freeze, [">= 0"])
    s.add_dependency(%q<pry-nav>.freeze, [">= 0"])
  end
end
