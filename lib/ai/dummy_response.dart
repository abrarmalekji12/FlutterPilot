const dummyCode =
r'''
{"name": "Scaffold", "props": {"backgroundColor": "Color(0xfff5f5f5)", "resizeToAvoidBottomInset": true}, "slots": {"body": {"name": "SingleChildScrollView", "props": {}, "slots": {"child": {"name": "Column", "props": {"mainAxisAlignment": "center", "crossAxisAlignment": "center", "mainAxisSize": "min"}, "children": [{"name": "Container", "props": {"padding": {"All": 20}, "margin": {"bottom": 20}, "width": 300}, "child": {"name": "Card", "props": {"elevation": 5, "shape": {"borderRadius": {"Circular": 10}}, "color": "Color(0xffffffff)"}, "slots": {"child": {"name": "Column", "props": {"padding": {"All": 20}}, "children": [{"name": "Text", "props": {"Text": "Login", "style": {"textStyle": {"fontSize": 24, "fontWeight": "bold", "color": "Color(0xff000000)"}}}}, {"name": "SizedBox", "props": {"height": 20}}, {"name": "TextFormField", "props": {"decoration": {"labelText": "Email", "hintText": "Enter your email", "border": {"borderRadius": {"Circular": 5}, "borderSide": {"color": "Color(0xffcccccc)", "width": 1}}, "enabledBorder": {"borderRadius": {"Circular": 5}, "borderSide": {"color": "Color(0xffcccccc)", "width": 1}}, "focusedBorder": {"borderRadius": {"Circular": 5}, "borderSide": {"color": "Color(0xff6200ea)", "width": 1}}}, "keyboardType": "emailAddress"}}, {"name": "SizedBox", "props": {"height": 10}}, {"name": "TextFormField", "props": {"decoration": {"labelText": "Password", "hintText": "Enter your password", "border": {"borderRadius": {"Circular": 5}, "borderSide": {"color": "Color(0xffcccccc)", "width": 1}}, "enabledBorder": {"borderRadius": {"Circular": 5}, "borderSide": {"color": "Color(0xffcccccc)", "width": 1}}, "focusedBorder": {"borderRadius": {"Circular": 5}, "borderSide": {"color": "Color(0xff6200ea)", "width": 1}}}, "obscureText": true, "keyboardType": "text"}}, {"name": "SizedBox", "props": {"height": 20}}, {"name": "ElevatedButton", "props": {"style": {"backgroundColor": "Color(0xff6200ea)"}, "child": {"name": "Text", "props": {"Text": "Login", "style": {"textStyle": {"color": "Color(0xffffffff)", "fontSize": 18}}}}}]}}}}]}}}}
''';
// {
//     "name": "Scaffold",
//     "props": {
//       "backgroundColor": "Color(0xffe5ddd5)"
//     },
//     "slots": {
//       "appBar": {
//         "name": "AppBar",
//         "props": {
//           "backgroundColor": "Color(0xff075e54)",
//           "titleTextStyle.textStyle.fontSize": 20,
//           "titleTextStyle.textStyle.color": "Color(0xffffffff)",
//           "titleTextStyle.textStyle.fontWeight": "bold"
//         },
//         "slots": {
//           "title": {
//             "name": "Text",
//             "props": {
//               "Text": "WhatsApp",
//               "textStyle.fontSize": 20,
//               "textStyle.color": "Color(0xffffffff)"
//             }
//           },
//           "actions": [
//             {
//               "name": "IconButton",
//               "props": {
//                 "icon": "search",
//                 "iconSize": 24,
//                 "color": "Color(0xffffffff)"
//               }
//             },
//             {
//               "name": "IconButton",
//               "props": {
//                 "icon": "more_vert",
//                 "iconSize": 24,
//                 "color": "Color(0xffffffff)"
//               }
//             }
//           ]
//         }
//       },
//       "body": {
//         "name": "Column",
//         "props": {
//           "mainAxisAlignment": "start",
//           "crossAxisAlignment": "stretch",
//          "padding": {
//                       "All": 10
//                     }
//         },
//         "children": [
//           {
//             "name": "Expanded",
//             "child": {
//               "name": "ListView",
//               "props": {
//                 "scrollDirection": "vertical",
//                 "reverse": true,
//                 "shrinkWrap": true
//               },
//               "children": [
//                 {
//                   "name": "ListTile",
//                   "props": {
//                     "contentPadding": {
//                       "All": 8
//                     },
//                     "tileColor": "Color(0xffffffff)",
//                     "shape": {
//                       "borderRadius": {
//                         "Circular": 8
//                       }
//                     }
//                   },
//                   "slots": {
//                     "title": {
//                       "name": "Text",
//                       "props": {
//                         "Text": "Hello! How are you?",
//                         "textStyle.fontSize": 16,
//                         "textStyle.color": "Color(0xff000000)"
//                       }
//                     },
//                     "subtitle": {
//                       "name": "Text",
//                       "props": {
//                         "Text": "10:30 AM",
//                         "textStyle.fontSize": 12,
//                         "textStyle.color": "Color(0xff757575)"
//                       }
//                     }
//                   }
//                 },
//                 {
//                   "name": "ListTile",
//                   "props": {
//                     "contentPadding": {
//                       "All": 8
//                     },
//                     "tileColor": "Color(0xffdcf8c6)",
//                     "shape": {
//                       "borderRadius": {
//                         "Circular": 8
//                       }
//                     }
//                   },
//                   "slots": {
//                     "title": {
//                       "name": "Text",
//                       "props": {
//                         "Text": "I'm good, thanks!",
//                         "textStyle.fontSize": 16,
//                         "textStyle.color": "Color(0xff000000)"
//                       }
//                     },
//                     "subtitle": {
//                       "name": "Text",
//                       "props": {
//                         "Text": "10:32 AM",
//                         "textStyle.fontSize": 12,
//                         "textStyle.color": "Color(0xff757575)"
//                       }
//                     }
//                   }
//                 }
//               ]
//             }
//           }
//         ]
//       }
//     }
//   }
// ''';
// '''
// {
//   "name": "Scaffold",
//   "props": {
//     "backgroundColor": "Color(0xffffffff)"
//   },
//   "childMap": {
//     "body": {
//       "name": "Column",
//       "props": {
//         "mainAxisAlignment": "center",
//         "crossAxisAlignment": "center",
//         "mainAxisSize": "max"
//       },
//       "children": [
//         {
//           "name": "Stack",
//           "props": {
//             "fit": "loose"
//           },
//           "children": [
//             {
//               "name": "CircleAvatar",
//               "props": {
//                 "radius": 50,
//                 "backgroundColor": "Color(0xffe0e0e0)"
//               },
//               "child": {
//                 "name": "Image.network",
//                 "props": {
//                   "Url": "https://images.ctfassets.net/h6goo9gw1hh6/2sNZtFAWOdP1lmQ33VwRN3/24e953b920a9cd0ff2e1d587742a2472/1-intro-photo-final.jpg?w=1200&h=992&q=70&fm=webp",
//                   "fit": "cover"
//                 }
//               }
//             },
//             {
//               "name": "Positioned",
//               "props": {
//                 "right": 0,
//                 "bottom": 0
//               },
//               "child": {
//                 "name": "IconButton",
//                 "props": {
//                   "icon": {
//                     "name": "Icon",
//                     "props": {
//                       "Icon": "edit",
//                       "size": 20,
//                       "color": "Color(0xffffffff)"
//                     },
//                     "alignment": "center"
//                   },
//                   "iconSize": 20,
//                   "color": "Color(0xff2196f3)",
//                   "style.backgroundColor": "Color(0xff2196f3)",
//                   "style.shape": {
//                     "borderRadius": {
//                       "Circular": 50
//                     }
//                   }
//                 }
//               }
//             }
//           ]
//         },
//         {
//           "name": "Text",
//           "props": {
//             "Text": "John Doe",
//             "style.textStyle.fontSize": 20,
//             "textStyle.color": "Color(0xff000000)",
//             "textAlign": "center"
//           }
//         },
//         {
//           "name": "Text",
//           "props": {
//             "Text": "john.doe@example.com",
//             "style.textStyle.fontSize": 16,
//             "textStyle.color": "Color(0xff757575)",
//             "textAlign": "center"
//           }
//         },
//         {
//           "name": "ListView",
//           "props": {
//             "shrinkWrap": true,
//             "padding": {
//               "All": 16
//             }
//           },
//           "children": [
//             {
//               "name": "ListTile",
//               "props": {
//                 "leading": {
//                   "name": "Icon",
//                   "props": {
//                     "Icon": "account_circle",
//                     "color": "Color(0xff757575)"
//                   },
//                   "alignment": "center"
//                 },
//                 "title": {
//                   "name": "Text",
//                   "props": {
//                     "Text": "Account",
//                     "style.textStyle.fontSize": 18,
//                     "textStyle.color": "Color(0xff000000)"
//                   }
//                 },
//                 "trailing": {
//                   "name": "Icon",
//                   "props": {
//                     "Icon": "arrow_forward_ios",
//                     "color": "Color(0xff757575)"
//                   },
//                   "alignment": "center"
//                 }
//               }
//             },
//             {
//               "name": "ListTile",
//               "props": {
//                 "leading": {
//                   "name": "Icon",
//                   "props": {
//                     "Icon": "notifications",
//                     "color": "Color(0xff757575)"
//                   },
//                   "alignment": "center"
//                 },
//                 "title": {
//                   "name": "Text",
//                   "props": {
//                     "Text": "Notifications",
//                     "style.textStyle.fontSize": 18,
//                     "textStyle.color": "Color(0xff000000)"
//                   }
//                 },
//                 "trailing": {
//                   "name": "Icon",
//                   "props": {
//                     "Icon": "arrow_forward_ios",
//                     "color": "Color(0xff757575)"
//                   },
//                   "alignment": "center"
//                 }
//               }
//             },
//             {
//               "name": "ListTile",
//               "props": {
//                 "leading": {
//                   "name": "Icon",
//                   "props": {
//                     "Icon": "lock",
//                     "color": "Color(0xff757575)"
//                   },
//                   "alignment": "center"
//                 },
//                 "title": {
//                   "name": "Text",
//                   "props": {
//                     "Text": "Privacy",
//                     "style.textStyle.fontSize": 18,
//                     "textStyle.color": "Color(0xff000000)"
//                   }
//                 },
//                 "trailing": {
//                   "name": "Icon",
//                   "props": {
//                     "Icon": "arrow_forward_ios",
//                     "color": "Color(0xff757575)"
//                   },
//                   "alignment": "center"
//                 }
//               }
//             },
//             {
//               "name": "ListTile",
//               "props": {
//                 "leading": {
//                   "name": "Icon",
//                   "props": {
//                     "Icon": "help",
//                     "color": "Color(0xff757575)"
//                   },
//                   "alignment": "center"
//                 },
//                 "title": {
//                   "name": "Text",
//                   "props": {
//                     "Text": "Help",
//                     "style.textStyle.fontSize": 18,
//                     "textStyle.color": "Color(0xff000000)"
//                   }
//                 },
//                 "trailing": {
//                   "name": "Icon",
//                   "props": {
//                     "Icon": "arrow_forward_ios",
//                     "color": "Color(0xff757575)"
//                   },
//                   "alignment": "center"
//                 }
//               }
//             }
//           ]
//         },
//         {
//           "name": "Container",
//           "props": {
//             "margin": {
//               "top": 16
//             },
//             "alignment": "center"
//           },
//           "child": {
//             "name": "ElevatedButton",
//             "props": {
//               "style.backgroundColor.Background-color": "Color(0xfff44336)",
//               "style.foregroundColor.Foreground-color": "Color(0xffffffff)",
//               "style.padding.Padding": {
//                 "vertical": 12,
//                 "horizontal": 24
//               }
//             },
//             "child": {
//               "name": "Text",
//               "props": {
//                 "Text": "Log Out",
//                 "style.textStyle.fontSize": 18,
//                 "textStyle.color": "Color(0xffffffff)"
//               }
//             }
//           }
//         }
//       ]
//     }
//   }
// }
// ''';