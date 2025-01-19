module Wordgraph
  class Core
    def initialize(files, verbose=false)
      @files = files
      @verbose = verbose
    end

    def process
      puts "Processing #{@files}" if @verbose

      @files.each do |f|
        case f
        when /\.(txt|text)\z/i
          puts "Processing txt file #{f}"
          count = {}
          count.default = 0
          IO.foreach(f) do |line|
            line.split do |word|
              count[word] += 1
            end
          end
          puts count
          puts "Succesfully finished processing"
        when /\.docx\z/i
          raise ArgumentError, "docx not supported yet."
        else
          raise ArgumentError, "File type not supported."
        end
      end
    end
  end
end