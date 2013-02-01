class GrowthForecast::Spec
  attr_accessor :name, :path, :complex
  attr_accessor :service_name, :section_name, :graph_name

  def complex?
    @complex
  end
  
  def initialize(dic, spec_yaml, complex=false)
    @dic = dic

    @spec = spec_yaml.dup

    @name = @spec.delete('name')
    @path = @spec.delete('path')
    @complex = @spec.delete('complex') || complex
    
    @service_name, @section_name, @graph_name = replace_keywords(@path).split('/')

    unless @service_name and @section_name and @graph_name and
        not @service_name.empty? and not @section_name.empty? and not @graph_name.empty?
      raise ArgumentError, "'path' must be as service/section/graph (#{@path})"
    end
  end

  def replace_keywords(str)
    @dic.reduce(str){|r, pair| r.gsub('${' + pair[0] + '}', pair[1])}
  end

  # return [true/false, [error notifications]]
  def check(cache)
    target = cache.get(@service_name, @section_name, @graph_name)

    if target.nil?
      return false, ["target path #{@service_name}/#{@section_name}/#{@graph_name} not exists"]
    elsif self.complex? ^ target.complex?
      return false, ["complex type is not match"]
    end

    if self.complex?
      self.check_complex(cache, target)
    else
      self.check_graph(cache, target)
    end
  end

  def merge(cache, target)
    if self.complex?
      self.merge_complex(cache, target)
    else
      self.merge_graph(cache, target)
    end
  end

  GRAPH_ATTRIBUTES = [
    :description, :mode, :sort, :color, :gmode,
    :type, :ulimit, :llimit, :stype, :sulimit, :sllimit,
    :adjust, :adjustval, :unit,
  ]
  def check_graph(cache, target)
    errors = []
    GRAPH_ATTRIBUTES.each do |attr|
      next unless @spec.has_key?(attr.to_s)
      target_val = target.send(attr)
      spec_val = if (attr == :description) && @spec[attr.to_s]
                   replace_keywords(@spec[attr.to_s])
                 else
                   @spec[attr.to_s]
                 end
      unless target_val == spec_val
        errors.push("attribute #{attr} value mismatch, spec '#{spec_val}' but '#{target_val}'")
      end
    end
    return errors.empty?, errors
  end

  def merge_graph(cache, target)
    if target.nil?
      target = GrowthForecast::Graph.new({
          service_name: @service_name, section_name: @section_name, graph_name: @graph_name,
          description: '',
        })
    end
    GRAPH_ATTRIBUTES.each do |attr|
      next unless @spec.has_key?(attr.to_s)
      val = if attr == :description
              replace_keywords(@spec[attr.to_s])
            else
              @spec[attr.to_s]
            end
      target.send((attr.to_s + '=').to_sym, val)
    end
    target
  end

  COMPLEX_ATTRIBUTES = [ :description, :sort, :sumup ]
  def check_complex(cache, target)
    errors = []
    COMPLEX_ATTRIBUTES.each do |attr|
      next unless @spec.has_key?(attr.to_s)
      target_val = target.send(attr)
      spec_val = if (attr == :description) && @spec[attr.to_s]
                   replace_keywords(@spec[attr.to_s])
                 else
                   @spec[attr.to_s]
                 end
      unless target_val == spec_val
        errors.push("attribute #{attr} value mismatch, spec '#{spec_val}' but '#{target_val}'")
      end
    end

    unless @spec.has_key?('data')
      return errors.empty?, errors
    end

    # @spec has 'data'
    spec_data_tmpl = {}
    spec_data_tmpl['gmode'] = @spec['gmode'] if @spec.has_key?('gmode')
    spec_data_tmpl['stack'] = @spec['stack'] if @spec.has_key?('stack')
    spec_data_tmpl['type'] = @spec['type'] if @spec.has_key?('type')

    target_data = target.send(:data)

    @spec['data'].each_with_index do |item, index|
      specitem = spec_data_tmpl.merge(item)

      #path
      unless specitem['path']
        errors.push("data[#{index}]: path missing")
        next
      end
      replaced_path = replace_keywords(specitem['path'])
      path_element = replaced_path.split('/')
      unless path_element.size == 3
        errors.push("data[#{index}]: path is not like SERVICE/SECTION/GRAPH")
      end
      specitem_graph = cache.get(*path_element)
      unless specitem_graph
        errors.push("data[#{index}]: specified graph '#{replaced_path}' not found")
      end

      #data(sub graph) size
      unless target_data[index]
        errors.push("data[#{index}]: graph member missing")
        next
      end

      #data graph_id
      if specitem_graph.id.to_i != target_data[index].graph_id.to_i
        errors.push("data[#{index}]: mismatch, spec '#{replaced_path}'(graph id #{specitem_graph.id}) but id '#{target_data[index].graph_id}'")
      end
      #gmode, type
      if specitem.has_key?('gmode') && specitem['gmode'] != target_data[index].gmode
        errors.push("data[#{index}]: gmode mismatch, spec '#{specitem['gmode']}' but '#{target_data[index].gmode}'")
      end
      if specitem.has_key?('type') && specitem['type'] != target_data[index].type
        errors.push("data[#{index}]: type mismatch, spec '#{specitem['type']}' but '#{target_data[index].type}'")
      end
      #stack: stack of first data item is nonsense
      if index > 0 && specitem.has_key?('stack') && specitem['stack'] != target_data[index].stack
        errors.push("data[#{index}]: stack mismatch, spec '#{specitem['stack']}' but '#{target_data[index].stack}'")
      end
    end

    return errors.empty?, errors
  end

  def merge_complex(cache, target)
    if target.nil?
      target = GrowthForecast::Complex.new({
          complex: true,
          service_name: @service_name, section_name: @section_name, graph_name: @graph_name,
          description: '',
        })
    end

    COMPLEX_ATTRIBUTES.each do |attr|
      next unless @spec.has_key?(attr.to_s)

      val = if attr == :description
              replace_keywords(@spec[attr.to_s])
            else
              @spec[attr.to_s]
            end
      target.send((attr.to_s + '=').to_sym, val)
    end

    unless @spec.has_key?('data')
      return target
    end

    # @spec has 'data'
    spec_data_tmpl = {}
    spec_data_tmpl['gmode'] = @spec['gmode'] if @spec.has_key?('gmode')
    spec_data_tmpl['stack'] = @spec['stack'] if @spec.has_key?('stack')
    spec_data_tmpl['type'] = @spec['type'] if @spec.has_key?('type')

    target.data = target.data.dup

    @spec['data'].each_with_index do |item, index|
      specitem = spec_data_tmpl.merge(item)

      #path
      unless specitem['path']
        warn "data[#{index}]: path missing"
        return nil
      end
      replaced_path = replace_keywords(specitem['path'])
      path_element = replaced_path.split('/')
      unless path_element.size == 3
        warn "data[#{index}]: path '#{replaced_path}' is not like SERVICE/SECTION/GRAPH"
        return nil
      end
      specitem_graph = cache.get(*path_element)
      unless specitem_graph
        warn "data[#{index}]: path '#{replaced_path}' not found"
        return nil
      end

      #data(sub graph) size
      unless target.data[index]
        target.data[index] = GrowthForecast::Complex::Item.new({
            graph_id: specitem_graph.id,
            gmode: (specitem['gmode'] || nil), # nil: default
            stack: (specitem.has_key?('stack') ? specitem['stack'] : nil),
            type: (specitem['type'] || nil),
          })
        next
      end

      target.data[index].graph_id = specitem_graph.id if specitem_graph.id != target.data[index].graph_id
      target.data[index].gmode = specitem['gmode'] if specitem.has_key?('gmode') && specitem['gmode'] != target.data[index].gmode
      target.data[index].type  = specitem['type']  if specitem.has_key?('type') && specitem['type'] != target.data[index].type
      target.data[index].stack = specitem['stack'] if index > 0 && specitem.has_key?('stack') && specitem['stack'] != target.data[index].stack
    end

    target
  end
end
