require 'json'
require_relative './graph'
require_relative './complex'

class GrowthForecast::Path
  attr_accessor :id, :service_name, :section_name, :graph_name
  attr_accessor :complex

  PATH_KEYS = [:id,:service_name,:section_name,:graph_name,:complex]
  def self.path?(obj)
    if obj.is_a?(String)
      obj = JSON.parse(obj)
    end
    keys = obj.keys.size
    if keys >= 4 && keys <= 5 && obj.keys.map(&:to_sym).reduce(true){|r,k| r && PATH_KEYS.include?(k)}
      return true
    end
    false
  end

  def initialize(obj)
    if obj.is_a?(String)
      obj = JSON.parse(obj)
    end
    obj.keys.each do |k|
      obj[k.to_sym] = obj.delete(k)
    end

    @id = obj[:id].to_i
    @service_name = obj[:service_name]
    @section_name = obj[:section_name]
    @graph_name = obj[:graph_name]
    @complex = obj[:complex] ? true : false
  end

  def complex?
    @complex
  end

  def to_json
    {
      'id' => @id, 'complex' => @complex,
      'service_name' => @service_name, 'section_name' => @section_name, 'graph_name' => @graph_name,
    }.to_json
  end

  def to_graph
    if @complex
      GrowthForecast::Complex.new({
          complex: true, id: @id, service_name: @service_name, section_name: @section_name, graph_name: @graph_name
        })
    else
      GrowthForecast::Graph.new({
          complex: false, id: @id, service_name: @service_name, section_name: @section_name, graph_name: @graph_name
        })
    end
  end
end
