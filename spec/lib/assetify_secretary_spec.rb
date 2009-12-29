require File.dirname(__FILE__) + '/../spec_helper'

describe Assetify::AssetSecretary do
  before(:all) do
    @js_lib_map_basic = File.join(File.dirname(__FILE__) + '/../fixtures', 'app_basic', 'javascripts', 'library.dependencies.json')
    @css_lib_map_basic = File.join(File.dirname(__FILE__) + '/../fixtures', 'app_basic', 'stylesheets', 'foo.dependencies.json')
    @js_lib_map1 = File.join(File.dirname(__FILE__) + '/../fixtures', 'app', 'javascripts', 'library.dependencies.json')
    @js_dyn_map1 = File.join(File.dirname(__FILE__) + '/../fixtures', 'app', 'javascripts', 'dynamic.dependencies.json')
    @css_dyn_map1 = File.join(File.dirname(__FILE__) + '/../fixtures', 'app', 'stylesheets', 'dynamic.dependencies.json')
    @js_lib_map_empty = File.join(File.dirname(__FILE__) + '/../fixtures', 'app', 'javascripts', 'empty.dependencies.json')
    @js_lib_map_circular = File.join(File.dirname(__FILE__) + '/../fixtures', 'app', 'javascripts', 'circular.dependencies.json')
    @css_lib_map_nested = File.join(File.dirname(__FILE__) + '/../fixtures', 'app', 'stylesheets', 'library.dependencies.json')
    @css_lib_map_really_nested = File.join(File.dirname(__FILE__) + '/../fixtures', 'app', 'stylesheets', 'librarynest.dependencies.json')
  end

  it "should use the dependency map to order two simple js files" do
    secretary = Assetify::AssetSecretary.new(@js_lib_map_basic, :type => :js)
    js = secretary.full_concatenation
    js = js.gsub(/\s|\n|\r/m, "")
    js.should == "BA"
  end
  
  it "should use the dependency map to order two simple css files" do
    secretary = Assetify::AssetSecretary.new(@css_lib_map_basic, :type => :css)
    js = secretary.full_concatenation
    js = js.gsub(/\s|\n|\r/m, "")
    js.should == "ED"
  end
  
  it "should use the dependency map to order files" do
    secretary = Assetify::AssetSecretary.new(@js_lib_map1, :type => :js)
    js = secretary.full_concatenation
    js = js.gsub(/\s|\n|\r/m, "")
    js.should == "AFGHCXEYZBD"
  end
  
  it "should use the dep map to order files for a controller/view" do
    secretary = Assetify::AssetSecretary.new(@js_dyn_map1, :type => :js)
    js = secretary.concatenation_for_view("home", "index")
    js = js.gsub(/\s|\n|\r/m, "")
    js.should == "AHOMEINDEX"
  end
  
  it "should handle an empty dependency map for a library" do
    secretary = Assetify::AssetSecretary.new(@js_lib_map_empty, :type => :js)
    js = secretary.full_concatenation
    js = js.gsub(/\s|\n|\r/m, "")
    js.should == ""
  end
  
  it "should handle an empty dependency map for a dynamic and still return the controller/action files" do
    secretary = Assetify::AssetSecretary.new(@js_lib_map_empty, :type => :js)
    js = secretary.concatenation_for_view("home", "index")
    js = js.gsub(/\s|\n|\r/m, "")
    js.should == "HOMEINDEX"
  end
  
  it "should utilize a nested dependency file" do
    secretary = Assetify::AssetSecretary.new(@css_lib_map_nested, :type => :css)
    js = secretary.full_concatenation
    js = js.gsub(/\s|\n|\r/m, "")
    js.should == "ABCD"
  end
  
  it "should utilize multiple nested dependency files" do
    secretary = Assetify::AssetSecretary.new(@css_lib_map_really_nested, :type => :css)
    js = secretary.full_concatenation
    js = js.gsub(/\s|\n|\r/m, "")
    js.should == "ABCDEF"
  end
  
  it "should return concatenations for a different kind" do
    secretary = Assetify::AssetSecretary.new(@css_lib_map_nested, :type => :css)
    js = secretary.full_concatenation(:ie)
    js = js.gsub(/\s|\n|\r/m, "")
    js.should == "BiCiDi"
  end
  
  it "should return an empty concat for a different kind if that kind doesn't exist" do
    secretary = Assetify::AssetSecretary.new(@css_lib_map_basic, :type => :css)
    js = secretary.full_concatenation(:print)
    js = js.gsub(/\s|\n|\r/m, "")
    js.should == ""
  end
  
  it "should return dynamic concats of a different kind" do
    secretary = Assetify::AssetSecretary.new(@css_dyn_map1, :type => :css)
    js = secretary.concatenation_for_view("home", "list", :print)
    js = js.gsub(/\s|\n|\r/m, "")
    js.should == "HOMEpLISTp"
  end
  
  it "shouldn't regenerate the concat if the mtime hasn't changed" do
    secretary = Assetify::AssetSecretary.new(@js_lib_map_basic, :type => :js)
    
    secretary.should_not_receive(:reset!)
    secretary.should_receive(:concatenate).once.and_return("dude")
    js = secretary.full_concatenation
    js = secretary.full_concatenation
  end
  
  it "should regenerate the concat if the JS file's mtime changes" do
    File.stub!(:mtime).and_return(Time.parse("1/1/2002"))
    secretary = Assetify::AssetSecretary.new(@js_lib_map_basic, :type => :js)
    File.should_receive(:mtime).with(/\.js$/).any_number_of_times.and_return(Time.parse("1/1/2002") + 1.days)
    File.should_receive(:mtime).with(/\.json$/).once.and_return(Time.parse("1/1/2002"))
    secretary.should_receive(:reset!)
    secretary.should_receive(:concatenate).once.and_return("dude")
    js = secretary.full_concatenation
  end
  
  it "should regenerate the concat if the JS map file changes" do
    File.stub!(:mtime).and_return(Time.parse("1/1/2002"))
    secretary = Assetify::AssetSecretary.new(@js_lib_map_basic, :type => :js)
    File.should_receive(:mtime).with(/\.js$/).any_number_of_times.and_return(Time.parse("1/1/2002"))
    File.should_receive(:mtime).with(/\.json$/).once.and_return(Time.parse("1/1/2002") + 1.days)
    secretary.should_receive(:reset!)
    secretary.should_receive(:concatenate).once.and_return("dude")
    js = secretary.full_concatenation
  end
  
  it "should detect circular dependencies" do
    secretary = Assetify::AssetSecretary.new(@js_lib_map_circular, :type => :js)
    lambda {
      js = secretary.full_concatenation
    }.should raise_error(Exception)
  end
end
