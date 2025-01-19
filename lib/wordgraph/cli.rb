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

        opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
          @options[:verbose] = v
        end

        opts.on("-h", "--help", "Prints this help") do
          puts opts
          puts args
        end
      end

      begin
        files = parser.parse!(args)
        core = Core.new(files, @options[:verbose])
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
