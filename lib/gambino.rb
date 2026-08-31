# frozen_string_literal: true

#
# gambino.rb

class Gambino

  # TODO deal with HEAD
  # TODO deal with error {}

  PLAIN = { 'Content-Type' => 'text/plain' }.freeze
    #
  NOT_FOUND = [ 404, PLAIN, [ 'Not Found' ] ].freeze

  class Context

    attr_reader :env

    def initialize(env); @env = env; end

    def request; @req ||= Rack::Request.new(@env); end
    def response; @res ||= Rack::Response.new; end

    def respond(r)

      res = response

      r = [ r ] unless r.is_a?(Array)
      r.each { |rr| res.write(rr.to_s) }

      res.finish
    end
  end

  class << self

    %w[ get post put patch delete head ].each do |method|

      define_method(method) do |pattern, &block|
        routes << [ method.upcase, compile(pattern), block ]
      end
    end

    def before(pattern=nil, &block)
      befores << [ compile(pattern), block ]
    end
    def after(pattern=nil, &block)
      afters << [ compile(pattern), block ]
    end

    def call(env)

      meth = env['REQUEST_METHOD']
      pafo = env['PATH_INFO']

      put_env(env) unless pafo.start_with?('/.well-known/')

      routes.each do |method, pattern, block|

        next if meth != method
        next unless pattern.match?(pafo)

        ctx = Gambino::Context.new(env)

        befores.each { |pa, bl| ctx.instance_exec(&bl) if pa.match?(pafo) }

        r = ctx.instance_exec(&block)

        afters.each { |pa, bl| ctx.instance_exec(&bl) if pa.match?(pafo) }

        return ctx.respond(r)
      end

      NOT_FOUND
    end

    protected

    def compile(pattern)

      return '/' if pattern == nil
      pattern
    end

    def routes; (@routes ||= []); end
    def befores; (@befores ||= []); end
    def afters; (@afters ||= []); end

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

