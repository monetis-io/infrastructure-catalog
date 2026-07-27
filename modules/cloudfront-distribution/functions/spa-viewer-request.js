function handler({ request }) {
  const { uri, headers, querystring } = request;
  const host = headers.host.value;

  if (!host.startsWith('www.')) {
    const query = Object.entries(querystring)
      .map(([param, { value, multiValue }]) => [param, multiValue || [{ value }]])
      .map(([param, values]) => values.map(({ value }) => (value === '' ? param : `${param}=${value}`)).join('&'))
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
