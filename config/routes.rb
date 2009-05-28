ActionController::Routing::Routes.draw do |map|

  unless Rails.env.production?
    map.assetify_info 'assets/info', :controller => 'assets', :action => 'info', :conditions => {:method => :get}
  end

  map.assetify_library 'assets/:id.:format',
                       :controller => 'assets',
                       :action => 'show',
                       :conditions => { :method => :get }
                             
  map.assetify_library_with_kind 'assets/:id/:kind.:format',
                                 :controller => 'assets',
                                 :action => 'show',
                                 :conditions => { :method => :get }
  
  map.assetify_dynamic 'assets/dynamic/:cont/:act.:format',
                       :controller => 'assets',
                       :action => 'dynamic',
                       :conditions => { :method => :get }

  map.assetify_dynamic_with_kind 'assets/dynamic/:cont/:act/:kind.:format',
                                 :controller => 'assets',
                                 :action => 'dynamic',
                                 :conditions => { :method => :get }
end
