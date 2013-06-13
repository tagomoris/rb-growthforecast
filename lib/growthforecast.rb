require "growthforecast/version"

class GrowthForecast
  TIME_FORMAT = '%Y/%m/%d %H:%M:%S'
end

require "growthforecast/graph"
require "growthforecast/complex"
require "growthforecast/path"

require 'net/http'
require 'uri'
require 'json'

class GrowthForecast
  attr_accessor :host, :port, :prefix, :timeout, :debug
  attr_accessor :username, :password

  def initialize(host='localhost', port=5125, prefix=nil, timeout=30, debug=false, username=nil, password=nil)
    @host = host
    @port = port.to_i
    @prefix = if prefix && (prefix =~ /^\//) then prefix
              elsif prefix then '/' + prefix
              else '/'
              end
    @prefix.chop! if @prefix =~ /\/$/
    @timeout = timeout.to_i
    @debug = debug ? true : false

    @username = username
    @password = password
  end

  def debug(mode=nil)
    if mode.nil?
      return GrowthForecast.new(@host,@port,@prefix,@timeout,true,@username,@password)
    end
    @mode = mode ? true : false
    self
  end

  def post(service, section, name, value, mode=nil, color=nil)
    form = {'number' => value}
    form.update({'mode' => mode}) if mode
    form.update({'color' => color}) if color
    content = URI.encode_www_form(form)

    request('POST', "/api/#{service}/#{section}/#{name}", {}, content)
  end

  def by_name(service, section, name)
    ((self.tree()[service] || {})[section] || {})[name]
  end

  def graph(id)
    if id.respond_to?(:complex?) && (not id.complex?) # accept graph object itself to reload
      id = id.id
    end
    request('GET', "/json/graph/#{id}")
  end

  def complex(id)
    if id.respond_to?(:complex?) && id.complex? # accept complex object itself to reload
      id = id.id
    end
    request('GET', "/json/complex/#{id}")
  end

  def graphs
    request('GET', "/json/list/graph", {}, '', true)
  end

  def complexes
    list = request('GET', "/json/list/complex", {}, '', true)
    return nil if list.nil?
    list.each do |path|
      path.complex = true
    end
    list
  end

  def all
    request('GET', "/json/list/all", {}, '', true)
  end

  def tree
    list = self.all()
    return {} if list.nil?

    root = {}
    list.each do |i|
      root[i.service_name] ||= {}
      root[i.service_name][i.section_name] ||= {}
      root[i.service_name][i.section_name][i.graph_name] = i
    end
    root
  end

  def edit(spec)
    if spec.id.nil?
      raise ArgumentError, "cannot edit graph without id (get graph data from GrowthForecast at first)"
    end
    path = if spec.complex?
             "/json/edit/complex/#{spec.id}"
           else
             "/json/edit/graph/#{spec.id}"
           end
    request('POST', path, {}, spec.to_json)
  end

  def delete(spec)
    if spec.id.nil?
      raise ArgumentError, "cannot delete graph without id (get graph data from GrowthForecast at first)"
    end
    path = if spec.complex?
             "/delete_complex/#{spec.id}"
           else
             "/delete/#{spec.service_name}/#{spec.section_name}/#{spec.graph_name}"
           end
    request('POST', path)
  end

  ADDITIONAL_PARAMS = ['description' 'sort' 'gmode' 'ulimit' 'llimit' 'sulimit' 'sllimit' 'type' 'stype' 'adjust' 'adjustval' 'unit']
  def add(spec)
    unless spec.respond_to?(:complex?)
      raise ArgumentError, "parameter of add() must be instance of GrowthForecast::Graph or GrowthForecast::Complex (or use add_graph/add_complex)"
    end
    if spec.complex?
      add_complex_spec(spec)
    else
      add_graph(spec.service_name, spec.section_name, spec.graph_name, spec.number, spec.color, spec.mode)
    end
  end

  def add_graph(service, section, graph_name, initial_value=0, color=nil, mode=nil)
    if service.empty? || section.empty? || graph_name.empty?
      raise ArgumentError, "service, section and graph_name must be specified"
    end
    if (not color.nil?)
      unless color =~ /^#[0-9a-fA-F]{6}/
        raise ArgumentError, "color must be specified like #FFFFFF"
      end
    end
    post(service, section, graph_name, initial_value, mode, color) and true # 'add' and 'add_graph' returns boolean not graph object
  end

  def add_complex(service, section, graph_name, description, sumup, sort, type, gmode, stack, data_graph_ids)
    unless data_graph_ids.is_a?(Array) && data_graph_ids.size > 0
      raise ArgumentError, "To create complex graph, specify 1 or more sub graph ids"
    end
    unless sort >= 0 and sort <= 19
      raise ArgumentError, "sort must be 0..19"
    end
    unless type == 'AREA' || type == 'LINE1' || type == 'LINE2'
      raise ArgumentError, "type must be one of AREA/LINE1/LINE2"
    end
    unless gmode == 'gauge' || gmode == 'subtract'
      raise ArgumentError, "gmode must be one of gauge/subtract"
    end
    spec = GrowthForecast::Complex.new({
        complex: true,
        service_name: service, section_name: section, graph_name: graph_name,
        description: description, sumup: sumup, sort: sort,
        data: data_graph_ids.map{|id| {'graph_id' => id, 'type' => type, 'gmode' => gmode, 'stack' => stack} }
      })
    add_complex_spec(spec)
  end

  private

  def add_complex_spec(spec)
    request('POST', "/json/create/complex", {}, spec.to_json)
  end

  def concrete(obj)
    case
    when obj.nil?
      nil
    when obj.is_a?(TrueClass) || obj.is_a?(FalseClass)
      obj
    when obj.is_a?(Array)
      obj.map{|e| concrete(e)}
    when Path.path?(obj)
      Path.new(obj)
    when obj['complex']
      Complex.new(obj)
    else
      Graph.new(obj)
    end
  end

  def request(method, path, header={}, content='', getlist=false)
    concrete(http_request(method, path, header, content, getlist))
  end

  def http_request(method, path, header={}, content=nil, getlist=false)
    conn = Net::HTTP.new(@host, @port)
    conn.open_timeout = conn.read_timeout = @timeout
    request_path = @prefix + path
    req = case method
          when 'GET'
            Net::HTTP::Get.new(request_path, header)
          when 'POST'
            Net::HTTP::Post.new(request_path, header)
          else
            raise ArgumentError, "Invalid HTTP method for GrowthForecast: '#{method}'"
          end
    if content
      req.body = content
    end
    if @username || @password
      req.basic_auth(@username, @password)
    end
    res = conn.request(req)

    unless res.is_a?(Net::HTTPSuccess)
      return [] if getlist and res.code == '404'

      # GrowthForecast returns 200 for validation and other errors. hmm...
      if @debug
        warn "GrowthForecast returns response code #{res.code}"
        warn " request (#{method}) http://#{host}:#{port}#{request_path}"
        warn " with content #{content}"
      end
      return nil
    end
    # code 200
    return true if res.body.length < 1

    obj = begin
            JSON.parse(res.body)
          rescue JSON::ParserError => e
            warn "failed to parse response content as json, with error: #{e.message}"
            nil
          end
    return nil unless obj

    if obj.is_a?(Array) # get valid list
      return obj
    end

    # hash obj
    if obj.has_key?('error') && obj['error'] != 0
      warn "request ended with error:"
      (obj['messages'] || {}).each do |key,msg|
        warn "  #{key}: #{msg}"
      end
      warn "  request (#{method}) http://#{host}:#{port}#{request_path}"
      warn "  with content #{res.body}"
      nil
    elsif obj.has_key?('error') && obj.has_key?('data') # valid response, without any errors
      obj['data']
    else  # bare growthforecast object
      obj
    end
  end
end
