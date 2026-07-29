function handler(event) {
  const request = event.request;

  const uri = request.uri;
  const headers = request.headers;
  const querystring = request.querystring;

  const host = headers.host.value;

  if (!host.endsWith('.cloudfront.net') && !host.startsWith('www.')) {
    const query = Object.entries(querystring)
      .map((entry) => {
        const key = entry[0];
        const values = entry[1].multiValue || [{ value: entry[1].value }];

        return values
          .map(item => item.value)
          .map(value => value === '' ? key : `${key}=${value}`)
          .join('&');
      })
      .join('&');

    return {
      statusCode: 301,
      statusDescription: 'Moved Permanently',
      headers: {
        location: { value: `https://www.${host}${uri}${query ? `?${query}` : ''}` },
      },
    };
  }

  const hasExtension = uri.lastIndexOf('.') > uri.lastIndexOf('/');

  if (!hasExtension) {
    request.uri = uri.endsWith('/') ? `${uri}index.html` : `${uri}/index.html`;
  }

  return request;
}
