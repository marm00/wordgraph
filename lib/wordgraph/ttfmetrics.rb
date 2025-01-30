require "ttfunk"
require_relative "mathwg"

module Wordgraph
  class TTFMetrics
    include Mathwg
    
    attr_reader :font_name, :font_family
    
    def initialize(path, ttc_index=0)
      raise ArgumentError, "File not found: #{path.empty? ? "[EMPTY STRING]" : path}" unless File.exist?(path)
      @file = path =~ /\.ttc\z/i ? 
        TTFunk::File.from_ttc(path, ttc_index) : 
        TTFunk::File.open(path)
      @font_name = @file.name.font_name.first
      @font_family = @file.name.font_family.first
      @hmtx = @file.horizontal_metrics
      @units_per_em = @file.header.units_per_em
      @font_height = @file.ascent - @file.descent
      @cache = Hash.new { |h, k| h[k] = {} }
    end

    def measure_token(token, font_size, occurence)
      scale = font_size.to_f / @units_per_em
      width = token.chars.sum { |c| measure_char(c, scale) }
      # Height is the same for every glyph grouped by font_size/scale (px conversion)
      height = @font_height * scale
      puts "#{token} #{occurence} #{font_size} #{width} #{height} #{width*height}"
      Rect.new(width.round, height.round)
    end

    def measure_char(char, scale)
      code = char.unpack1("U*")
      glyph = @file.cmap.unicode.first[code]
      return 0 unless glyph
      @cache[scale][glyph] ||= @hmtx.for(glyph).advance_width * scale
    end

    def get_ttc_options(path)
      raise ArgumentError, "File not ttc: #{path}" unless path =~ /\.ttc\z/i
      raise ArgumentError, "File not found: #{path}" unless File.exist?(path)
      TTFunk::Collection.open(path) do |ttc|
        puts "#{ttc.count} fonts in collection"
        ttc.each do |font|
          puts "- #{font.name.font_name.join(', ')}"
        end
      end
    end
  end
end