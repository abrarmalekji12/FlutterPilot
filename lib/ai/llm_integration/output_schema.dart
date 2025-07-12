
const Map<String, dynamic> functionBody = {
  'name': 'generateFlutterUI',
  'description': 'Generate a Flutter UI as JSON using predefined component schema for a low-code platform.',
  'strict': false,
  'parameters':widgetTreeSchema
};

const Map<String,dynamic> widgetTreeSchema= {
  'type': 'object',
  'description': 'Root widget of the UI in JSON format following custom Flutter widget schema',
  'properties': {
    'name': {'type': 'string', 'description': 'Name of the Flutter component (e.g., Scaffold, Column, Container)'},
    'props': {
      'type': 'object',
      'description': 'Flat key-value map of properties in string i.e color, fontSize etc',
      'additionalProperties': {'type': 'string'}
    },
    'child': {'\$ref': '#', 'description': 'Single child widget (if supported)'},
    'children': {
      'type': 'array',
      'items': {'\$ref': '#'},
      'description': 'Multiple children (if supported)'
    },
    'slots': {
      'type': 'object',
      'description': 'Map of named single-child or multi-child slots (keys can be dynamic)',
      'additionalProperties': {'\$ref': '#'}
    }
  },
  'required': ['name', 'props']
};