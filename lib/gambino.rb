# frozen_string_literal: true

#
# gambino.rb

class Gambino

  class Response

    def initialize(res)

      @res = res
    end

    def to_a

      [ 200, {}, @res.is_a?(Array) ? @res.map(&:to_s) : [ @res.to_s ] ]
    end

    class << self

      def not_found_a

        [ 404, { 'Content-Type' => 'text/plain' }, [ 'Not Found' ] ]
      end
    end
  end

  class << self

    %w[ get post put patch delete head ].each do |method|

      define_method(method) do |pattern, &block|

        (@routes ||= []) << [ method.upcase, compile(pattern), block ]
      end
    end

    def before(pattern=nil, &block)
      (@befores ||= []) << [ compile(pattern), block ]
    end
    def after(pattern=nil, &block)
      (@afters ||= []) << [ compile(pattern), block ]
    end

    def call(env)

      put_env(env)

      meth = env['REQUEST_METHOD']
      pafo = env['PATH_INFO']

      @routes.each do |method, pattern, block|

        next if meth != method
        next if ! pattern.match?(pafo)

        req = Rack::Request.new(env)
        def req.request; self; end

        res = req.instance_exec(&block)

        Gambino::Response.new(res).to_a
      end

      Gambino::Response.not_found_a
    end

    # TODO deal with HEAD

    protected

    def compile(pattern)

      pattern
    end

    def put_env(env)

      puts "   <<< " + env
        .filter { |k, v|
          k.is_a?(String) &&
          k.match?(/\A[A-Z_]+\Z/) &&
          ! k.match?(/\A(HTTP|SERVER|REMOTE|GATEWAY)_/) }
        .map { |k, v|
          "#{k}: #{v.inspect}" }
        .join(', ')
    end
  end
end

