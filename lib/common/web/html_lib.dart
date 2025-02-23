/// For web uncomment this

 /*//start_web

import 'dart:html' as html;

html.Window window = html.window;
html.HtmlDocument document = html.document;

getAnchorElement({required String href}) {
  return html.AnchorElement(href: href);
}

class MySanitizer implements html.NodeTreeSanitizer {
  @override
  void sanitizeTree(html.Node node) {}
}

 *///end_web

/// For Non-web uncomment this

 //start_non_web
dynamic window;
dynamic document;

class Node {}

class MySanitizer {}

getAnchorElement({required String href}) {
  return null;
}
 //end_non_web
