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

    r = get(test_uri)

    assert r[0], 200
    assert eval(r[1]), { name: 'foo', page: '1', offset: 'none' }
  end

  test 'HEAD /foo' do

    assert head(test_uri), [ 200, '' ]
  end

  # To be on the safe side...
  #
  test 'HEAD /foo with curl' do

    r = `curl --head -v --silent http://127.0.0.1:7080#{test_uri} 2>&1`

    assert r, /\n> HEAD \/foo HTTP\/1\.1\r\n/
    assert r, /\ncontent-length: 7\r\n/
    refute r, /foo bar/
  end
end

