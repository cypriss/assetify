# Include hook code here


require "assetify"
require "assetify_secretary"
require "assetify_compressor"
require "assetify_helper"
 
class ActionController::Base
  helper :assetify
end

