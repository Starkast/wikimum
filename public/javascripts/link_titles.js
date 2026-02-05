// Extract bare URLs from content (URLs not already in markdown link format)
function extractBareUrls(content) {
  var urlPattern = /https?:\/\/[^\s)\]<>"]+/g;
  var allUrls = [];
  var match;
  while ((match = urlPattern.exec(content)) !== null) {
    if (allUrls.indexOf(match[0]) === -1) {
      allUrls.push(match[0]);
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
