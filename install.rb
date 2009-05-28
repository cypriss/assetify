require "fileutils"
include FileUtils::Verbose
 
RAILS_ROOT = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..")) unless defined?(RAILS_ROOT)

mkdir_p File.join(RAILS_ROOT, "app", "javascripts/dynamic")
mkdir_p File.join(RAILS_ROOT, "app", "stylesheets/dynamic")
touch File.join(RAILS_ROOT, "app", "javascripts", "library.dependencies.json")
touch File.join(RAILS_ROOT, "app", "javascripts", "dynamic.dependencies.json")
touch File.join(RAILS_ROOT, "app", "stylesheets", "library.dependencies.json")
touch File.join(RAILS_ROOT, "app", "stylesheets", "dynamic.dependencies.json")

# TODO: copy real dependency files