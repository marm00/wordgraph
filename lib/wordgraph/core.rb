require_relative "mathwg"
require_relative "ttfmetrics"

module Wordgraph
  class Core
    def initialize(files, verbose: false, output_directory: Dir.pwd, name: "wordgraph", 
                    overwrite: false, seed: nil, nlargest: nil, font: "", ttc: 0)
      @files = files
      @verbose = verbose
      @output_directory = output_directory
      @name = name
      @overwrite = overwrite
      @seed = seed
      @nlargest = nlargest
      @max_size = 20
      @min_font_size = 12;
      @max_font_size = 48;
      @font = font
      @ttc = ttc
      @metrics = TTFMetrics.new(@font, @ttc)
      @font_name = @metrics.font_name # e.g. Iosevka Bold
      @font_family = @metrics.font_family # e.g. Iosevka
      if @verbose
        puts "Proceeding with settings:"
        self.instance_variables.each do |var|
          puts "#{var}: #{self.instance_variable_get(var) || false}"
        end  
      end
    end

    def tokenize(word)
      # Lowercase
      word = word.downcase
      # Strip trailing punctuation at word start
      word = word.sub(/^[\.,;:!?'"`(\[\{<]+/, "")
      # Strip trailing punctuation at word end
      word = word.sub(/[\.,;:!?'"`)\]\}>]+$/, "")
    end

    def calculate_sizes(tokens)
      # https://en.wikipedia.org/wiki/Tag_cloud
      raise ArgumentError, "Empty tokens map" unless tokens.length > 0
      # Linear normalization
      # TODO: logarithmic function for larger texts
      tokens = tokens.sort_by { |_, v| -v }.yield_self { |t| @nlargest ? t.take(@nlargest) : t }.to_h
      min_count = tokens.values.min
      max_count = tokens.values.max
      max_sub_min = [max_count - min_count, 1].max
      tokens.each do |token, count|
        size = count <= min_count ? 
          1 : 
          [((@max_size * (count - min_count)) / max_sub_min).ceil, 1].max
        fs = Mathwg::remap(1, @max_size, @min_font_size, @max_font_size, size).floor
        tokens[token] = {
          count: count,
          size: size,
          fs: fs
        }
      end
      tokens
    end

    def get_path
      raise ArgumentError, "Output directory: #{@output_directory} not found" unless Dir.exist?(@output_directory)
      file_name = File.basename(@name) + ".html"
      out = File.join(@output_directory, file_name)
      puts "Creating file: #{out}"
      continue_exists = @overwrite || !File.exist?(out)
      raise ArgumentError, "Output file already exists, either overwrite or change the name" unless continue_exists
      out
    end

    def get_font_face
      locals = [@font_name, @font_family, @font_family.split.first].uniq.map do |s|
        "\n\tlocal(\"#{s}\")"
      end
      # Appending url (download source) just in case, probably futile for ttc
      "#{locals.join(',')},\n\turl(\"#{@font}\")"
    end

    def write_html_simple(tokens)
      out = self.get_path
      File.open(out, File::RDWR | File::CREAT) do |f|
        f.flock(File::LOCK_EX)
        f.truncate(0)
        document_setup = <<~HTML
          <!DOCTYPE html>
          <html lang="en">
          <head>
              <meta charset="UTF-8">
              <meta name="viewport" content="width=device-width, initial-scale=1.0">
              <title>wordgraph</title>
          </head>
          <body>
            #{tokens.to_a.shuffle(random: Random.new(*@seed)).map { |k, v|
              fs = Mathwg::remap(1, @max_size, @min_font_size, @max_font_size, v[:size]).floor
              title = "#{v[:count].to_s} occurrence#{(v[:count] > 1 ) ? "s" : ""}"
              <<~HTML.strip
                <span
                    title='#{title}'
                    style='font-size: #{fs}px;'
                    aria-role='listitem'
                    aria-label='#{title}'>#{k}</span>
              HTML
            }.join("\n\s\s")}
          </body>
          <style>
            @font-face {
              font-family: "#{@font_family}";
              src: #{get_font_face};
            }
            body {
              display: flex;
              flex-wrap: wrap;
              gap: 8px;
              justify-content: center;
              background-color: #000;
              color: #FFFFFF;
              line-height: 1.6;
              margin: 0;
              padding: 20px;
              font-family: "#{@font_family}";
            }
            span {
              display: inline-block;
              margin: 2px 6px;
              padding: 4px 12px;
              border-radius: 4px;
            }
          </style>
          </html>
        HTML
        f.write(document_setup)
      end
      puts File.read(out) if @verbose
    end


    def rmagick_metrics(tokens)
      glyph = Magick::Draw.new
      glyph.font = @font_n
      glyph.fill = 'white'
      glyph.stroke = ''
      tokens.each do |token, v|
        fs = Mathwg::remap(1, @max_size, @min_font_size, @max_font_size, v[:size]).floor
        glyph.pointsize = fs
        # Every token with the same pointsize will share the same height glyph,
        # regardless of the letters/glyphs present in their strings.
        # E.g. a group of fs=1 will uniformly have a height of 16.0 with font=times.
        # This property is useful for placement; word frequency = height.
        # Note that for width this is not the case, even if the font is monospace.
        # E.g. a group of fs=1 and length=5 has a width of (35|36) with font=courier.
        # TODO: if using this function, this is slow, look into caching or TTFunk
        metrics = glyph.get_type_metrics(token)
        puts "#{metrics[:width]} #{metrics[:height]} #{v[:size]} #{token.length}"
      end
    end

    def spiral_pack(tokens)
      tokens.each do |token, v|
        @metrics.measure_token(token, v[:fs], v[:count]) 
      end
    end

    def process_lines(lines)
      count = {}
      count.default = 0
      lines.each do |line|
        line.split do |word|
          tokenized = self.tokenize(word)
          count[tokenized] += 1
        end
      end
      begin
        puts count if @verbose
        tokens = self.calculate_sizes(count)
        if false
          return self.write_html_simple(tokens)
        end
        self.spiral_pack(tokens)
      rescue ArgumentError => e
        raise e
      else
        puts "Succesfully finished processing" if @verbose
      end
      count
    end

    def process_text(file)
      puts "Processing txt file #{file}" if @verbose
      lines = IO.readlines(file)
      self.process_lines(lines)
    end

    def process_docx(file)
      require "zip"
      puts "Processing docx file #{file}" if @verbose
      binary = File.open(file, 'rb') { |f| f.read }
      Zip::File.open_buffer(binary) do |zip|
        doc = zip.find { |entry| entry.name == 'word/document.xml'}
        text = doc.get_input_stream.read
        # TODO: check if styling is supported
        lines = text.scan(/(?<=<w:t>).+?(?=<\/w:t>)/)
        return self.process_lines(lines)
      end
    end

    def process
      Array(@files).each do |f|
        case f
        when /\.(txt|text)\z/i
          return self.process_text(f)
        when /\.docx\z/i
          return self.process_docx(f)
        else
          raise ArgumentError, "File type not supported."
        end
      end
    end
  end
end