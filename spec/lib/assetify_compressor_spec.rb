require File.dirname(__FILE__) + '/../spec_helper'

describe Assetify::AssetCompressor do
  it "should compress javascript" do
    javascript = <<-JS
      function foo(other)  {
        var t = "1234";
        var x = 8;
        return t + x;
      }
    JS
    
    comp = Assetify::AssetCompressor.new(javascript)
    comp.compress.should == %Q`function foo(b){var c="1234";var a=8;return c+a};`
  end
  
  it "should compress css" do
    css = <<-CSS
      html #dog {
          color: red;
          background-color: teal;
      }
      
      #rat {
          color: blue;
      }
    CSS
    
    comp = Assetify::AssetCompressor.new(css)
    comp.compress(:type => :css).should == %Q`html #dog{color:red;background-color:teal;}#rat{color:blue;}`
  end
end