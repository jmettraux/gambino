# frozen_string_literal: true

#
# gambino.rb

class Gambino

  # TODO deal with HEAD
  # TODO deal with error {}

  VERSION = '1.0.0'

  NOT_FOUND = Rack::Response.new(
    'Not Found', 404, 'Content-Type' => 'text/plain'
      ).finish.freeze

  class Context

    attr_reader :env, :stage, :params

    def initialize(env, match)

      @env = env

      cs = match.named_captures; if cs.any?
        @params = match.named_captures
        @params.entries.each { |k, v| @params[k.to_s.to_sym] = v }
      else
        @params = (1..match.size - 1).inject({}) { |h, k| h[k] = match[k]; h }
      end
    end

    def respond(r)

      return r.finish if r.is_a?(Rack::Response)
      return r if is_rack_response_array?(r)

      res = response

      r = [ r ] unless r.is_a?(Array)
      r.each { |rr| res.write(rr.to_s) }

      res.finish
    end

    def call(stage, block); @stage = stage; self.instance_exec(&block); end

    protected

    def request; @req ||= Rack::Request.new(@env); end
    def response; @res ||= Rack::Response.new; end

    def content_type(mime, opts={})

      response.content_type = mime
    end

    def send_file(path, opts={})

      st, hs, bo = Rack::Files.new(File.dirname(path)).serving(request, path)

      Rack::Response.new(bo, st, hs)
    end

    def not_found; Gambino::NOT_FOUND; end

    def is_rack_response_array?(r)

      return false unless r.is_a?(Array) && r.length == 3
      return false unless r[0].is_a?(Integer) && r[1].is_a?(Hash)
      return false unless r[2].is_a?(Array) || r[2].is_a?(Rack::Files::Iterator)
      true
    end

    def halt(status, body='', headers={})

      throw :halt, Rack::Response.new(body, status, headers)
    end

    def etag(tag)

      t = response['ETag'] = "\"#{tag}\""

      if hinm = env['HTTP_IF_NONE_MATCH']
        halt 304 if hinm == '*' || hinm == t
      elsif him = env['HTTP_IF_MATCH']
        halt 412 if him != '*' && him != t
      end
    end
  end

  class << self

    def set(k, v) # TODO

      settings[k] = v
    end

    def disable(k) # TODO

      disabled[k] = true
    end

    %w[ get post put patch delete head ].each do |method|

      define_method(method) do |pattern, &block|
        routes << [ method.upcase, compile(pattern), block ]
      end
    end

    def before(pattern=nil, &block); befores << [ compile(pattern), block ]; end
    def after(pattern=nil, &block); afters << [ compile(pattern), block ]; end

    def call(env)

      meth = env['REQUEST_METHOD']
      pafo = env['PATH_INFO']

      put_env(env) unless pafo.start_with?('/.well-known/')

      routes.each do |method, pattern, block|

        next if meth != method
        m = pattern.match(pafo); next unless m

        ctx = Gambino::Context.new(env, m)

        res =
          catch :halt do

            befores.each { |pa, bl| ctx.call(:before, bl) if pa.match?(pafo) }
            r = ctx.call(:method, block)
            afters.each { |pa, bl| ctx.call(:after, bl) if pa.match?(pafo) }

            r
          end

        return ctx.respond(res)
      end

      NOT_FOUND
    end

    protected

    def compile(pat)

      case pat
      when nil then compile_str('/')
      when String then compile_str(pat)
      when Regexp then compile_rex(pat)
      else fail ArgumentError.new("not a pattern #{pat.inspect}"); end
    end

    def compile_rex(pat)

      Regexp.new("\\A#{ pat.source.strip }\\z")
    end

    def compile_str(pat)

      Regexp.new("\\A#{ pat.gsub(/:(\w+)/, '(?<\1>[^/]+)') }\\z")
    end

    def routes; @routes ||= []; end
    def befores; @befores ||= []; end
    def afters; @afters ||= []; end

    def settings; @settings ||= []; end
    def disabled; @disabled ||= []; end

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

