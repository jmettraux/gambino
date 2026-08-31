# frozen_string_literal: true

#
# gambino.rb

class Gambino

  class << self

    %w[ get post put patch delete ].each do |method|

      define_method(method) do |pattern, &block|

        #self.class.routes << {
        (@routes ||= []) << {
          method:  method.upcase,
          pattern: compile(pattern),
          block:   block }
      end
    end

    def call(env)

      puts "=" * 80
      puts "=" * 80
      pp env
      puts "-" * 80
      pp @routes

      [ 200, {}, [ 'foo bar' ] ]
    end

    protected

    def compile(pattern)

      pattern
    end
  end
end

