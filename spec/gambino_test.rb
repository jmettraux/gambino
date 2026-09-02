
#
# Testing Gambino
#
# Wed Sep  2 08:16:57 JST 2026


group 'Gambino' do

  test 'simple GET' do

    r = get('/')

    assert r._response._c, 200
    assert r, 'hello world'
  end
end

