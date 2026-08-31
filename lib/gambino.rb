# frozen_string_literal: true

#
# gambino.rb

class Gambino

  PLAIN = { 'Content-Type' => 'text/plain' }.freeze
    #
  NOT_FOUND = [ 404, PLAIN, [ 'Not Found' ] ].freeze

  class Request < ::Rack::Request

    def initialize(env)
      super
      env['gambino.res'] = Rack::Response.new
    end

    def request; self; end
    def response; env['gambino.res']; end
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

        req = Gambino::Request.new(env)

        r = req.instance_exec(&block)

        return respond(req, r)
      end

      NOT_FOUND
    end

    # TODO deal with HEAD

    protected

    def compile(pattern)

      pattern
    end

    def respond(req, r)

      res = req.response

      r = [ r ] unless r.is_a?(Array)
      r.each { |rr| res.write(rr.to_s) }

      res.finish
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

