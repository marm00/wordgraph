module Wordgraph
  class Core
    def initialize(files, verbose: false, output_directory: Dir.pwd, name: "wordgraph", overwrite: false, seed: nil)
      @files = files
      @verbose = verbose
      @output_directory = output_directory
      @name = name
      @overwrite = overwrite
      @seed = seed
      @max_fontsize = 20
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

    def get_path
      out_dir = @output_directory || Dir.pwd
      raise ArgumentError, "Output directory: #{@out_dir} not found" if !Dir.exist?(out_dir)
      out_file = File.basename(@name || "wordgraph") + ".html"
      out = File.join(out_dir, out_file)
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
            #{tokens.to_a.shuffle(random: Random.new(*@seed)).map { |k, v| \
                "<span title='" + v[:count].to_s + " occurrence" + ((v[:count] > 1 ) ? "s" : "") \
                  +  "' style=\"" + "font-size: " + (v[:size] + 8).to_s + "px;\">" \
                  + k + \
                "</span>"} \
              .join("\n\s\s")}
          </body>
          <style>
            body {
              background-color: #000;
              color: #FFFFFF;
              text-align: center;
              line-height: 2;
              margin: 0;
            }
            span {
              margin: 4px;
              padding: 4px 8px;
              display: inline-block;
            }
          </style>
          </html>
        HTML
        f.write(document_setup)
      end
      puts File.read(out) if @verbose
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