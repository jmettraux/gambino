
#
# test/config.ru

$: << 'lib'

require 'gambino'

class RootEndpoints < Gambino

  before do
    p [ :before, '/', response.class ]
  end
  after '/foo' do
    p [ :after, '/foo', response.class ]
  end

  get '/' do

    'hello world'
  end

  get '/foo' do

    'foo bar'
  end

  get '/greet/:name' do

    "hello #{params[:name]}!"
  end

  get %r{
    /book/(one|two|three)
  }x do

    content_type 'text/plain'

    "once upon a time in #{params.inspect}"
  end

  get '/send/file' do

    send_file 'test/some.txt'
  end

  get '/halt' do

    halt 400, 'Hold My Beer'
  end

  get '/etag' do

    etag "hello4b02c354c06582"
    'The Remains of the Day'
  end

  error do

    err = env['gambino.error']

    [ 500, {}, [ "ouch: #{err.message.inspect}" ] ]
  end

  get '/error' do

    fail 'oh the horror'
  end
end

run RootEndpoints

