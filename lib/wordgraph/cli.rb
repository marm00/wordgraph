# frozen_string_literal: true

require "optparse"

module Wordgraph
  class CLI
    def initialize
      @options = {}
    end

    def parse(args)
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: cli.rb [options] ARG..."
        opts.separator ""
        opts.separator "Specific options:"

        opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
          @options[:verbose] = v
        end

        opts.on("-h", "--help", "Prints this help") do
          puts opts
          puts args
          exit
        end
      end

      begin
        parser.parse!(args)
      rescue OptionParser::InvalidOption => e
        puts e.message
        puts parser
        exit 1
      end

      @options
    end
  end
end
