# GrowthForecast

Client library to operate GrowthForecast.

* http://kazeburo.github.com/GrowthForecast/ (Japanese)
* https://github.com/kazeburo/growthforecast

Update graph value, or create/edit/delete basic graphs and complex graphs.

**USE GrowthForecast v0.33 or later**

## Installation

Add this line to your application's Gemfile:

    gem 'growthforecast'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install growthforecast

## Usage

Update graph's value:

```ruby
require 'growthforecast'
gf = GrowthForecast.new('your.gf.host.name', 5125)

gf.post('servicename', 'sectionname', 'graphname', 50)
#### or post with graph mode and color
# gf.post('servicename', 'sectionname', 'graphname', 50, 'gauge', '#ff00ff')
```

Get graph list and full descripted object:

```ruby
glist = gf.graphs() #=> [] or array of GrowthForecast::Path

glist[0].id
glist[0].service_name
glist[0].section_name
glist[0].graph_name
glist[0].complex? #=> false

graph = gf.graph(glist[0].id) #=> instance of GrowthForecast::Graph

graph.id
graph.description
graph.color
graph.type
graph.number
graph.created_at #=> instance of Time

### complex
clist = gf.complexes() #=> [] or array of GrowthForecast::Path

clist[0].id
clist[0].service_name
clist[0].section_name
clist[0].graph_name
clist[0].complex? #=> true

complex = gf.complex(clist[0].id) #=> instance of GrowthForecast::Complex

complex.id
complex.description
complex.data        #=> array of GrowthForecast::Complex::Item

complex.data[1].graph_id #=> id of GrowthForecast::Graph
complex.data[1].stack    #=> boolean
complex.data[1].gmode    #=> 'gauge' or 'subtract'
complex.data[1].type     #=> 'AREA', 'LINE1' or 'LINE2'

### get data of elements of complex graph

complex.data.each do |e|
  graph = gf.graph(e.graph_id) #=> GrowthForecast::Graph
  # ...
end

### get full list of both of graph and complex

list = gf.all() #=> array of GrowthForecast::Graph and GrowthForecast::Complex

tree = gf.tree()
tree['service']['section']['name']
   #=> instance of GrowthForecast::Graph or GrowthForecast::Complex

### Or more simply, get one by path name
### (heavy operation: consider to cache result of gf.all() or gf.tree() to call multiple times)
one = gf.by_name('service', 'section', 'name')
   #=> instance of GrowthForecast::Graph or GrowthForecast::Complex
```

To edit:

```ruby
target = gf.graph(glist.first.id)

target.description = 'OK, we are now testing...'
target.color = '#000000'
target.type = 'LINE2'

result = gf.edit(target) #=> boolean: success or not

raise "Something goes wrong..." unless result

### invert complex graph element order
complex = gf.complex(clist.last.id)

complex.data.reverse!

gf.edit(complex)

### add graph into complex graph's data

item = GrowthForecast::Complex::Item.new({graph_id: g.id, stack: true, gmode: 'gauge', type: 'AREA'})
complex.data.push(item)

gf.edit(complex)

### delete graph
gf.delete(graph)   #=> if false, not deleted correctly...
gf.delete(complex)
```

To add graph, `add_graph()` and `add()` are available:

```ruby
# add_graph(service, section, graph_name, initial_value=0, color=nil, mode=nil)
## color default: nil(random)
## mode  default: nil('gauge')
gf.add_graph('example', 'test', 'graph1')

# add(spec)
## spec: instance of GrowthForecast::Graph
spec = GrowthForecast::Graph({service_name: 'example', section_name: 'test', graph_name: 'graph1', color: '#0000ff'})
gf.add(spec)
```

As same as graph, to add complex, `add_complex()` and `add()` are available:

```ruby
# add_complex(service, section, graph_name, description, sumup, sort, type, gmode, stack, data_graph_ids)
## sumup: true or false
## sort: 0-19
## type,gmode,stack: specify all options of members of data, with same value
## type: 'AREA', 'LINE1', 'LINE2'
## gmode: 'gauge', 'subtract'
## stack: true or false
gf.add_complex('example', 'test', 'summary1', 'testing...', true, 0, 'AREA', 'gauge', true, [graph1.id, graph2.id])

# add(spec)
## spec: instance of GrowthForecast::Complex
spec = GrowthForecast::Complex({
  service_name: 'example', section_name: 'test', graph_name: 'summary1',
  description: 'testing...', sumup: true,
  data: graph_id_list.map{|id| GrowthForecast::Complex::Item.new({graph_id: id, type: 'AREA', gmode: 'gauge', stack: true}) }
})
# hmm, i want not to stack last of data, and want to show by bold line.
spec.data.last.stack = false
spec.data.last.type = 'LINE2'

gf.add(spec)
```

`add()` accepts graph/complex instance already exists as template:

```ruby
# copy template complex graph
complex_spec = gf.complex(template.id)

complex_spec.graph_name = 'copy_of_template_1' # you MUST change one of service/section/graph at least
complex_spec.description = '....'

gf.add(complex_spec) # add() ignores 'id' attribute
```

### Basic Authentication

Set `username` and `password`:

```ruby
gf = GrowthForecast.new(hostname, portnum)
gf.username = 'whoami'
gf.password = 'secret'

# ...
```

## TODO

* validations of specs
* diff of 2 graph objects
* tests

## Copyright

* Copyright (c) 2013- TAGOMORI Satoshi (tagomoris)
* License
  * Apache License, Version 2.0
  * see 'LICENSE'
