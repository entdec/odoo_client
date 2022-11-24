$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "odoo_client/client"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "odoo_client"
  s.version     = Odoo::Client::VERSION
  s.authors     = ["Valentin LAMBOLEY", "Justin Berhang"]
  s.email       = ["vlamboley@zeto.fr", "justin@scratch.com"]
  s.homepage    = "https://github.com/Yub0/odoo_client"
  s.summary     = "Pure Ruby Client for Odoo ERP"
  s.description = "Connect to Odoo ERP and perform CRUD operations."
  s.license     = "MIT"
  s.add_runtime_dependency 'xmlrpc', '~> 0.3.0'

  s.files = Dir["{lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
end