#!/usr/bin/env ruby

require 'minitest/unit'
include MiniTest::Assertions

require 'growthforecast'

gf = GrowthForecast.new

start_graphs = gf.all().size

# value update
r = gf.post('example', 'test', 'graph2', Process.pid)
g1a = gf.graph(r.id)
g1b = gf.post('example', 'test', 'graph2', 0, 'count')
assert (g1a.number == g1b.number), "if number changed, something goes wrong..."

# get graph
r = gf.graph(99999) # maybe non-existing graph id
assert r.nil?, "may be nil"

# list check
glist = gf.graphs()
assert (glist.is_a?(Array) and glist.size >= 0), "lists must be not nil"

# add graph and edit it
r = gf.add_graph('example', 'test', 'graphrb' + Process.pid.to_s + 'a', 0, '#ff0000')
g2 = gf.by_name('example', 'test', 'graphrb' + Process.pid.to_s + 'a')

assert (g2.color == '#ff0000'), "added graph color must be #ffff00"
assert (g2.type == 'AREA'), "initial type of graph may be AREA"

g2.type = 'LINE2'

r = gf.edit(g2)

g3 = gf.graph(g2.id)
assert (g3.type == 'LINE2'), "type not changed correctly #{g3.type}"

glist2 = gf.graphs()
assert (glist.size + 1 == glist2.size), "graphs not added one: #{glist.size} -> #{glist2.size}"

# add graph by spec
spec = GrowthForecast::Graph.new({
    'service_name' => 'example', 'section_name' => 'test', 'graph_name' => 'graphrb' + Process.pid.to_s + 'b',
    'color' => '#00FF00', 'mode' => 'derive',
  })
r = gf.add(spec)

assert r, "add failed with return value #{r}"

g4 = gf.by_name('example', 'test', 'graphrb' + Process.pid.to_s + 'b')
assert (g4.mode == 'derive'), "mode should be derive, but #{g4.mode}"

# complex
r = gf.complex(99999) # may be non-existing id
assert r.nil?, "may be nil"

clist = gf.complexes()
assert (clist.is_a?(Array) and clist.size >= 0), "lists must be not nil"

r = gf.add_complex('example', 'test', 'graphrb' + Process.pid.to_s + 'c', 'testing now', true, 19, 'LINE1', 'gauge', true, [g1b.id, g2.id, g4.id])

assert r, "add_complex failed with return value #{r}"
c1 = gf.by_name('example', 'test', 'graphrb' + Process.pid.to_s + 'c')
assert c1.complex?, "c1 is not complex, why?"

c2spec = gf.complex(c1) #copy of c1 instance
c2spec.graph_name = 'graphrb' + Process.pid.to_s + 'd'
c2spec.data = [
  GrowthForecast::Complex::Item.new(graph_id: g2.id),
  GrowthForecast::Complex::Item.new(graph_id: g4.id),
]

r = gf.add(c2spec)

assert r, "add failed with return value #{r}"

c2 = gf.by_name('example', 'test', 'graphrb' + Process.pid.to_s + 'd')
c2.sort = 0

r = gf.edit(c2)

c2 = gf.complex(c2)
assert (c2.sort == 0), "sort value not updated correctly"

# delete graphs
unless gf.delete(c2) && gf.delete(c1) && gf.delete(g4) && gf.delete(g2) && gf.delete(g1b)
  raise "failed to delete graphs ..."
end

end_graphs = gf.all().size
assert (start_graphs == end_graphs), "start graph nums and end graph nums mismatch: #{start_graphs} -> #{end_graphs}"

