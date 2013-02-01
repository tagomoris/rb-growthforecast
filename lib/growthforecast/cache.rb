class GrowthForecast::Cache
  def initialize(client, tree=nil, reload=true)
    @client = client
    @tree = tree
    @reload = reload

    @graphs = []
    @complexes = []
  end

  def get(service, section, graph, force_reload=false)
    if @tree && (!force_reload)
      return @tree.fetch(service, {}).fetch(section, {})[graph]
    end

    item = check_cached_path(service, section, graph)
    if item.is_a?(GrowthForecast::Path)
      if item.complex?
        item = @client.complex(item.id)
      else
        item = @client.graph(item.id)
      end
    end
    item
  end

  def check_cached_path(service, section, graph, atfirst=true)
    list = @graphs.select{|item| item.service_name == service && item.section_name == section && item.graph_name == graph}
    unless list.empty?
      return list.first
    end

    list = @complexes.select{|item| item.service_name == service && item.section_name == section && item.graph_name == graph}
    unless list.empty?
      return list.first
    end

    if @reload && atfirst
      @graphs = @client.graphs
      @complexes = @client.complexes
      return check_cached_path(service, section, graph, false)
    end

    nil
  end
end
