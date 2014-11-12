# encoding: utf-8

Gem::Specification.new do |s|
  s.name = "px"
  s.version = "0.0.1"
  s.summary = "PX library"
  s.description = "PX library"
  s.authors = ["Cyril David"]
  s.email = ["cyx@cyx.is"]
  s.homepage = "http://cyx.is"
  s.files = Dir[
    "LICENSE",
    "README*",
    "Makefile",
    "lib/**/*.rb",
    "*.gemspec",
    "test/*.*",
  ]

  s.license = "MIT"

  s.add_dependency "requests"
  s.add_dependency "xml-simple"
  s.add_dependency "mote"
  s.add_dependency "hache"
  s.add_development_dependency "cutest"
end
