require File.dirname(__FILE__) + '/../spec_helper'

describe AssetifyHelper do
  it "should link to a JS library file" do
    tag = helper.assetify_javascript_library_include_tag
    tag.should == %Q`<script src="/assets/library.js" type="text/javascript"></script>`
  end
  
  it "should link to another JS library file" do
    tag = helper.assetify_javascript_library_include_tag("foo")
    tag.should == %Q`<script src="/assets/foo.js" type="text/javascript"></script>`
  end
  
  it "should link to a dynamic JS file" do
    params[:controller] = "accounts"
    params[:action] = "index"
    tag = helper.assetify_javascript_dynamic_include_tag
    tag.should == %Q`<script src="/assets/dynamic/accounts/index.js" type="text/javascript"></script>`
  end
  
  it "should link to another dynamic JS file" do
    params[:controller] = "accounts"
    params[:action] = "index"
    tag = helper.assetify_javascript_dynamic_include_tag(:controller => "soup", :action => "nuts")
    tag.should == %Q`<script src="/assets/dynamic/soup/nuts.js" type="text/javascript"></script>`
  end
  
  it "should link to a CSS library file" do
    tag = helper.assetify_stylesheet_library_include_tag
    tag.should == %Q`<link href="/assets/library.css" media="screen" rel="stylesheet" type="text/css" />`
  end
  
  it "should link to another CSS library file" do
    tag = helper.assetify_stylesheet_library_include_tag("foo")
    tag.should == %Q`<link href="/assets/foo.css" media="screen" rel="stylesheet" type="text/css" />`
  end
  
  it "should link to a CSS library file with print" do
    tag = helper.assetify_stylesheet_library_include_tag("library", :include_print => true)
    tag.should == %Q`<link href="/assets/library.css" media="screen" rel="stylesheet" type="text/css" />\n<link href="/assets/library/print.css" media="print" rel="stylesheet" type="text/css" />`
  end
  
  it "should link to a CSS library file with ie" do
    tag = helper.assetify_stylesheet_library_include_tag("library", :include_ie => true)
    tag.should == %Q`<link href="/assets/library.css" media="screen" rel="stylesheet" type="text/css" />\n<!--[if lt IE 8]>\n<link href="/assets/library/ie.css" media="screen" rel="stylesheet" type="text/css" />\n<![endif]-->`
  end
  
  it "should link to a CSS library file with both print and ie" do
    tag = helper.assetify_stylesheet_library_include_tag("library", :include_print => true, :include_ie => true)
    tag.should == %Q`<link href="/assets/library.css" media="screen" rel="stylesheet" type="text/css" />\n<link href="/assets/library/print.css" media="print" rel="stylesheet" type="text/css" />\n<!--[if lt IE 8]>\n<link href="/assets/library/ie.css" media="screen" rel="stylesheet" type="text/css" />\n<![endif]-->`
  end
  
  it "should link to a CSS dyanmic file" do
    params[:controller], params[:action] = "accounts", "index"
    tag = helper.assetify_stylesheet_dynamic_include_tag
    tag.should == %Q`<link href="/assets/dynamic/accounts/index.css" media="screen" rel="stylesheet" type="text/css" />`
  end
  
  it "should link to another CSS dyanmic file" do
    params[:controller], params[:action] = "accounts", "index"
    tag = helper.assetify_stylesheet_dynamic_include_tag(:controller => "soup", :action => "nuts")
    tag.should == %Q`<link href="/assets/dynamic/soup/nuts.css" media="screen" rel="stylesheet" type="text/css" />`
  end
  
  it "should link to a CSS dyanmic file with print" do
    params[:controller], params[:action] = "accounts", "index"
    tag = helper.assetify_stylesheet_dynamic_include_tag(:include_print => true)
    tag.should == %Q`<link href="/assets/dynamic/accounts/index.css" media="screen" rel="stylesheet" type="text/css" />\n<link href="/assets/dynamic/accounts/index/print.css" media="print" rel="stylesheet" type="text/css" />`
  end
  
  it "should link to a CSS dyanmic file with ie" do
    params[:controller], params[:action] = "accounts", "index"
    tag = helper.assetify_stylesheet_dynamic_include_tag(:include_ie => true)
    tag.should == %Q`<link href="/assets/dynamic/accounts/index.css" media="screen" rel="stylesheet" type="text/css" />\n<!--[if lt IE 8]>\n<link href="/assets/dynamic/accounts/index/ie.css" media="screen" rel="stylesheet" type="text/css" />\n<![endif]-->`
  end
  
  it "should link to a CSS dyanmic file with both print and ie" do
    params[:controller], params[:action] = "accounts", "index"
    tag = helper.assetify_stylesheet_dynamic_include_tag(:include_ie => true, :include_print => true)
    tag.should == %Q`<link href="/assets/dynamic/accounts/index.css" media="screen" rel="stylesheet" type="text/css" />\n<link href="/assets/dynamic/accounts/index/print.css" media="print" rel="stylesheet" type="text/css" />\n<!--[if lt IE 8]>\n<link href="/assets/dynamic/accounts/index/ie.css" media="screen" rel="stylesheet" type="text/css" />\n<![endif]-->`
  end
  
  it "shouldn't break because Rails made a change to their internal implementation of asset timestamp caching" do
    timestamps_cache = helper.class.send(:class_variable_get, :@@asset_timestamps_cache)
    timestamps_guard = helper.class.send(:class_variable_get, :@@asset_timestamps_cache_guard)
    
    timestamps_cache.should be_an_instance_of(Hash)
    timestamps_guard.should be_an_instance_of(Mutex)
  end
  
  it "should respond to timestamp helpers" do
    helper.should respond_to(:assetify_timestamp_header)
    helper.should respond_to(:assetify_timestamp_after_body)
    helper.should respond_to(:assetify_timestamp_bottom)
  end
end