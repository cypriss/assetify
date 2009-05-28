begin
  require File.join(File.expand_path(File.join(File.dirname(__FILE__), '/../../../../')),  'spec/spec_helper')
rescue LoadError
  puts "You need to install rspec in your base app"
  exit
end