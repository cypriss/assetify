require File.dirname(__FILE__) + '/../spec_helper'

describe AssetsController do
  it "should render dynamic javascript" do
    Assetify.should_receive(:js_dynamic_source).with("accounts", "index").and_return("lol")
    get :dynamic, {:cont => "accounts", :act => "index", :format => "js"}
    response.should be_success
    response.header["Content-Type"].should match(/text\/javascript/)
  end
  
  it "should render dynamic css" do
    Assetify.should_receive(:css_dynamic_source).with("accounts", "index", :standard).and_return("lol")
    get :dynamic, {:cont => "accounts", :act => "index", :format => "css"}
    response.should be_success
    response.header["Content-Type"].should match(/text\/css/)
  end
  
  it "should render dynamic print css" do
    Assetify.should_receive(:css_dynamic_source).with("accounts", "index", :print).and_return("lol")
    get :dynamic, {:cont => "accounts", :act => "index", :kind => "print", :format => "css"}
    response.should be_success
    response.header["Content-Type"].should match(/text\/css/)
  end
  
  it "should render library js" do
    Assetify.should_receive(:js_library_source).with("foo").and_return("lol")
    get :show, {:id => "foo", :format => "js"}
    response.should be_success
    response.header["Content-Type"].should match(/text\/javascript/)
  end
  
  it "should render library css" do
    Assetify.should_receive(:css_library_source).with("foo", :standard).and_return("lol")
    get :show, {:id => "foo", :format => "css"}
    response.should be_success
    response.header["Content-Type"].should match(/text\/css/)
  end
  
  it "should render library ie css" do
    Assetify.should_receive(:css_library_source).with("foo", :ie).and_return("lol")
    get :show, {:id => "foo", :kind => "ie", :format => "css"}
    response.should be_success
    response.header["Content-Type"].should match(/text\/css/)
  end
  
  it "should throw ActionController::RoutingError if the js library doesn't exist" do
    Assetify.should_receive(:js_library_source).with("foo").and_raise(Assetify::NoSuchAssetException)
    lambda {
      get :show, {:id => "foo", :format => "js"}
    }.should raise_error(ActionController::RoutingError)
  end
  
  it "should throw ActionController::RoutingError if the css library doesn't exist" do
    Assetify.should_receive(:css_library_source).with("foo", :standard).and_raise(Assetify::NoSuchAssetException)
    lambda {
      get :show, {:id => "foo", :format => "css"}
    }.should raise_error(ActionController::RoutingError)
  end
end
