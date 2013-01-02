require 'json'
require 'time'

class GrowthForecast::Complex
  attr_accessor :id, :service_name, :section_name, :graph_name
  attr_accessor :description, :sort, :sumup
  attr_accessor :data
  attr_accessor :number, :data, :created_at, :updated_at

  # TODO strict validations
  
  def initialize(obj)
    if obj.is_a?(String)
      obj = JSON.parse(obj)
    end

    if not obj['complex']
      raise ArgumentError, "non-complex graph is for GrowthForecast::Graph"
    end

    @id = obj['id'] ? obj['id'].to_i : nil
    @service_name = obj['service_name']
    @section_name = obj['section_name']
    @graph_name = obj['graph_name']
    @description = obj['description']
    @sort = (obj['sort'] || 19).to_i
    @sumup = obj['sumup'] ? true : false
    @data = (obj['data'] || []).map{|d| Item.new(d)}
    @number = (obj['number'] || 0).to_i
    @created_at = obj['created_at'] ? Time.strptime(obj['created_at'], GrowthForecast::TIME_FORMAT) : nil
    @updated_at = obj['updated_at'] ? Time.strptime(obj['updated_at'], GrowthForecast::TIME_FORMAT) : nil
  end

  def complex?
    true
  end

  def to_json
    {
      'complex' => true,
      'id' => @id,
      'service_name' => @service_name, 'section_name' => @section_name, 'graph_name' => @graph_name,
      'description' => @description, 'sort' => @sort, 'sumup' => @sumup,
      'data' => @data.map(&:to_hash),
      'number' => @number,
      'created_at' => @created_at.strftime(GrowthForecast::TIME_FORMAT), 'updated_at' => @updated_at.strftime(GrowthForecast::TIME_FORMAT)
    }.to_json
  end

  class Item
    attr_accessor :graph_id, :gmode, :stack, :type

    def initialize(obj)
      if obj.is_a?(String)
        obj = JSON.parse(obj)
      end
      @graph_id = obj['graph_id']
      @gmode = obj['gmode'] || 'gauge'
      @stack = (obj['stack'] || obj['stack'].nil?) ? true : false
      @type = obj['type'] || 'AREA'
    end

    def to_hash
      {'graph_id' => @graph_id, 'gmode' => @gmode, 'stack' => @stack, 'type' => @type}
    end
  end
end
