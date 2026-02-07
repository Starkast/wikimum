// Extract bare URLs from content (URLs not already in markdown link format)
function extractBareUrls(content) {
  var urlPattern = /https?:\/\/[^\s)\]<>"]+/g;
  var allUrls = [];
  var match;
  while ((match = urlPattern.exec(content)) !== null) {
    // Strip trailing punctuation that's unlikely to be part of the URL
    var url = match[0].replace(/[.,;:!?]+$/, '');
    if (url && allUrls.indexOf(url) === -1) {
      allUrls.push(url);
    }
  }

  var result = [];
  for (var i = 0; i < allUrls.length; i++) {
    var url = allUrls[i];
    var escapedUrl = url.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    var barePattern = new RegExp('(?<!\\]\\()' + escapedUrl);
    if (barePattern.test(content)) {
      result.push(url);
    }
  }
  return result;
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = { extractBareUrls: extractBareUrls };
}
