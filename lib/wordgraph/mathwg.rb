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

    class Vector2
      attr_accessor :x, :y

      def initialize(x=0, y=0)
        @x = x
        @y = y
      end

      def +(v)
        Vector2.new(@x + v.x, @y + v.y)
      end

      def -(v)
        Vector2.new(@x - v.x, @y - v.y)
      end
    
      def *(scalar)
        Vector2.new(@x * scalar, @y * scalar)
      end

      def ==(v)
        @x == v.x && @y == v.y
      end

      def clone
        Vector2.new(@x, @y)
      end

      def lenSq
        @x * @x + @y * @y
      end

      def len
        Math.sqrt(lenSq)
      end

      def norm
        length = len
        return self unless length > 0
        Vector2.new(@x / length, @y / length)
      end

      def dot(v)
        Vector2.new(@x * v.x, @y * v.y)
      end

      def setLen(length)
        self.norm*(length)        
      end

      def distToSq(v)
        dx = @x - v.x
        dy = @y - v.y
        dx * dx + dy * dy
      end

      def distTo(v)
        Math.sqrt(self.distToSq(v))
      end

      def distToMd(v)
        Math.abs(@x - v.x) + Math.abs(@y - v.y)
      end

      def lenMd
        Math.abs(@x) + Math.abs(@y)
      end

      def to_s
        "Vector2(#{@x}, #{@y})"
      end
    end
  end
end