# GrowthForecast

Client library and command to operate GrowthForecast.

* http://kazeburo.github.com/GrowthForecast/ (Japanese)
* https://github.com/kazeburo/growthforecast

Features:

* Update graph value, or create/edit/delete basic graphs and complex graphs from your own code
* Check, or edit/create basic/complex graphs with YAML specs, keywords and `gfclient` command

**USE GrowthForecast v0.33 or later**

## Installation

Add this line to your application's Gemfile:

    gem 'growthforecast'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install growthforecast

## Usage

### Client Library

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
spec = GrowthForecast::Graph.new({service_name: 'example', section_name: 'test', graph_name: 'graph1', color: '#0000ff'})
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
spec = GrowthForecast::Complex.new({
  complex: true,
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

### gfclient

```
usage: gfclient SPEC_PATH TARGET_NAME [KEYWORD1 KEYWORD2 ...]
  -f, --force     create/edit graphs with spec (default: check only)

  -H, --host=HOST  set growthforecast hostname (overwrite configuration in spec)
  -P, --port=PORT  set growthforecast port number

  -u, --user=USER  set username for growthforecast basic authentication
  -p, --pass=PASS  set password

      --prefix=PREFIX  set growthforecast uri prefix

  -l, --list=PATH  set keywords list file path (keywords set per line)
                     do check/edit many times with this option
                     (ignore default keywords)
  -a, --get-all    get and cache all graph data at first (default: get incrementally)
  -g, --debug      enable debug mode

  -h, --help      show this message
```

`gfclient` checks all patterns of `TARGET_NAME` in spec yaml file's `specs -> check` section and `specs -> edit` section. Spec file examples are `example/testspec.yaml` and `example/spec.yaml`.

Minimal example is:

```yaml
config:
  host: your.gf.host.local
  port: 5125
specs:
  - name: 'example1'
    keywords:
      - 'target'
      - 'groupname'
    check:
      - name: 'metrics1'
        path: 'pageviews/${target}/total'
        color: '#1111ff'
      - name: 'metrics2'
        path: 'pageviews/${target}/bot'
        color: '#ff1111'
    edit:
      - name: 'all metrics'
        path: '${groupname}/pageviews/all'
        complex: true
        description: 'Pageviews graph (team: ${groupname}, service: ${target})'
        stack: false
        type: 'LINE2'
        data:
          - path: 'pageviews/${target}/total'
          - path: 'pageviews/${target}/bot'
            type: 'LINE1'
```

With configurations above and command line below:

```sh
 $ gfclient spec.yaml example1 myservice super_team
```

`gfclient` works with GrowthForecast at http://your.gf.host.local:5125/ like this:

1. check `pageviews/myservice/total` and `pageviews/myservice/bot` exists or not
2. check these are configured with specified configuration parameters or not
3. **check** `super_team/pageviews/all` complex graph exists or not, and is configured correctly or not
4. report result

`gfclient` do check only without options. With **-f or --force** option, graphs specified in `edit` section are created/editted.

1. check `pageviews/myservice/total` and `pageviews/myservice/bot` exists or not, and are configured correctly or not
2. **abort** when any mismatches found for `check` section specs
3. check graph specs in `edit` section
4. **create** graph if specified path is not found
5. **edit** graph if specified graph's configuration doesn't matches with spec

`name` and `path` attributes must be specified in each check/edit items, and `complex: true` must be specified for complex graph. Others are optional (missing configuration attributes are ignored for check, and specified as default value for create).

(bold item is required)

* basic graph
  * **name** (label of this spec item)
  * **path** (string like `service/section/graph`)
  * description (text)
  * mode (string: 'gauge', 'subtract' or 'both')
  * sort (number: 19-0)
  * color (string like '#0088ff')
  * type (string: 'AREA', 'LINE1' or 'LINE2') (LINE2 meas bold)
  * ulimit, llimit (number: effective range upper/lower limit)
  * stype (string: 'AREA', 'LINE1' or 'LINE2') (mode of subtract graph)
  * sulimit, llimit (number: effective range of subtract graph)
* complex graph
  * **name** (label of this spec item)
  * **path** (string like `service/section/graph`)
  * **complex** (true or false: true must be specified for complex graph)
  * description (text)
  * sort (number: 19-0)
  * sumup (true or false: display sum up value or not)
  * mode/type/stack (global options for items of `data`, and may be overwritten by mode/type/stack of each items of `data`)
  * **data** (list of basic graph in this complex graph)
    * **path** (string: path of graph like `service/section/graph`)
    * mode (string: 'gauge' or 'subtract')
    * type (string: 'AREA', 'LINE1' or 'LINE2')
    * stack (true or false)

Spec file configurations (all of these are optional, and may be overwritten by command line options):

```yaml
config:
  host: 'hostname.of.growthforecast' # default: localhost
  port: 80         # default: 5125
  prefix: '/gf'    # default: '/' (for cases if you mount GrowthForecast on subpath of web server)
  username: 'name' # username of GrowthForecast's HTTP Basic authentication (default: none)
  password: 'pass' # password (default: none)
  debug: false     # show errors in growthforecast http response or not (default: false)
  getall: false    # get and cache all graph informations before all checks
                   # (default false, but you should specify true if your gf has many graphs)
```

You can check/edit many graphs with keywords list file like `gfclient -l listfile spec.yaml targetname`:

```
# keyword1 keyword2
xx1        yy1
xx2        yy2

# blank and comments are ok (but invalid for line-end comment)
aa1   bb1
aa2   bb2
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
