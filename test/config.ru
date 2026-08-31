
#
# test/config.ru

$: << 'lib'

require 'gambino'

class RootEndpoints < Gambino

  get '/' do

    'hello world'
  end

  get '/foo' do

    'foo bar'
  end
end

run RootEndpoints

