require_relative "mathwg"

module Wordgraph
  class Core
    def initialize(files, verbose: false, output_directory: Dir.pwd, name: "wordgraph", 
                    overwrite: false, seed: nil, nlargest: nil, font: "times")
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
      @font = font.downcase
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
      return word
    end

    def generate_cloud(tokens)
      # https://en.wikipedia.org/wiki/Tag_cloud
      raise ArgumentError, "Empty tokens map" unless tokens.length > 0
      # Linear normalization
      # TODO: logarithmic function for larger texts
      min_count = tokens.values.min
      max_count = tokens.values.max
      max_sub_min = [max_count - min_count, 1].max
      tokens = tokens.max_by(@nlargest) { |v| v }.to_h if @nlargest
      tokens.each do |token, count|
        size = count <= min_count ? 
          1 : 
          [((@max_size * (count - min_count)) / max_sub_min).ceil, 1].max
        tokens[token] = {
          count: count,
          size: size
        }
      end
      self.write_html(tokens)
    end

    def get_path
      raise ArgumentError, "Output directory: #{@output_directory} not found" if !Dir.exist?(@output_directory)
      file_name = File.basename(@name) + ".html"
      out = File.join(@output_directory, file_name)
      puts "Creating file: #{out}"
      stop_exists = File.exist?(out) && !@overwrite
      raise ArgumentError, "Output file already exists, either overwrite or change the name" if stop_exists
      return out
    end

    def write_html(tokens)
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
              font-family: #{@font};
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
        self.generate_cloud(count)
      rescue ArgumentError => e
        raise e
      else
        puts "Succesfully finished processing" if @verbose
      end
      return count
    end

    def process_text(file)
      puts "Processing txt file #{file}" if @verbose
      lines = IO.readlines(file)
      return self.process_lines(lines)
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