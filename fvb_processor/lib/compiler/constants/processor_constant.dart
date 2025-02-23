const Set<String> arithmeticOperators = {
  '+',
  '-',
  '*',
  '/',
  '%',
  '>',
  '<',
  '>=',
  '<=',
  '+=',
  '-=',
  '*=',
  '/=',
  '**',
  '&',
  '|',
  '^',
  '<<',
  '>>'
};
const List<String> baNullOperators = ['='];

// static final abNullOperators=['==','!='];
const capitalACodeUnit = 65, //'A'.codeUnits.first,
    smallACodeUnit = 97, //'a'.codeUnits.first,
    capitalZCodeUnit = 90, //'Z'.codeUnits.first,
    smallZCodeUnit = 122, //'z'.codeUnits.first,
    underScoreCodeUnit = 95, //'_'.codeUnits.first,
    roundBracketClose = 41, //')'.codeUnits.first,
    roundBracketOpen = 40, //'('.codeUnits.first,
    squareBracketClose = 93, //']'.codeUnits.first,
    squareBracketOpen = 91, //'['.codeUnits.first,
    curlyBracketClose = 125, //'}'.codeUnits.first,
    curlyBracketOpen = 123, //'{'.codeUnits.first,
    triangleBracketClose = 62, //'>'.codeUnits.first,
    triangleBracketOpen = 60, //'<'.codeUnits.first,
    commaCodeUnit = 44, //','.codeUnits.first;
    backslashCodeUnit = 92; //'\\'.codeUnits.first;

const Iterable<int> extendedStringFormatterOpen = [36, 123]; //'\${'.codeUnits;
const zeroCodeUnit = 48, //'0'.codeUnits.first,
    nineCodeUnit = 57, //'9'.codeUnits.first,
    dotCodeUnit = 46, //'.'.codeUnits.first,
    dollarCodeUnit = 36, //'\$'.codeUnits.first,
    singleQuoteCodeUnit = 39, //'\''.codeUnits.first,
    doubleQuoteCodeUnit = 34, //'"'.codeUnits.first,
    backQuoteCodeUnit = 96, //'`'.codeUnits.first,
    backslashNCodeUnit = 10, //'\n'.codeUnits.first
    colonCodeUnit = 58, //':'.codeUnits.first;
    semiColonCodeUnit = 59; //';'.codeUnits.first;
const plusCodeUnit = 43, //'+'.codeUnits[0]
    minusCodeUnit = 45, //'-'.codeUnits[0]
    starCodeUnit = 42, //'*'.codeUnits[0]
    forwardSlashCodeUnit = 47, //'/'.codeUnits[0]
    equalCodeUnit = 61, //'='.codeUnits[0]
    greaterThanCodeUnit = 60, //'<'.codeUnits[0]
    lessThanCodeUnit = 62, //'>'.codeUnits[0]
    empersonCodeUnit = 38, //'&'.codeUnits[0]
    approxCodeUnit = 126, //'~'.codeUnits[0]
    modeleCodeUnit = 37, //'%'.codeUnits[0]
    exclamationCodeUnit = 33, //'!'.codeUnits[0]
    questionMarkCodeUnit = 63, //'?'.codeUnits[0]
    pipeCodeUnit = 124; //'|'.codeUnits[0]
const space = '@';
const openInt = '\${';
const closeInt = '}';
const realSpaceCodeUnit = 32; // ' '.codeUnits[0];
const spaceReplacementCodeUnit = 64; //space.codeUnits[0]//'@'.codeUnits[0];

/***
 * Obtained from Dart-pad by below code

    print('A'.codeUnits.first);
    print('a'.codeUnits.first);
    print('Z'.codeUnits.first);
    print('z'.codeUnits.first);
    print('_'.codeUnits.first);
    print('?'.codeUnits.first);
    print(')'.codeUnits.first);
    print('('.codeUnits.first);
    print(']'.codeUnits.first);
    print('['.codeUnits.first);
    print('}'.codeUnits.first);
    print('{'.codeUnits.first);
    print('>'.codeUnits.first);
    print('<'.codeUnits.first);
    print(','.codeUnits.first);

    print('-----');

    print('0'.codeUnits.first);
    print('9'.codeUnits.first);
    print('.'.codeUnits.first);
    print('\''.codeUnits.first);
    print('"'.codeUnits.first);
    print(':'.codeUnits.first);


    print('------');

    print('\${'.codeUnits);
 */
