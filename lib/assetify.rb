module Assetify
  
  class NoSuchAssetException < Exception; end
  
  class << self
    def js_library_source(library)
      filter_with_compression(secretary_for(library, :js).full_concatenation, :type => :js)
    end
    
    def css_library_source(library, kind = :standard)
      filter_with_compression(secretary_for(library, :css).full_concatenation(kind), :type => :css)
    end
    
    def js_dynamic_source(controller, action)
      filter_with_compression(secretary_for("dynamic", :js).concatenation_for_view(controller, action), :type => :js)
    end
    
    def css_dynamic_source(controller, action, kind = :standard)
      filter_with_compression(secretary_for("dynamic", :css).concatenation_for_view(controller, action, kind), :type => :css)
    end
 
    protected
      def secretary_for(library, type)
        @secretaries ||= {}
        @secretaries[library + "_#{type}"] ||= Assetify::AssetSecretary.new(dependency_map_file(library, type), :type => type)
      end
      
      def dependency_map_file(library, type)
        subfolder = (type == :js) ? "javascripts" : "stylesheets"
        file = File.join(Rails.root, "app", subfolder, "#{library}.dependencies.json")
        raise NoSuchAssetException, "Could not find the specified asset." unless File.exist?(file)
        file
      end
      
      def filter_with_compression(string, options)
        if compress_assets?
          AssetCompressor.new(string).compress(options)
        else
          string
        end
      end
      
      def compress_assets?
        Rails.env.production?
      end
  end
end