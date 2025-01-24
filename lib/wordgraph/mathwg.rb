module Wordgraph
  module Mathwg
    def self.lerp(a, b, t)
      (1 - t) * a + b * t
    end

    def self.invLerp(a, b, v)
      a == b ? 0 : (v - a).to_f / (b - a)
    end
    
    def self.remap(from_min, from_max, to_min, to_max, value)
      self.lerp(to_min, to_max, self.invLerp(from_min, from_max, value))
    end
  end
end