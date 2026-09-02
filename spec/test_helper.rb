
#
# spec/test_helpers.rb

require 'scorn'


class Probatio::Context

  BASE_URI = 'http://127.0.0.1:7080'

  def get(path)

    Scorn.get(File.join(BASE_URI, path))
  end
end

