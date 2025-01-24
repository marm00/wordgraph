module Wordgraph
  module Mathwg
    def lerp(a, b, t)
      (1 - t) * a + b * t
    end

    def invLerp(a, b, v)
      a === b ? 0 : (v - a).to_f / (b - a)
    end
    
    def remap(from_min, from_max, to_min, to_max, value)
      lerp(to_min, to_max, invLerp(from_min, from_max, value))
    end
  end
end