/// For web uncomment this

import 'dart:html' as html;

dynamic window = html.window;
dynamic document= html.document;

getAnchorElement({required String href}) {
  return html.AnchorElement(href: href);
}
class MySanitizer implements html.NodeTreeSanitizer {
  @override
  void sanitizeTree(html.Node node) {}
}

/// For Non-web uncomment this

// dynamic window;
// dynamic document;
// class Node{
//
// }
// class MySanitizer {
// }
// getAnchorElement({required String href}) {
// return null;
// }