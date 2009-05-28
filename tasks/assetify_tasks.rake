namespace :assetify do
  
  desc 'Compress the javascript and css in public/stylesheets and public/javascripts'
  task :compress_public => [:environment] do
    p "Compressing JS and CSS assets..."
    yui_compressor = Dir.glob(File.dirname(__FILE__) + '/../bin/yuicompressor-*-multi.jar')[0]
    js_files = Dir.glob(File.join(ActionView::Helpers::AssetTagHelper::JAVASCRIPTS_DIR, '**', '*.js'))
    css_files = Dir.glob(File.join(ActionView::Helpers::AssetTagHelper::STYLESHEETS_DIR, '**', '*.css'))
    
    unless yui_compressor.nil?
      joined_array = js_files + css_files
      joined_array.in_groups_of(100) do |arr|
        arr = arr.compact
        arr.size.times { $stdout.putc '.' }
        files_array = arr.join(' ')
        `java -jar #{yui_compressor} #{files_array}`
      end
    end
    puts "\nDone."
  end
end