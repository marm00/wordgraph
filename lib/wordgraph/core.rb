module Wordgraph
  class Core
    def initialize(files, verbose=false, output_directory = nil, name = nil, overwrite=false)
      @files = files
      @verbose = verbose
      @max_fontsize = 20
      @output_directory = output_directory
      @name = name
      @overwrite = overwrite
    end

    def tokenize(word)
      # Lowercase
      word = word.downcase
      # Strip trailing punctuation at word start
      word = word.sub(/^[\.,;:!?'"`(\[\{<]/, "")
      # Strip trailing punctuation at word end
      word = word.sub(/[\.,;:!?'"`)\]\}>]\z/, "")
      return word
    end

    def generate_cloud(tokens)
      # https://en.wikipedia.org/wiki/Tag_cloud
      raise ArgumentError, "Empty tokens map" unless tokens.length > 0
      # Linear normalization
      min_count = tokens.values.min
      max_count = tokens.values.max
      max_sub_min = [max_count - min_count, 1].max
      tokens.each do |token, count|
        size = count <= min_count ? 
                1 : 
                ((@max_fontsize * (count - min_count)) / max_sub_min).ceil 
        tokens[token] = {
          count: count,
          size: size
        }
      end
      self.write_html(tokens)
    end

    def write_html(tokens)
      out_dir = @output_directory || Dir.pwd
      raise ArgumentError, "Output directory: #{@out_dir} not found" unless Dir.exist?(out_dir)
      out_file = File.basename(@name || "graph") + ".html"
      out = File.join(out_dir, out_file)
      puts "Creating file: #{out}"
      continue_exists = @overwrite || !File.exist?(out)
      raise ArgumentError, "File already exists, either overwrite or change name" unless continue_exists
      File.open(out, File::RDWR | File::CREAT) do |f|
        f.flock(File::LOCK_EX)
        document_setup = <<~HTML
          <!DOCTYPE html>
          <html lang="en">
          <head>
              <meta charset="UTF-8">
              <meta name="viewport" content="width=device-width, initial-scale=1.0">
              <title>wordgraph</title>
          </head>
          <body>
          </body>
          </html>
        HTML
        f.write(document_setup)
      end
      puts File.read(out)
    end

    def process_text(file)
      puts "Processing txt file #{file}" if @verbose
      count = {}
      count.default = 0
      IO.foreach(file) do |line|
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

    def process
      puts "Processing #{@files}" if @verbose
      Array(@files).each do |f|
        case f
        when /\.(txt|text)\z/i
          return self.process_text(f)
        when /\.docx\z/i
          raise ArgumentError, "docx not supported yet."
        else
          raise ArgumentError, "File type not supported."
        end
      end
    end
  end
end