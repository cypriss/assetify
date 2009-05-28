module Assetify
  class AssetSecretary

    def initialize(map, options = {})
      @map_file_path = map
      @root_dir = File.dirname(@map_file_path)
      @file_type = (options.delete(:type) || :js).to_s

      reset!
    end

    def reset!
      @json_maps = []
      @orig_json_map = load_dependency_map(@map_file_path)

      # Create @dependency_map: A processed up version of the basic json map with cross references.
      @dependency_map = include_nested_maps(@orig_json_map, @root_dir)
      symbolize_specials(@dependency_map)
      calculate_leaf_nodes(@dependency_map)
      add_backlinks(@dependency_map, nil)
      push_dependencies(@dependency_map)
      expand_dependencies(@dependency_map)

      # Create a simpler representation of the dependency map
      @file_map = {}
      flatten_dependencies(@dependency_map, @file_map)

      @mtime = max_modified_time
      
      @concatenations = {}
    end

    def something_changed?(controller = nil, action = nil)
      previous_mtime, @mtime = @mtime, max_modified_time
      if controller and action
        cont_file = File.join(@root_dir, dynamic_controller_file_name(controller))
        act_file = File.join(@root_dir, dynamic_action_file_name(controller, action))
        cont_act_mtime = [cont_file, act_file].collect do |fname|
          File.exist?(fname) ? File.mtime(fname) : nil
        end
        cont_act_mtime << @mtime
        @mtime = cont_act_mtime.compact.max
      end
      previous_mtime != @mtime
    end

    def full_concatenation(kind = :standard)
      reset! if something_changed?

      @concatenations["::full::#{kind}"] ||= concatenate(topological_sort(@file_map), kind)
    end

    def concatenation_for_view(controller, action, kind = :standard)
      reset! if something_changed?(controller, action)
      
      @concatenations["#{controller}:#{action}:#{kind}"] ||= begin
        @included = []
        
        cont_file = dynamic_controller_file_name(controller)
        act_file = dynamic_action_file_name(controller, action)
        
        include_file_and_dependencies(cont_file) if @file_map[cont_file]
        include_file_and_dependencies(act_file) if @file_map[act_file]
        
        unless @file_map[cont_file]
          @included << cont_file if File.exist?(File.join(@root_dir, cont_file))
        end
        
        unless @file_map[act_file]
          @included << act_file if File.exist?(File.join(@root_dir, act_file))
        end
        
        concatenate(@included, kind)
      end
    end

    protected #-----------------------------------------------------------------------------
    
    def dynamic_controller_file_name(controller)
      File.join("dynamic", "#{controller}.#{@file_type}")
    end
    
    def dynamic_action_file_name(controller, action)
      File.join("dynamic", controller, "#{action}.#{@file_type}")
    end

    def concatenate(included_files, kind)
      file_without_extension_matcher = Regexp.new("^(.+)\.#{@file_type}$")
      kind = kind.to_s
      
      data = included_files.collect do |path|
        if kind == "standard"
          path_with_kind = path
        else
          path_with_kind = path.match(file_without_extension_matcher)[1] + "_#{kind}.#{@file_type}"
        end
        
        fname = File.join(@root_dir, path_with_kind)
        File.exist?(fname) ? File.read(fname) : ""
      end

      data.join("\n\n").strip
    end
    
    # NOTE: this doesn't take into account subtypes (print/ie).  I know this.
    # It would be easy to fix, but I suspect iterating over all CSS files 3 more times isn't worth the cost (performance-wise), especially with large file sets.
    def max_modified_time
      mtime_sources = @file_map.keys.collect do |file|
        full_path = File.join(@root_dir, file)
        File.exist?(full_path) ? File.mtime(full_path) : Time.now
      end

      mtime_json = @json_maps.collect do |file|
        File.exist?(file) ? File.mtime(file) : Time.now
      end

      [mtime_sources.max, mtime_json.max].compact.max
    end
    
    def load_dependency_map(path)
      map = ActiveSupport::JSON.decode(File.read(path))
      @json_maps << path
      map
    rescue Errno::ENOENT => file_error
      raise "Could not open/read the dependency file #{path}. error = #{file_error.inspect}"
    rescue ActiveSupport::JSON::ParseError => parse_error
      raise "Could not parse the JSON in the dependency file #{path}. error = #{parse_error.inspect}"
    end

    # NOTE: Most of these functions require arguments passed into them b/c they are recursive.
    # (as opposed to using @dependency_map directly, for instance)

    # Does the string represent a file?
    def is_file?(str)
      !(str =~ Regexp.new("\.#{@file_type}$")).nil?
    end

    # Does the string represent a json map?
    def is_json_map?(str)
      !(str =~ /\.json$/).nil?
    end

    # Loops through the hash's resources (string keys, representing folders and files) and calls yield for each of them.
    def each_resource(obj)
      obj.each_pair do |item, props|
        yield(item, props) unless Symbol === item
      end
    end

    # Expand nested dependencies.json files
    def include_nested_maps(obj, cur_path)
      json_files = []

      each_resource(obj) do |item, props|
        if is_json_map?(item)
          json_files << item
        end
      end

      json_files.each do |item|
        obj.delete(item)

        more_json = load_dependency_map(File.join(cur_path, item))

        more_json.each_pair do |k, v|
          obj[k] = v
        end
      end

      each_resource(obj) do |item, props|
        if !["desc", "deps"].include?(item)
          include_nested_maps(props, File.join(cur_path, item))
        end
      end

    end

    # Converts non-resource keys to symbols
    def symbolize_specials(obj)
      desc = obj.delete("desc")
      obj[:desc] = desc unless desc.nil?

      deps = obj.delete("deps")
      obj[:deps] = deps unless deps.nil?

      each_resource(obj) do |item, props|
        symbolize_specials(props)
      end
    end

    # Figures out which nodes are leaf resources (files) and what its path is
    def calculate_leaf_nodes(obj, is_leaf = false, path = nil)
      obj[:is_leaf] = true if is_leaf
      obj[:path] = path if is_leaf

      each_resource(obj) do |item, props|

        if path.nil?
          new_path = item
        else
          new_path = "#{path}/#{item}"
        end

        calculate_leaf_nodes(props, is_file?(item), new_path)
      end
    end

    # Add a backlink (parent pointer) to each node so we can walk the tree better.
    def add_backlinks(obj, parent)
      obj[:parent] = parent

      each_resource(obj) do |item, props|
        add_backlinks(props, obj)
      end
    end

    # Remove backlinks (they're not needed after a point)
    def remove_backlinks(obj)
      obj.delete(:parent)
      each_resource(obj) do |item, props|
        remove_backlinks(props)
      end
    end

    # Move up folder dependencies to each file
    def push_dependencies(obj)

      deps = obj.delete(:deps) || []
      deps = [deps] if deps.is_a?(String)
      deps.collect! do |dep|
        "../#{dep}"
      end

      each_resource(obj) do |item, props|
        child_deps = props.delete(:deps) || []
        child_deps = [child_deps] if child_deps.is_a?(String)
        child_deps = child_deps.concat(deps)
        child_deps.uniq!

        props[:deps] = child_deps

        unless props[:is_leaf]
          push_dependencies(props)
        end
      end
    end

    # Collects all leaf nodes that this node eventually contains and returns an array of them.
    def collect_leaf_files(obj)
      deps = []

      each_resource(obj) do |item, props|
        if is_file?(item)
          deps << props
        else
          deps.concat(collect_leaf_files(props))
        end
      end

      deps
    end

    # Return an array of leaf nodes which are the dependencies of leaf given by the single string dependency dep
    def collect_real_deps(leaf, dep)
      deps = []

      if !(dep =~ /^\.\.\//).nil?
        deps = collect_real_deps(leaf[:parent], dep[3, dep.length])
      else
        dep_parts = dep.split("/")
        if dep_parts.length > 1
          first_dep = dep_parts.shift
          deps = collect_real_deps(leaf[first_dep], dep_parts.join("/"))
        else
          if is_file?(dep)
            # here we have something like dep="blah.js" and leaf should have a key "blah.js"
            deps = [leaf[dep]]
          else
            # here we have something like dep="mootools" and leaf should have a key "mootools" which is a folder
            deps = collect_leaf_files(leaf[dep])
          end
        end
      end

      deps
    end

    # Recursively convert the dependencies to real_deps, where real_deps are pointers to other leaf nodes.
    def expand_dependencies(obj)
      if obj[:is_leaf]        
        rough_deps = obj.delete(:deps)
        real_deps = []

        rough_deps.each do |dep|
          # we're considering a dep like "dbug.js" or "../../mootools" or "Browser/IframeShim.js",
          # and we need to convert that into an array of object references to other files.
          # "dbug.js" => [the dbug.js hash]
          # "../../mootools" => [for each js hash in mootools folder, the js hash]
          real_deps.concat(collect_real_deps(obj, "../#{dep}"))
        end

        obj[:real_deps] = real_deps

      else
        each_resource(obj) do |item, props|
          expand_dependencies(props)
        end
      end
    end

    # Convert our giant dependency structure into a simple hash of "file/name/path.js" => {:deps => [array of other file strings], :incomming => 0}
    # The incomming is used later to determine the order of each node in topological sort
    def flatten_dependencies(obj, files)
      each_resource(obj) do |item, props|

        if props[:is_leaf]
          edges = {:incomming => 0}
          edges[:deps] = props[:real_deps].collect do |dep|
            dep[:path]
          end
          files[props[:path]] = edges
        else
          flatten_dependencies(props, files)
        end
      end
    end

    # Do a topological sort of the flattened_dependencies and output the file list as an ordered array.
    # The order is which files can be loaded first
    def topological_sort(files)
      # Calculate the incomming edges for each node
      files.each_pair do |item, props|
        deps = props[:deps]
        deps.each do |dep|
          files[dep][:incomming] += 1
        end
      end

      sorted_nodes = []
      no_dep_nodes = []
      files.each_pair do |item, props|
        if props[:incomming] == 0
          no_dep_nodes << item
        end
      end

      while no_dep_nodes.length > 0
        n = no_dep_nodes.shift
        sorted_nodes << n

        deps = files[n][:deps]
        deps.each do |dep|
          files[dep][:incomming] -= 1
          if files[dep][:incomming] == 0
            no_dep_nodes << dep
          end
        end
      end

      raise Exception, "Circular dependency detected!" if sorted_nodes.length != files.size

      sorted_nodes.reverse
    end
    
    # Includes the file and its dependencies in @included
    # NOTE: cycles aren't detected.
    def include_file_and_dependencies(file)
      return if @included.index(file)
      
      file_obj = @file_map[file]
      raise "Could not find dependency in map." if file_obj.nil?
      deps = file_obj[:deps]
      
      deps.each do |dep|
        include_file_and_dependencies(dep)
      end
      
      @included << file
    end
    
  end
end
