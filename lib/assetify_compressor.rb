module Assetify
  class AssetCompressor
    
    COMPRESSOR = Dir.glob(File.expand_path(File.join(File.dirname(__FILE__), "..", "bin", "yuicompressor-*-std.jar")))[0]
    COMPRESSOR_MULTI = Dir.glob(File.expand_path(File.join(File.dirname(__FILE__), "..", "bin", "yuicompressor-*-multi.jar")))[0]
    
    def initialize(data_to_compress)
      @data = data_to_compress
    end
    
    def compress(options = {})
      type = (options.delete(:type) || "js").to_s
      
      data = IO.popen("java -jar #{COMPRESSOR} --type #{type}", 'r+') do |io|
        io.write(@data)
        io.close_write
        io.read
      end
      
      data || ''
    end
  end
end