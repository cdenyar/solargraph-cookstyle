# frozen_string_literal: true

require 'solargraph'
require 'cookstyle'
require 'stringio'

require_relative 'solargraph_cookstyle_helpers'

# Cookstyle plugin for solargraph
module Solargraph
  module Diagnostics
    # Cookstyle class
    class Cookstyle < Base
      include CookstyleHelpers

      # Conversion of RuboCop severity names to LSP constants
      SEVERITIES = {
        'refactor' => Severities::HINT,
        'convention' => Severities::INFORMATION,
        'warning' => Severities::WARNING,
        'error' => Severities::ERROR,
        'fatal' => Severities::ERROR
      }.freeze

      def diagnose(source, _api_map)
        options, paths = generate_options(source.filename, source.code)
        store = RuboCop::ConfigStore.new
        runner = RuboCop::Runner.new(options, store)
        result = redirect_stdout { runner.run(paths) }
        make_array JSON.parse(result)
      rescue RuboCop::ValidationError, RuboCop::ConfigNotFoundError => e
        raise Solargraph::DiagnosticsError,
              "Error in RuboCop configuration: #{e.message}"
      rescue JSON::ParserError
        raise Solargraph::DiagnosticsError, 'RuboCop returned invalid data'
      end

      private

      def make_array(resp)
        diagnostics = []
        resp['files'].each do |file|
          file['offenses'].each do |off|
            diagnostics.push offense_to_diagnostic(off)
          end
        end
        diagnostics
      end

      def offense_to_diagnostic(off)
        {
          range: offense_range(off).to_hash,
          severity: SEVERITIES[off['severity']],
          source: off['cop_name'],
          message: off['message'].gsub(/^#{off['cop_name']}\:/, '')
        }
      end

      def offense_range(off)
        Range.new(offense_start_position(off),
                  offense_ending_position(off))
      end

      def offense_start_position(off)
        Position.new(
          off['location']['start_line'] - 1,
          off['location']['start_column'] - 1
        )
      end

      def offense_ending_position(off)
        if off['location']['start_line'] != off['location']['last_line']
          Position.new(off['location']['start_line'], 0)
        else
          Position.new(
            off['location']['start_line'] - 1, off['location']['last_column']
          )
        end
      end
    end
  end
end

Solargraph::Diagnostics.register('cookstyle',
                                 Solargraph::Diagnostics::Cookstyle)
