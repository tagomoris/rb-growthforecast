require 'growthforecast'
require 'growthforecast/cache'
require 'growthforecast/spec'

require 'yaml'

module GrowthForecast::Client
  def self.execute_bulk(force, spec_path, target, keywords_list, options)
    gf, cache, specs = setup(spec_path, options)
    spec = specs.select{|s| s['name'] == target}
    if spec.size != 1
      warn "#{spec.size} specs with name '#{target}'" if spec.size > 1
      warn "Spec #{target} not found" if spec.size < 1
      return 2
    end
    spec = spec.first

    keywords_list.each do |keywords|
      retval = execute_once(gf, cache, force, spec, keywords)
      if force && retval != 0
        warn "aborting batch mode."
        return retval
      end
    end
    return 0
  end

  def self.execute(force, spec_path, target, keywords, options)
    gf, cache, specs = setup(spec_path, options)
    spec = specs.select{|s| s['name'] == target}
    if spec.size != 1
      warn "#{spec.size} specs with name '#{target}'" if spec.size > 1
      warn "Spec #{target} not found" if spec.size < 1
      return 2
    end
    spec = spec.first

    execute_once(gf, cache, force, spec, keywords)
  end

  def self.execute_once(gf, cache, force, spec, keywords)
    # generate dictionary
    if spec['keywords'].size != keywords.size
      warn "Keyword mismatch, in spec: #{spec['keywords'].join('/')}"
      exit(2)
    end
    dic = Hash[[spec['keywords'], keywords].transpose]

    check_success = true
    # check [and fix] all specs
    check_target = if force
                     spec['check'] || []
                   else
                     (spec['check'] || []) + (spec['edit'] || [])
                   end
    check_target.each do |check|
      c = GrowthForecast::Spec.new(dic, check)
      result,errors = c.check(cache)
      unless result
        errors.each{|e|
          warn "#{c.name}(#{c.service_name}/#{c.section_name}/#{c.graph_name} [#{c.complex? ? 'complex' : 'graph'}]) #{e}"
        }
        check_success = false
      end
    end

    unless check_success
      warn "Some check failure exists, aborting."
      return 1
    end
    return 0 unless force

    (spec['edit'] || []).each do |edit|
      e = GrowthForecast::Spec.new(dic, edit)
      result,errors = e.check(cache)
      next if result
      
      target = cache.get(e.service_name, e.section_name, e.graph_name)
      if target
        if target.complex? ^ e.complex?
          warn "#{e.name}(#{e.service_name}/#{e.section_name}/#{e.graph_name}) complex type is not match: skip."
          next
        end
        # edit
        warn "update #{e.name}(#{e.service_name}/#{e.section_name}/#{e.graph_name})"
        target = e.merge(cache, target)
        unless target
          warn "aborting with error."
          return 1
        end
        gf.debug.edit(target)
      else
        # generate
        warn "create #{e.name}(#{e.service_name}/#{e.section_name}/#{e.graph_name})"
        target = e.merge(cache, nil)
        unless target
          warn "aborting with error."
          return 1
        end
        gf.debug.add(target)
        unless target.complex? # basic graph creation cannot handle options (except for 'color')
          target = e.merge(cache, cache.get(e.service_name, e.section_name, e.graph_name, true))
          gf.debug.edit(target)
        end
      end
    end
    return 0
  end

  def self.setup(spec_path, options)
    spec_data = nil
    begin
      spec_data = YAML.load_file(spec_path)
    rescue => e
      warn "Spec file load error: #{e.message}"
      exit(2)
    end
    specs = spec_data['specs']
    spec_config = spec_data['config']

    config = lambda{|name| options[name] || spec_config[name.to_s]}

    host = config.call(:host) || 'localhost'
    port = config.call(:port) || 5125
    prefix = config.call(:prefix)
    gf = GrowthForecast.new(host, port, prefix)

    gf.debug = true if config.call(:debug)

    gf.username = config.call(:username)
    gf.password = config.call(:password)

    tree = if config.call(:getall)
             gf.tree()
           else
             nil
           end
    cache = GrowthForecast::Cache.new(gf, tree)

    return gf, cache, specs
  end
end
