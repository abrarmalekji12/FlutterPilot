//
//
// abstract class DataFile{
//  void load();
//  void save();
// }
//
//
//
// copy all the images to assets/images/ folder
//
// TODO Dependencies (add into pubspec.yaml)
// google_fonts: ^2.2.0
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main(){
 runApp(const Temp2());
}
class Temp2 extends StatefulWidget {
 const Temp2({Key? key}) : super(key: key);

 @override
 _Temp2State createState() => _Temp2State();
}

class _Temp2State extends State<Temp2> {
 static const double pd = 10;
 static const double font = 18;

 late double dw;
 late double dh;

 @override
 Widget build(BuildContext context) {
  dw = MediaQuery.of(context).size.width;
  dh = MediaQuery.of(context).size.height;

  return MaterialApp(
   title:'My App',
   theme:ThemeData(backgroundColor:Color(0xff700d06),primaryColor:Color(0xff334192),primaryColorLight:Color(0xff321c59),cardColor:Color(0xff464646),),
   themeMode:ThemeMode.light,
   home:Scaffold(
    backgroundColor:Color(0xffffffff),
    resizeToAvoidBottomInset:false,
    appBar:AppBar(
     backgroundColor:Color(0xff0000ff),
     toolbarHeight:55,

    ),body:Padding(
       padding:EdgeInsets.all(pd),
       child:Column(
        mainAxisAlignment:MainAxisAlignment.start,
        crossAxisAlignment:CrossAxisAlignment.center,
        mainAxisSize:MainAxisSize.max,
        children:[
         Row(
          mainAxisAlignment:MainAxisAlignment.start,
          crossAxisAlignment:CrossAxisAlignment.start,
          mainAxisSize:MainAxisSize.max,
          children:[
           Container(
               padding:EdgeInsets.all(6),
               width:dw/2,
               height:220,
               alignment:Alignment.center,
               decoration:BoxDecoration(color:Color(0xffffffff),borderRadius:BorderRadius.circular(15),border:Border.all(color:Color(0xffe8e8e8),width:1,),shape:BoxShape.rectangle,),
               child:Column(
                mainAxisAlignment:MainAxisAlignment.spaceBetween,
                crossAxisAlignment:CrossAxisAlignment.center,
                mainAxisSize:MainAxisSize.max,
                children:[
                 Row(
                  mainAxisAlignment:MainAxisAlignment.spaceBetween,
                  crossAxisAlignment:CrossAxisAlignment.start,
                  mainAxisSize:MainAxisSize.max,
                  children:[
                   Container(
                       padding:EdgeInsets.symmetric(horizontal:5,vertical:3,),
                       alignment:Alignment.center,
                       decoration:BoxDecoration(color:Color(0xffa1dbf5),borderRadius:BorderRadius.circular(8),shape:BoxShape.rectangle,),
                       child:Text(
                        '30%',
                        style:GoogleFonts.getFont('Roboto Slab',textStyle:TextStyle(fontSize:12,color:Color(0xff202339),fontWeight:FontWeight.w600,fontStyle:FontStyle.normal,),),
                        textAlign:TextAlign.center,
                       )
                   ),Padding(
                       padding:EdgeInsets.all(5),
                       child:Image.asset(
                        'heart.png',
                        width:15,
                        fit:BoxFit.fitWidth,
                       )
                   ),
                  ],
                 ),Expanded(
                     flex:1,
                     child:Padding(
                         padding:EdgeInsets.all(10),
                         child:Image.asset(
                          '71D9ImsvEtL._UY500_.jpg',
                          width:90,
                          fit:BoxFit.fitWidth,
                         )
                     )
                 ),Padding(
                     padding:EdgeInsets.all(4),
                     child:Text(
                      'Nike Air Max',
                      style:GoogleFonts.getFont('Roboto',textStyle:TextStyle(fontSize:12,color:Color(0xff585e90),fontWeight:FontWeight.w800,fontStyle:FontStyle.normal,),),
                      textAlign:TextAlign.left,
                     )
                 ),Padding(
                     padding:EdgeInsets.all(4),
                     child:Text(
                      '\$240.00',
                      style:GoogleFonts.getFont('Roboto',textStyle:TextStyle(fontSize:15,color:Color(0xff3e45aa),fontWeight:FontWeight.w900,fontStyle:FontStyle.normal,),),
                      textAlign:TextAlign.left,
                     )
                 ),Row(
                  mainAxisAlignment:MainAxisAlignment.center,
                  crossAxisAlignment:CrossAxisAlignment.center,
                  mainAxisSize:MainAxisSize.max,
                  children:[
                   Row(
                    mainAxisAlignment:MainAxisAlignment.spaceBetween,
                    crossAxisAlignment:CrossAxisAlignment.center,
                    mainAxisSize:MainAxisSize.max,
                    children:[
                     Padding(
                         padding:EdgeInsets.only(top:0,left:0,bottom:0,right:4,),
                         child:Image.asset(
                          'star.png',
                          width:11,
                          fit:BoxFit.fitWidth,
                         )
                     ),Padding(
                         padding:EdgeInsets.only(top:0,left:0,bottom:0,right:4,),
                         child:Image.asset(
                          'star.png',
                          width:11,
                          fit:BoxFit.fitWidth,
                         )
                     ),Padding(
                         padding:EdgeInsets.only(top:0,left:0,bottom:0,right:4,),
                         child:Image.asset(
                          'star.png',
                          width:11,
                          fit:BoxFit.fitWidth,
                         )
                     ),Padding(
                         padding:EdgeInsets.only(top:0,left:0,bottom:0,right:4,),
                         child:Image.asset(
                          'star.png',
                          width:11,
                          fit:BoxFit.fitWidth,
                         )
                     ),Padding(
                         padding:EdgeInsets.only(top:0,left:0,bottom:0,right:4,),
                         child:Image.asset(
                          'star.png',
                          width:11,
                          fit:BoxFit.fitWidth,
                         )
                     ),
                    ],
                   ),Padding(
                       padding:EdgeInsets.all(4),
                       child:Text(
                        '(4.5)',
                        style:GoogleFonts.getFont('Roboto',textStyle:TextStyle(fontSize:10,color:Color(0xffaeb0bf),fontWeight:FontWeight.w500,fontStyle:FontStyle.normal,),),
                        textAlign:TextAlign.left,
                       )
                   ),
                  ],
                 ),
                ],
               )
           ),
          ],
         ),Visibility(
             visible:true,
             child:Container(
                 padding:EdgeInsets.all(20),
                 width:dw,
                 margin:EdgeInsets.all(pd),
                 alignment:Alignment.center,
                 decoration:BoxDecoration(color:Color(0xffffffff),borderRadius:BorderRadius.circular(10),border:Border.all(color:Color(0xff3d4eaf),width:3,),shape:BoxShape.rectangle,),
                 child:Column(
                  mainAxisAlignment:MainAxisAlignment.start,
                  crossAxisAlignment:CrossAxisAlignment.start,
                  mainAxisSize:MainAxisSize.max,
                  children:[
                   Text(
                    'LoginPage',
                    style:GoogleFonts.getFont('Roboto',textStyle:TextStyle(fontSize:23,color:Color(0xff000000),fontWeight:FontWeight.w500,fontStyle:FontStyle.normal,),),
                    textAlign:TextAlign.left,
                   ),SizedBox(
                    height:10,

                   ),Text(
                    'last worked on Yeasterday',
                    style:GoogleFonts.getFont('Roboto',textStyle:TextStyle(fontSize:15,color:Color(0xff2e2e2e),fontWeight:FontWeight.w400,fontStyle:FontStyle.normal,),),
                    textAlign:TextAlign.left,
                   ),
                  ],
                 )
             )
         ),OutlinedButton(
             backgroundColor:MaterialStateProperty.all(backgroundColor:Color(0xff951208),),alignment:Alignment.center,textStyle:MaterialStateProperty.all(GoogleFonts.getFont('ABeeZee',textStyle:TextStyle(fontSize:13,color:Color(0xff000000),fontWeight:FontWeight.w400,fontStyle:FontStyle.normal,),),),side:MaterialStateProperty.all(borderSide:BorderSide.none,),
             child:Text(
              'Click this button',
              style:GoogleFonts.getFont('Roboto',textStyle:TextStyle(fontSize:13,color:Color(0xffffffff),fontWeight:FontWeight.w400,fontStyle:FontStyle.normal,),),
              textAlign:TextAlign.left,
             )
         ),IconButton(
          icon:Icon(
           Icons.close,
          ),
          iconSize:24,
          color:Color(0xff000000),
          enableFeedback:true,
          alignment:Alignment.center,
          padding:EdgeInsets.all(0),
          tooltip:'',
         ),Switch(
          value:true,
         ),SizedBox(
          width:100,
          height:100,
          child:Card(
           color:Color(0xffffffff),
           shadowColor:Color(0xffffffff),

          ),
         ),
        ],
       )
   ),floatingActionButton:FloatingActionButton(
       elevation:1,
       enableFeedback:true,
       hoverElevation:10,
       focusElevation:8,
       hoverColor:Color(0xffd61557),
       child:Text(
        '+',
        style:GoogleFonts.getFont('Roboto',textStyle:TextStyle(fontSize:27,color:Color(0xffffffff),fontWeight:FontWeight.w400,fontStyle:FontStyle.normal,),),
        textAlign:TextAlign.left,
       )
   ),
   ),
  );
 }
}







