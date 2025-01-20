module Wordgraph
  class Core
    def initialize(files, verbose=false)
      @files = files
      @verbose = verbose
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
      puts "Succesfully finished processing" if @verbose
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