# encoding: utf-8

Gem::Specification.new do |s|
  s.name = "px"
  s.version = "0.0.2"
  s.summary = "PX library"
  s.description = "PaymentExpress 2.0 integration library"
  s.authors = ["Cyril David"]
  s.email = ["cyx@cyx.is"]
  s.homepage = "http://cyx.is"
  s.files = Dir[
    "LICENSE",
    "README*",
    "Makefile",
    "lib/*.rb",
    "lib/xml/*.xml",
    "*.gemspec",
    "test/*.*",
  ]

  s.license = "MIT"

  s.add_dependency "requests", "~> 1.0"
  s.add_dependency "xml-simple", "~> 1.1"
  s.add_dependency "mote", "~> 1.1"
  s.add_dependency "hache", "~> 1.1"
  s.add_development_dependency "cutest", "~> 1.2"
end
