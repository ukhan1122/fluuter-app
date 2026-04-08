String fixImageUrl(String url) {
  if (url == null || url.isEmpty) return '';
  if (url.contains('depop-backend.test')) {
    return url.replaceAll('depop-backend.test', '10.0.2.2');
  }
  if (url.contains('localhost')) {
    return url.replaceAll('localhost', '10.0.2.2');
  }
  return url;
}