/// For web uncomment this

// import 'dart:html' as html;
//
// html.Window window = html.window;
// html.HtmlDocument document= html.document;
//
// getAnchorElement({required String href}) {
//   return html.AnchorElement(href: href);
// }
// class MySanitizer implements html.NodeTreeSanitizer {
//   @override
//   void sanitizeTree(html.Node node) {}
// }

/// For Non-web uncomment this

dynamic window;
dynamic document;

class Node {}

class MySanitizer {}

getAnchorElement({required String href}) {
  return null;
}
