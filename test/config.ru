
#
# test/config.ru

$: << 'lib'

require 'gambino'

class RootEndpoints < Gambino

  get '/' do

    'hello world'
  end
end

run RootEndpoints

