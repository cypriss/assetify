require 'fileutils'

class AssetsController < ActionController::Base
  
  if Assetify.cache_mode == 'page'
    caches_page :show
    caches_page :dynamic
  end
  
  def show
    response.headers['Cache-Control'] = 'public, max-age=43200' # Cache for 12 hours
    
    respond_to do |wants|
      wants.js do
        render :text => Assetify.js_library_source(params[:id]), :content_type => "text/javascript"
      end
      
      wants.css do
        kind = (params[:kind] || :standard).to_sym
        render :text => Assetify.css_library_source(params[:id], kind), :content_type => "text/css"
      end
    end
  rescue Assetify::NoSuchAssetException => e
    raise ActionController::RoutingError, e.message
  end
  
  def dynamic
    response.headers['Cache-Control'] = 'public, max-age=43200' # Cache for 12 hours
    
    respond_to do |wants|
      wants.js do
        render :text => Assetify.js_dynamic_source(params[:cont], params[:act]), :content_type => "text/javascript"
      end
      
      wants.css do
        kind = (params[:kind] || :standard).to_sym
        render :text => Assetify.css_dynamic_source(params[:cont], params[:act], kind), :content_type => "text/css"
      end
    end
  end
  
  def info
    type = params[:type] || "js"
    if type == "js"
      asset_folder = "javascripts"
      asset_suffix = "js"
      asset_symbol = :js
      asset_library_method = :js_library_source
      asset_dynamic_method = :js_dynamic_source
    elsif type == "css"
      asset_folder = "stylesheets"
      asset_suffix = "css"
      asset_symbol = :css
      asset_library_method = :css_library_source
      asset_dynamic_method = :css_dynamic_source
    else
      raise "You're retarded"
    end
    
    # Duplicate all files into tmp/assetify
    dup_assets_dir = Rails.root.join("tmp", "assetify")
    duplicate_assets(dup_assets_dir)
    
    # Size of each file/folder, including overall
    @all_files = []
    @total_overall = calc_file_lengths(dup_assets_dir.join(asset_folder), @all_files)
    @all_files.each {|pair| pair[0].sub!(dup_assets_dir.join(asset_folder), '') }
    
    # Size of each library (not including dynamic)
    @library_sizes = {}
    asset_maps = Dir.glob(Rails.root.join("app", asset_folder, '*.dependencies.json'))
    asset_maps.each do |amap|
      map_name = /^#{Rails.root.join("app", asset_folder)}\/([^.]+)\.dependencies\.json$/.match(amap)[1]
      next if map_name == "dynamic"
      asset_data = Assetify.send(asset_library_method, map_name)
      if type == "css"
        asset_data += "\n" + Assetify.send(asset_library_method, map_name, :print)
        asset_data += "\n" + Assetify.send(asset_library_method, map_name, :ie)
      end
      asset_data_compressed = Assetify::AssetCompressor.new(asset_data).compress(:type => asset_symbol)
      @library_sizes[map_name] = asset_data_compressed.length
    end
    
    # Look at each dynamic action
    @dynamic_actions = []
    Dir.glob(Rails.root.join("app/#{asset_folder}/dynamic/*/*.#{asset_suffix}")).each do |file|
      m = file.match(/(\w+)\/(\w+)\.#{asset_suffix}/)
      next if type == "css" and (m[2].ends_with?("_print") || m[2].ends_with?("_ie"))
      asset_data = Assetify.send(asset_dynamic_method, m[1], m[2])
      if type == "css"
        asset_data += "\n" + Assetify.send(asset_dynamic_method, m[1], m[2], :print)
        asset_data += "\n" + Assetify.send(asset_dynamic_method, m[1], m[2], :ie)
      end
      asset_data_compressed = Assetify::AssetCompressor.new(asset_data).compress(:type => asset_symbol)
      @dynamic_actions << [m[1], m[2], asset_data_compressed.length]
    end
    
    # Some totals
    @library_total = @library_sizes.values.inject(0) {|sum, item| sum + item }
    @number_actions = [Dir[Rails.root.join("app/stylesheets/dynamic/*/*")].length, Dir[Rails.root.join("app/javascripts/dynamic/*/*")].length].max
    @dynamic_total = @dynamic_actions.inject(0) {|sum, item| sum + item[2] }
    @total_download = @dynamic_total + @library_total
    
    render :layout => false
  end
  
  protected
    
    def duplicate_assets(target)
      FileUtils.mkdir_p target
      FileUtils.rm_rf Dir.glob(target.join("*"))
      FileUtils.cp_r Rails.root.join("app/javascripts"), target.join("javascripts")
      FileUtils.cp_r Rails.root.join("app/stylesheets"), target.join("stylesheets")
      
      files = Dir.glob(target.join("**/*.js")).concat(Dir.glob(target.join("**/*.css")))
      files.in_groups_of(100) do |arr|
        mini_list = arr.compact.join(' ')
        `java -jar #{Assetify::AssetCompressor::COMPRESSOR_MULTI} #{mini_list}`   # TODO: make a function in AssetCompressor that compresses a list of files.
      end
    end
    
    def calc_file_lengths(dir, return_data)
      dir = Pathname.new(dir)
      total_dir_size = 0
      
      Dir.glob(dir.join("*.js")).concat(Dir.glob(dir.join("*.css"))).each do |js|
        js_file_len = File.read(js).length
        total_dir_size += js_file_len
        return_data << [js, js_file_len]
      end

      Dir.glob(dir.join("*")).each do |path|
        unless /^\./ =~ path or File.file?(path)
          dir_length = calc_file_lengths(path, return_data)
          total_dir_size += dir_length
          return_data << [path, dir_length]
        end
      end
      total_dir_size
    end
  
end
