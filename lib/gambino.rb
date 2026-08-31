# frozen_string_literal: true

#
# gambino.rb

class Gambino

  class << self

    %w[ get post put patch delete ].each do |method|

      define_method(method) do |pattern, &block|

        (@routes ||= []) << [ method.upcase, compile(pattern), block ]
      end
    end

    def call(env)

      puts "#" * 80
      puts env
        .filter { |k, v|
          k.is_a?(String) &&
          k.match?(/\A[A-Z_]+\Z/) &&
          ! k.match?(/\A(HTTP|SERVER|REMOTE|GATEWAY)_/) }
        .map { |k, v|
          "#{k}: #{v.inspect}" }
        .join(', ')

      meth = env['REQUEST_METHOD']
      pafo = env['PATH_INFO']

      @routes.each do |method, pattern, block|

        next if meth != method
        next if ! pattern.match?(pafo)

        req = Rack::Request.new(env)

        res = instance_exec(req, &block)
        res = res.is_a?(Array) ? res.map(&:to_s) : [ res.to_s ]

        # TODO Content-Type

        return [ 200, {}, res ]
      end

      [ 404, { 'Content-Type' => 'text/plain' }, [ 'Not Found' ] ]
    end

    protected

    def compile(pattern)

      pattern
    end
  end
end

