require 'json'
require 'time'

class GrowthForecast::Graph
  attr_accessor :id, :service_name, :section_name, :graph_name
  attr_accessor :description, :mode, :sort, :color, :gmode
  attr_accessor :type, :ulimit, :llimit, :stype, :sulimit, :sllimit
  attr_accessor :adjust, :adjustval, :unit
  attr_accessor :number, :data, :created_at, :updated_at

  # TODO strict validations
  
  def initialize(obj)
    if obj.is_a?(String)
      obj = JSON.parse(obj)
    end

    obj.keys.each do |k|
      obj[k.to_sym] = obj.delete(k)
    end

    if obj[:complex]
      raise ArgumentError, "complex graph is for GrowthForecast::Complex"
    end

    @id = obj[:id] ? obj[:id].to_i : nil
    @service_name = obj[:service_name]
    @section_name = obj[:section_name]
    @graph_name = obj[:graph_name]
    @description = obj[:description]
    @mode = obj[:mode] || 'gauge'
    @sort = (obj[:sort] || 19).to_i
    @color = obj[:color] #TODO 'color' parameter should be specified for graph creation ... (or should handle nil properly)
    @gmode = obj[:gmode] || 'gauge'
    @type = obj[:type] || 'AREA'
    @ulimit = obj[:ulimit] || 1000000000
    @llimit = obj[:llimit] || -1000000000
    @stype = obj[:stype] || 'AREA'
    @sulimit = obj[:sulimit] || 100000
    @sllimit = obj[:sllimit] || -100000
    @adjust = obj[:adjust] || '*'
    @adjustval = (obj[:adjustval] || 1).to_i
    @unit = obj[:unit] || ''
    @number = (obj[:number] || 0).to_i
    @data = obj[:data] || []
    @created_at = obj[:created_at] ? Time.strptime(obj[:created_at], GrowthForecast::TIME_FORMAT) : nil
    @updated_at = obj[:updated_at] ? Time.strptime(obj[:updated_at], GrowthForecast::TIME_FORMAT) : nil
  end

  def complex?
    false
  end

  def to_json
    if @color.nil?
      raise RuntimeError, "cannot stringify as json without 'color' parameter"
    end

    {
      'complex' => false,
      'id' => @id,
      'service_name' => @service_name, 'section_name' => @section_name, 'graph_name' => @graph_name,
      'description' => @description, 'mode' => @mode, 'sort' => @sort, 'color' => @color, 'gmode' => @gmode,
      'type' => @type, 'ulimit' => @ulimit, 'llimit' => @llimit, 'stype' => @stype, 'sulimit' => @sulimit, 'sllimit' => @sllimit,
      'adjust' => @adjust, 'adjustval' => @adjustval, 'unit' => @unit,
      'number' => @number, 'data' => @data,
      'created_at' => @created_at.strftime(GrowthForecast::TIME_FORMAT), 'updated_at' => @updated_at.strftime(GrowthForecast::TIME_FORMAT)
    }.to_json
  end
end
