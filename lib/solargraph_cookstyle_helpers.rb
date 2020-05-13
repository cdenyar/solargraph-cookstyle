# frozen_string_literal: true

# cookstyle helpers
module Solargraph
  module Diagnostics
    # Cookstyle helpers
    module CookstyleHelpers
      module_function

      def generate_options(filename, code)
        args = ['-f', 'j']
        rubocop_file = find_rubocop_file(filename)
        args.push('-c', fix_drive_letter(rubocop_file)) unless rubocop_file.nil?
        args.push filename
        base_options = RuboCop::Options.new
        options, paths = base_options.parse(args)
        options[:stdin] = code
        [options, paths]
      end

      def find_rubocop_file(filename)
        return nil unless File.exist?(filename)

        filename = File.realpath(filename)
        dir = File.dirname(filename)
        until File.dirname(dir) == dir
          here = File.join(dir, '.rubocop.yml')
          return here if File.exist?(here)

          dir = File.dirname(dir)
        end
        nil
      end

      def fix_drive_letter(path)
        return path unless path.match(/^[a-z]:/)

        path[0].upcase + path[1..-1]
      end

      def redirect_stdout
        redir = StringIO.new
        $stdout = redir
        yield if block_given?
        $stdout = STDOUT
        redir.string
      end
    end
  end
end
