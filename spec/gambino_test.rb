#
# Testing Gambino
#
# Wed Sep  2 08:16:57 JST 2026


group 'Gambino' do

  test 'GET /' do

    assert get('/'), [ 200, 'hello world' ]
  end

  test 'GET /foo' do

    assert get('/foo'), [ 200, 'foo bar' ]
  end

  test 'GET /greet/bob' do

    assert get('/greet/bob'), [ 200, 'hello bob!' ]
  end

  test 'GET /book/two' do

    assert get('/book/two'), [ 200, 'once upon a time in {1 => "two"}' ]
  end

  test 'GET /send/file' do

    assert get('/send/file'), [ 200, "Lore Ipsum SendFile is working...\n" ]
  end

  test 'GET /halt' do

    assert get('/halt'), [ 400, 'Hold My Beer' ]
  end

  test 'GET /etag' do

    r = get('/etag')

    assert r[0], 200
    assert r[1], 'The Remains of the Day'

    etag = r[1]._response._headers['etag']

    assert etag, "\"hello4b02c354c06582\""

    assert get('/etag', etag: etag), [ 304, '' ]
  end

  test 'GET /error' do

    assert get('/error'), [ 500, 'ouch: "oh the horror"' ]
  end

  test 'GET /redirect' do

    assert get('/redirect')[0], 307
  end
end

