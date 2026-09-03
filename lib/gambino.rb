# frozen_string_literal: true

#
# gambino.rb

class Gambino

  # TODO deal with HEAD

  VERSION = '1.0.0'

  NOT_FOUND = Rack::Response.new(
    'Not Found', 404, 'Content-Type' => 'text/plain'
      ).finish.freeze

  class Context

    attr_reader :env, :stage, :params

    def initialize(env, match)

      @env = env

      params =
        if (cs = match.named_captures).any?
          cs
        else
          (1..match.size - 1).inject({}) { |h, k| h[k] = match[k]; h }
        end
      query =
        Rack::Utils.parse_query(env['QUERY_STRING'])

      @params =
        query.merge(params)
          .transform_keys { |k| k.is_a?(Integer) ? k : k.to_sym }
    end

    def finish(res)

      return res.finish if res.is_a?(Rack::Response)
      return res if is_finished?(res)

      rez = response

      (res.is_a?(Array) ? res : [ res ]).each do |r|
        case r
        when Hash then rez.headers.merge!(r)
        when String then rez.write(r)
        when Integer then rez.status = r
        else rez.write(r.to_s)
        end
      end

      rez.finish
    end

    def is_finished?(x)

      x.is_a?(Array) && x.length == 3 &&
      x[0].is_a?(Integer) && x[1].is_a?(Hash)
    end

    def call(stage, block)

      @stage = stage

      self.instance_exec(&block)
    end

    protected

    def request; @req ||= Rack::Request.new(@env); end
    def response; @res ||= Rack::Response.new; end

    def session; request.session; end

    def content_type(mime, opts={})

      response.content_type = mime
    end

    def send_file(path, opts={})

      Rack::Files.new(File.dirname(path)).serving(request, path)
    end

    #def not_found; Gambino::NOT_FOUND; end

    def halt(*res)

      throw :halt, res
    end

    def etag(tag)

      t = response['ETag'] = "\"#{tag}\""

      if hinm = env['HTTP_IF_NONE_MATCH']
        halt 304 if hinm == '*' || hinm == t
      elsif him = env['HTTP_IF_MATCH']
        halt 412 if him != '*' && him != t
      end
    end

    def redirect(uri, status=302)

      uri = env['HTTP_REFERER'] if uri == :back

      response.status = status
      response['Location'] = uri

      halt response
    end
  end

  class << self

    def set(k, v); settings[k] = v; end
    def disable(k); disabled[k] = true; end

    %w[ get post put patch delete head ].each do |method|

      define_method(method) do |pattern, &block|
        routes << [ method.upcase, compile(pattern), block ]
      end
    end

    def before(pattern=nil, &block); befores << [ compile(pattern), block ]; end
    def after(pattern=nil, &block); afters << [ compile(pattern), block ]; end

    def error(kla=nil, &block); errors << [ kla, block]; end

    def call(env)

      meth = env['REQUEST_METHOD']
      pafo = env['PATH_INFO']

      routes.each do |method, pattern, block|

        next if meth != method
        m = pattern.match(pafo); next unless m

        ctx = Gambino::Context.new(env, m)

        res =
          catch :halt do
            handle_request(ctx, pafo, block)
          rescue => err
            handle_error(ctx, err)
          end

        return ctx.finish(res)
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
    def errors; @errors ||= []; end

    def settings; @settings ||= {}; end
    def disabled; @disabled ||= {}; end

    def handle_request(ctx, pafo, block)

      befores.each { |pa, bl| ctx.call(:before, bl) if pa.match?(pafo) }

      ctx.call(:method, block)

    rescue => err

      ctx.env['gambino.error'] = err

      raise err

    ensure

      afters.each { |pa, bl| ctx.call(:after, bl) if pa.match?(pafo) }
    end

    def handle_error(ctx, err)

      errors.each do |kla, block|

        return ctx.call(:error, block) if kla == nil || err.is_a?(kla)
      end

      raise err
    end
  end
end

