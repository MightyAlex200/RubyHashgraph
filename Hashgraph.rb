class Hashgraph
    attr_reader :population
    attr_reader :events
    attr_reader :coin_round_frequency

    def initialize
        @events = []
        @population = 0
        @coin_round_frequency = 10
    end

    def add_event!(event)
        @events = @events.push(event).uniq
        @population = @events.map { |e| e.creator }.uniq.length
    end

    def many_creators(s)
        s.map { |x| x.creator }.uniq.length > (2*population)/3.0
    end

    def rounds_decided(r)
        @events.select { |x| x.round <= r and x.witness }.all? { |x| @events.any? { |y| y.decide x } }
    end

    def round_received(x)
        counter = 1
        until rounds_decided(counter) and @events.select { |y| y.round = r and y.unique_famous }.all? { |y| y.ancestor x}
            counter += 1
        end
        counter
    end

    def time_recieved(x)
        ary = x.time + (@events.select { |y|
            y.ancestor(x) and
            @events.any? { |z|
                z.round == round_received(x) and z.unique_famous and z.self_ancestor(y)
            } and
            @events.none? { |w|
                y.self_ancestor(w) and w.ancestor(x)
            }
        })
        mid = ary.length / 2
        sorted = ary.sort
        ary.length.odd? ? sorted[mid] : 0.5 * (sorted[mid] + sorted[mid - 1])
    end
end

class Event
    attr_reader :hashgraph
    attr_reader :data
    attr_reader :time
    attr_reader :creator
    attr_reader :signature
    attr_reader :self_parent
    attr_reader :other_parent
    
    def initialize(hashgraph, data, time, creator, signature, self_parent, other_parent)
        @data = data
        @time = time
        @creator = creator
        @signature = signature
        @self_parent = self_parent
        @other_parent = other_parent
        @hashgraph = hashgraph
        hashgraph.add_event! self
        self.round
    end

    def ancestor(y)
        self == y or self_parent ? self_parent.ancestor(y) : false or other_parent ? other_parent.ancestor(y) : false
    end

    def self_ancestor(y)
        self == y or self_parent ? self_parent.self_ancestor(y) : false
    end

    def see(y)
        # this function is supposed to do more than this but it can be detected in intialize
        ancestor(y)
    end

    def strongly_see(y)
        (see y and hashgraph.many_creators hashgraph.events.select { |z| see z and z.see y })
    end

    def parent_round
        self_parent_round = self_parent ? self_parent.round : 1
        other_parent_round = other_parent ? other_parent.round : 1
        self_parent_round > other_parent_round ? self_parent_round : other_parent_round
    end

    def round_inc
        pr = parent_round
        hashgraph.many_creators hashgraph.events.select { |y| self != y and y.round == pr and strongly_see y}
    end

    def round
        if not @round
            @round = parent_round + (((self_parent or other_parent) and round_inc) ? 1 : 0)
        end
        @round
    end

    def witness
        not self_parent or round > self_parent.round
    end

    def diff(y)
        round - y.round
    end

    def votes(y, v)
        hashgraph.events.count { |z| diff(z) == 1 and z.witness and strongly_see(z) and z.vote(y) == v }
    end

    def fract_true(y)
        vt = votes y, true
        vf = votes y, false
        r = vt.fdiv(vt + vf)
        if r.nan? then 0 else r end
    end

    def decide(y)
        supermajority = (2*hashgraph.population)/3.0
        (self_parent ? self_parent.decide(y) : false) or (
            witness and
            y.witness and
            diff(y) > 1 and
            (diff(y) % hashgraph.coin_round_frequency > 0) and
            (votes(y, true) > supermajority or votes(y, false) > supermajority)
        )
    end

    def copy_vote(y)
        not witness or self_parent ? self_parent.decide(y) : false
    end

    def vote(y)
        ft = fract_true(y)
        if copy_vote y
            self_parent.vote y
        elsif diff(y) % hashgraph.coin_round_frequency == 0 and ft.between?((1/3.0), (2/3.0))
            true # MAKE THIS A COIN ROUND
        else
            ft > 0.5
        end
    end

    def famous
        hashgraph.events.any? { |y| y.decide(self) and y.vote(self) }
    end

    def unique_famous
        famous and hashgraph.events.none? { |y| self != y and y.famous and round == y.round and creator == y.creator }
    end
end