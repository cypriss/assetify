module AssetifyHelper
  
  def assetify_javascript_library_include_tag(library = "library", options = {})
    asset = "/assets/#{library}.js"
    fix_rails_asset_cache(asset)
    javascript_include_tag(asset)
  end
  
  def assetify_javascript_dynamic_include_tag(options = {})
    cont = options.delete(:controller) || params[:controller]
    act = options.delete(:action) || params[:action]
    
    asset = "/assets/dynamic/#{cont}/#{act}.js"
    fix_rails_asset_cache(asset)
    javascript_include_tag(asset)
  end
  
  def assetify_stylesheet_library_include_tag(library = "library", options = {})
    include_print = options.delete(:include_print)
    include_ie = options.delete(:include_ie)
    
    primary_options = {} # TODO: this needs a test
    primary_media_type = options.delete(:primary_media_type)
    primary_options[:media] = primary_media_type if primary_media_type
    
    tags = []

    asset = "/assets/#{library}.css"
    fix_rails_asset_cache(asset)
    tags << stylesheet_link_tag(asset, primary_options)
    
    if include_print
      asset = "/assets/#{library}/print.css"
      fix_rails_asset_cache(asset)
      tags << stylesheet_link_tag(asset, :media => "print")
    end
    
    if include_ie
      asset = "/assets/#{library}/ie.css"
      fix_rails_asset_cache(asset)
      tags << ("<!--[if lt IE 8]>\n" + stylesheet_link_tag(asset) + "\n<![endif]-->")
    end
    
    tags.join("\n")
  end
  
  def assetify_stylesheet_dynamic_include_tag(options = {})
    cont = options.delete(:controller) || params[:controller]
    act = options.delete(:action) || params[:action]
    include_print = options.delete(:include_print)
    include_ie = options.delete(:include_ie)
      
    primary_options = {} # TODO: this needs a test
    primary_media_type = options.delete(:primary_media_type)
    primary_options[:media] = primary_media_type if primary_media_type
    
    tags = []
    
    asset = "/assets/dynamic/#{cont}/#{act}.css"
    fix_rails_asset_cache(asset)
    tags << stylesheet_link_tag(asset, primary_options)
    
    if include_print
      asset = "/assets/dynamic/#{cont}/#{act}/print.css"
      fix_rails_asset_cache(asset)
      tags << stylesheet_link_tag(asset, :media => "print")
    end
    
    if include_ie
      asset = "/assets/dynamic/#{cont}/#{act}/ie.css"
      fix_rails_asset_cache(asset)
      tags << ("<!--[if lt IE 8]>\n" + stylesheet_link_tag(asset) + "\n<![endif]-->")
    end
    
    tags.join("\n")
  end
  
  def assetify_timestamp_header
    <<-JS_TIMESTAMP
      <script type="text/javascript">
          var $loadTimes = {domHeader: new Date().getTime()};
      </script>
    JS_TIMESTAMP
  end
  
  def assetify_timestamp_after_body
    <<-JS_TIMESTAMP
      <script type="text/javascript">
          $loadTimes.domMiddle = new Date().getTime();
      </script>
    JS_TIMESTAMP
  end
  
  def assetify_timestamp_bottom(options = {})
    library = options.delete(:library) || :mootools
    output = options.delete(:output) || :console
    
    domready_function = {
      :mootools   =>  "window.addEvent('domready',function(){",
      :jquery     =>  "$(document).ready(function(){",
      :prototype  =>  "document.observe('dom:loaded',function(){"
    }[library]
    
    <<-JS_TIMESTAMP
      <script type="text/javascript">
          $loadTimes.domBottom = new Date().getTime();
        
          #{domready_function}
              $loadTimes.domReady = new Date().getTime();
            
              var str = "DomTop to (Middle, Bottom, DomReady): (" +
                        ($loadTimes.domMiddle - $loadTimes.domHeader) + ", " +
                        ($loadTimes.domBottom - $loadTimes.domHeader) + ", " +
                        ($loadTimes.domReady - $loadTimes.domHeader) + ")" +
                        " DomReady: " + ($loadTimes.domReady - $loadTimes.domBottom);
              
              if (#{output == :console} && (typeof console != "undefined") && console.log) {
                  console.log(str);
              } else if (#{output == :function}) {
                  #{options[:function]}(str);
              }
        });
        
      </script>
    JS_TIMESTAMP
  end
  
  private
    
    # NOTE: this function fixes Rails caching of asset timestamps
    # Without this, in production, scripts tags will look like "/assets/library.js",
    # because the file won't exist the first time through.  It will stay like this throughout the life of the application,
    # unless the server is restarted.
    # This method will cause the first asset to be "/assets/library.js", but all subsequent requests after that will
    # have the correct timestamp cached (eg, "/assets/library.js?234235235").
    def fix_rails_asset_cache(asset_name)
      if ActionView::Helpers::AssetTagHelper.cache_asset_timestamps
        timestamps_cache = self.class.send(:class_variable_get, :@@asset_timestamps_cache)
        timestamps_guard = self.class.send(:class_variable_get, :@@asset_timestamps_cache_guard)

        timestamps_guard.synchronize do 
          asset_id = timestamps_cache[asset_name]
          timestamps_cache.delete(asset_name) if asset_id == ''
        end
      end
    end
end