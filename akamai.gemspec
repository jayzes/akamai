# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "akamai/version"

Gem::Specification.new do |s|
  s.name        = "akamai"
  s.version     = Akamai::VERSION
  s.authors     = ["Jay Zeschin"]
  s.email       = ["jay@zeschin.org"]
  s.homepage    = "https://github.com/jayzes/akamai"
  s.summary     = %Q{Simple library for interacting with Akamai NetStorage and EdgeSuite caches}
  s.description = %Q{Simple library for interacting with Akamai NetStorage and EdgeSuite caches}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
