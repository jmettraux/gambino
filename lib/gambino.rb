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

      cs = match.named_captures; if cs.any?
        @params = match.named_captures
        @params.entries.each { |k, v| @params[k.to_s.to_sym] = v }
      else
        @params = (1..match.size - 1).inject({}) { |h, k| h[k] = match[k]; h }
      end
    end

    def finish(r)

      return r.finish if r.is_a?(Rack::Response)

      st, hs, bd = arr =
        case r
        when Array then r
        when Integer then [ r, {}, [ '' ] ]
        when String then [ 200, {}, [ r ] ]
        else [ 200, {}, [ r.to_s ] ]
        end

      if st.is_a?(Rack::Response)

        st.finish

      elsif arr.length == 3 && st.is_a?(Integer) && hs.is_a?(Hash)

        arr[2] = [ bd ] if bd.is_a?(String)
        arr

      else

        res = response
        arr.each { |e| res.write(e.to_s) }
        res.finish
      end
    end

    def call(stage, block); @stage = stage; self.instance_exec(&block); end

    protected

    def request; @req ||= Rack::Request.new(@env); end
    def response; @res ||= Rack::Response.new; end

    def content_type(mime, opts={})

      response.content_type = mime
    end

    def send_file(path, opts={})

      Rack::Files.new(File.dirname(path)).serving(request, path)
    end

    def not_found; Gambino::NOT_FOUND; end

    def halt(status, body='', headers={})

      throw :halt, [ status, headers, body ]
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

    def settings; @settings ||= []; end
    def disabled; @disabled ||= []; end

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

