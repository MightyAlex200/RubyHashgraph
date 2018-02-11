# a0 = Event.new myHashgraph, nil, 0, :alice, "alice a0", nil, nil
# a1 = Event.new myHashgraph, nil, 1, :alice, "alice a1", a0, nil

myHashgraph = Hashgraph.new
a0 = Event.new myHashgraph, nil, 0, :a, "a0", nil, nil
b0 = Event.new myHashgraph, nil, 0, :b, "b0", nil, nil
c0 = Event.new myHashgraph, nil, 0, :c, "c0", nil, nil
d0 = Event.new myHashgraph, nil, 0, :d, "d0", nil, nil
b1 = Event.new myHashgraph, nil, 1, :b, "b1", b0, a0
a1 = Event.new myHashgraph, nil, 2, :a, "a1", a0, b1
c1 = Event.new myHashgraph, nil, 3, :c, "c1", c0, a1
d1 = Event.new myHashgraph, nil, 4, :d, "d1", d0, c1
b2 = Event.new myHashgraph, nil, 5, :b, "b2", b1, d1