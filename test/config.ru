
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
end

run RootEndpoints

