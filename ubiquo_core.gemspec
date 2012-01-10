# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ubiquo/version"

Gem::Specification.new do |s|
  s.name        = "ubiquo_core"
  s.version     = Ubiquo.version
  s.authors     = ["Jordi Beltran", "Albert Callarisa", "Bernat Foj", "Eric Garcia", "Felip Ladrón", "David Lozano", "Toni Reina", "Ramon Salvadó", "Arnau Sánchez"]
  s.homepage    = "http://www.ubiquo.me"
  s.summary     = %q{Core gem of the ubiquo cms framework}
  s.description = %q{Provides the basic common Ubiquo infrastructure so that other plugins can be built on top of it}

  s.rubyforge_project = "ubiquo_core"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency "rails", ["~> 3.2.0.rc2"]
  s.add_development_dependency "mocha", "~> 0.10.0"
  s.add_development_dependency "sqlite3", "~> 1.3.5"
  s.add_development_dependency 'linecache19'
  s.add_development_dependency 'ruby-debug-base19x', '~> 0.11.30.pre4'
  s.add_development_dependency 'ruby-debug19', "~> 0.11.6"

end
