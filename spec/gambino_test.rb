#
# Testing Gambino
#
# Wed Sep  2 08:16:57 JST 2026


group 'Gambino' do

  test 'GET /' do

    assert get(test_uri), [ 200, 'hello world' ]
  end

  test 'GET /foo' do

    assert get(test_uri), [ 200, 'foo bar' ]
  end

  test 'GET /greet/bob' do

    assert get(test_uri), [ 200, 'hello bob!' ]
  end

  test 'GET /book/two' do

    assert get(test_uri), [ 200, 'once upon a time in {1 => "two"}' ]
  end

  test 'GET /send/file' do

    assert get(test_uri), [ 200, "Lore Ipsum SendFile is working...\n" ]
  end

  test 'GET /halt' do

    assert get(test_uri), [ 400, 'Hold My Beer' ]
  end

  test 'GET /etag' do

    r = get(test_uri)

    assert r[0], 200
    assert r[1], 'The Remains of the Day'

    etag = r[1]._response._headers['etag']

    assert etag, "\"hello4b02c354c06582\""

    assert get(test_uri, etag: etag), [ 304, '' ]
  end

  test 'GET /error' do

    assert get(test_uri), [ 500, 'ouch: "oh the horror"' ]
  end

  test 'GET /redirect' do

    assert get(test_uri)[0], 307
  end


  test 'GET /query/foo?page=1&offset=none' do

    p __test_name
    p test_uri
    #get '/query/foo?page=1&offset=none'
  end
end

