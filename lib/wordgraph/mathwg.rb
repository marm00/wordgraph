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

    class Rect
      attr_reader :area, :min, :max, :width, :height, :vertices

      def initialize(width, height)
        @width = width
        @height = height
        @halfWidth = width / 2
        @halfHeight = height / 2
        @area = width * height
        @min = Vector2.new
        @max = Vector2.new
        @vertices = Array.new(4) { Vector2.new }
      end
      
      def initialize_copy(other)
        super(other)
        @vertices = @vertices.map(&:dup)
        @min = @min.dup
        @max = @max.dup
      end

      def place(pos)
        @vertices[0].set(pos.x - @halfWidth, pos.y + @halfHeight) # Top-left
        @vertices[1].set(pos.x + @halfWidth, pos.y + @halfHeight) # Top-right
        @vertices[2].set(pos.x + @halfWidth, pos.y - @halfHeight) # Bottom-right
        @vertices[3].set(pos.x - @halfWidth, pos.y - @halfHeight) # Bottom-left
        @min.copy(@vertices[3])
        @max.copy(@vertices[1])
      end

      def intersects?(b)
        # Simple aabb collision check
        @max.x >= b.min.x && @min.x <= b.max.x \
        && \
        @max.y >= b.min.y && @min.y <= b.max.y
      end

      def to_s
        "Rect(#{@width}, #{@height}, #{@min}, #{@max})"
      end
    end

    class Vector2
      attr_accessor :x, :y

      def initialize(x=0, y=0)
        @x = x
        @y = y
      end

      def initialize_copy(other)
        @x = other.x
        @y = other.y
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

      def set(x, y)
        @x = x
        @y = y
        self
      end

      def copy(v)
        @x = v.x
        @y = v.y
        self
      end

      def self.north
        new(0, 1)
      end

      def self.east
        new(1, 0)
      end

      def self.south
        new(0, -1)
      end

      def self.west
        new(-1, 0)
      end

      def to_s
        "Vector2(#{@x}, #{@y})"
      end
    end
  end
end