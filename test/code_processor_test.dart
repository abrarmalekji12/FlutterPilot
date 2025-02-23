import 'package:flutter_test/flutter_test.dart';
import 'package:fvb_processor/compiler/code_processor.dart';

void main() {
  late Processor processor;
  setUpAll(() {
    processor = Processor(
        scopeName: 'test',
        consoleCallback: (value, {List<dynamic>? arguments}) {
          return null;
        },
        onError: (error, line) {
          print('ERROR ${error} at $line');
        });
  });

  group('Test FVB Compiler', () {
    test('Math operation check', () {
      expect(processor.process('23-20', config: const ProcessorConfig()), 3);
      expect(processor.process('20%3', config: const ProcessorConfig()), 2);
      expect(processor.process('-10+2', config: const ProcessorConfig()), -8);
      expect(processor.process('-(-10+2)', config: const ProcessorConfig()), 8);
      expect(
          processor.process('-(-10+2)%3', config: const ProcessorConfig()), 2);
      expect(processor.process('-(-10+2)*3', config: const ProcessorConfig()),
          -(-10 + 2) * 3);
      expect(processor.process('-10+2*3', config: const ProcessorConfig()),
          -10 + 2 * 3);
      expect(processor.process('-10/2*3', config: const ProcessorConfig()),
          -10 / 2 * 3);
      expect(processor.process('10/2%3', config: const ProcessorConfig()),
          10 / 2 % 3);
      expect(
          processor.process('10==10', config: const ProcessorConfig()), true);
    });
    group('Functions Check', () {
      test('Simple Functions', () {
        processor.executeCode('''
        String sum(double a, double b){
        return 'sum : \${a+b}';
        }
        ''', declarativeOnly: true);
        expect(processor.process('sum(10,20)', config: const ProcessorConfig()),
            'sum : 30');
      });
      test('Lambda Functions', () {
        processor.executeCode('''
        String sum(double a, double b) => 'sum : \${a+b}';
        ''', declarativeOnly: true);
        expect(processor.process('sum(10,20)', config: const ProcessorConfig()),
            'sum : 30');
      });
      test('Argument Types Test', () {
        processor.executeCode('''
        int sum(int a, int b,[int? c]) => a + b + (c!=null?c:0); 
        ''');
        expect(processor.process('sum(10,20)', config: const ProcessorConfig()),
            30);
        expect(
            processor.process('sum(10,20,5)', config: const ProcessorConfig()),
            35);
      });
    });

    test('Variables Check', () {
      processor.executeCode('''
      var a=10;
      String str="test_string";
      ''', declarativeOnly: true);
      expect(processor.process('a+10', config: const ProcessorConfig()), 20);
      expect(processor.process('str+"_abc"', config: const ProcessorConfig()),
          'test_string_abc');
    });
    group('OOPs Check', () {
      test('Class', () {
        processor.executeCode('''
        class Student{
        String play(int a){
        return 'playing \$a';
        }
        }
        ''', declarativeOnly: true);
        expect(
            processor.process('Student().play(10)',
                config: const ProcessorConfig()),
            'playing 10');
      });
      test('Class Constructor', () {
        processor.executeCode('''
        class Student{
        final int roll;
        final String name;
        Student(this.roll,this.name);
        }
        ''', declarativeOnly: true);
        expect(
            processor.process('Student(10,"Abrar").name',
                config: const ProcessorConfig()),
            'Abrar');
      });

      test('Class with toString', () {
        Processor.error = false;
        processor.executeCode('''
        class Student{
        final int roll;
        final String name;
        Student(this.roll,this.name);
        
        String toString()=>'name: \$name, roll: \$roll';
        }
        ''', declarativeOnly: true);
        expect(
            processor.process('"\${Student(10,"Abrar")}"',
                config: const ProcessorConfig()),
            'name: Abrar, roll: 10');
      });
    });
  });
}
