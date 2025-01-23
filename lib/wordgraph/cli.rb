# frozen_string_literal: true

require "optparse"
require_relative "core"

module Wordgraph
  class CLI
    def initialize
      @options = {}
    end

    def parse(args)
      parser = OptionParser.new do |opts|
        opts.banner = "E.g.: wordgraph [options] ARG..."
        opts.separator ""
        opts.separator "Specific options:"

        opts.on("-h", "--help", "Prints this help") do
          puts opts
          puts args
        end
        
        opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
          @options[:verbose] = v
        end

        opts.on("-o=STRING", "--output-directory=STRING", "Directory to output files", String) do |dir|
          # Supports /mnt/[:drive_letter]/[:directory]
          @options[:output_directory] = dir
        end

        opts.on("-n=STRING", "--name=STRING", "Output file name", String) do |name|
          @options[:name] = name
        end

        opts.on("--[no-]overwrite", "Overwrite output file") do |overwrite|
          @options[:overwrite] = overwrite
        end

        opts.on("-s=INTEGER", "--seed=INTEGER", "Deterministic word order", Integer) do |seed|
          @options[:seed] = seed
        end

        opts.on("-m=INTEGER", "--nlargest=INTEGER", "Maximum amount of words in graph", Integer) do |nlargest|
          @options[:nlargest] = nlargest
        end

        opts.on("--font=STRING", ["times", "georgia", "garamond", "arial", 
                "helvetica", "verdana", "courier", "cursive", "papyrus"], 
                "Use a web safe font", String) do |font|
          @options[:font] = font
        end
      end

      begin
        files = parser.parse!(args)
        core = Core.new(files, **@options)
        core.process
      rescue OptionParser::InvalidOption => e
        puts e.message
        puts parser
        exit 1
      rescue ArgumentError => e
        puts "Invalid argument: #{e}"
      end

      @options
    end
  end
end
