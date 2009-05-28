require File.dirname(__FILE__) + '/../spec_helper'

describe Assetify do
  it "should create one js asset secretary per asset (dup)" do
    Assetify.send(:instance_variable_set, :@secretaries, {})
    Assetify::AssetSecretary.should_receive(:new).once.and_return(mock(Object, :full_concatenation => "dood"))
    Assetify.js_library_source("library")
    Assetify.js_library_source("library")
  end
  
  it "should create one js asset secretary per asset (2 libs)" do
    Assetify.send(:instance_variable_set, :@secretaries, {})
    File.should_receive(:exist?).any_number_of_times.and_return(true)
    Assetify::AssetSecretary.should_receive(:new).twice.and_return(mock(Object, :full_concatenation => "dood"))
    Assetify.js_library_source("library")
    Assetify.js_library_source("foobar")
  end
  
  it "should create one css asset secretary per asset (dup)" do
    Assetify.send(:instance_variable_set, :@secretaries, {})
    Assetify::AssetSecretary.should_receive(:new).once.and_return(mock(Object, :full_concatenation => "dood"))
    Assetify.css_library_source("library")
    Assetify.css_library_source("library")
  end
  
  it "should create one css asset secretary per asset (2 libs)" do
    Assetify.send(:instance_variable_set, :@secretaries, {})
    File.should_receive(:exist?).any_number_of_times.and_return(true)
    Assetify::AssetSecretary.should_receive(:new).twice.and_return(mock(Object, :full_concatenation => "dood"))
    Assetify.css_library_source("library")
    Assetify.css_library_source("foobar")
  end
  
  it "should create one asset secretary per asset (2 libs, 2 types)" do
    Assetify.send(:instance_variable_set, :@secretaries, {})
    Assetify::AssetSecretary.should_receive(:new).twice.and_return(mock(Object, :full_concatenation => "dood"))
    Assetify.js_library_source("library")
    Assetify.js_library_source("library")
    Assetify.css_library_source("library")
    Assetify.css_library_source("library")
  end
  
  it "should handle js dynamic assets" do
    Assetify.send(:instance_variable_set, :@secretaries, {})
    File.should_receive(:exist?).any_number_of_times.and_return(true)
    Assetify::AssetSecretary.should_receive(:new).once.with(/dynamic/, {:type => :js}).and_return(mock(Object, :concatenation_for_view => "dood"))
    Assetify.js_dynamic_source("accounts", "index")
  end
  
  it "should handle css dynamic assets" do
    Assetify.send(:instance_variable_set, :@secretaries, {})
    Assetify::AssetSecretary.should_receive(:new).once.with(/dynamic/, {:type => :css}).and_return(mock(Object, :concatenation_for_view => "dood"))
    Assetify.css_dynamic_source("accounts", "index")
  end
  
  it "should compress assets" do
    Assetify.send(:instance_variable_set, :@secretaries, {})
    Assetify.should_receive(:compress_assets?).and_return(true)
    File.should_receive(:exist?).any_number_of_times.and_return(true)
    Assetify::AssetSecretary.should_receive(:new).once.and_return(mock(Object, :full_concatenation => "dood"))
    Assetify::AssetCompressor.should_receive(:new).once.and_return(mock(Object, :compress => "hello"))
    data = Assetify.js_library_source("ohmy")
    data.should == "hello"
  end
  
  it "should raise Assetify::NoSuchAssetException when the library file isn't found" do
    lambda {
      Assetify.js_library_source("doesntexist")
    }.should raise_error(Assetify::NoSuchAssetException)
  end
end