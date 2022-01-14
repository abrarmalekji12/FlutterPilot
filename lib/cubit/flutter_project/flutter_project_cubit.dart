import 'package:bloc/bloc.dart';
import 'package:flutter_builder/common/logger.dart';
import 'package:flutter_builder/models/other_model.dart';
import '../component_operation/component_operation_cubit.dart';
import '../component_selection/component_selection_cubit.dart';
import '../../firestore/firestore_bridge.dart';
import '../../models/project_model.dart';
import 'package:meta/meta.dart';

part 'flutter_project_state.dart';

class FlutterProjectCubit extends Cubit<FlutterProjectState> {
  final List<FlutterProject> projects = [];

  FlutterProjectCubit() : super(FlutterProjectInitial());

  Future<void> loadFlutterProjectList() async {
    emit(FlutterProjectLoadingState());
  }

  void loadFlutterProject(final ComponentSelectionCubit componentSelectionCubit,
      final ComponentOperationCubit componentOperationCubit) async {
    emit(FlutterProjectLoadingState());
    FlutterProject? flutterProject =
        await FireBridge.loadFlutterProject(1, 'untitled1');
    if (flutterProject == null) {
      flutterProject = FlutterProject.createNewProject();
      FireBridge.saveFlutterProject(1, flutterProject);
    }
    //MaterialApp(home:Scaffold(backgroundColor:Color(0xffffffff),resizeToAvoidBottomInset:false,appBar:AppBar(backgroundColor:Color(0xff0000ff),toolbarHeight:54,title:Padding(padding:EdgeInsets.only(top:0,left:0,bottom:0,right:30,),child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,crossAxisAlignment:CrossAxisAlignment.center,mainAxisSize:MainAxisSize.max,children:[Text('OnlineTiffinService',style:GoogleFonts.getFont('ABeeZee',textStyle:TextStyle(fontSize:19,color:Color(0xffffffff),fontWeight:FontWeight.w400,fontStyle:FontStyle.normal,),),),Stack(alignment:Alignment.topRight,children:[Padding(padding:EdgeInsets.all(5)),Align(alignment:Alignment.centerRight,widthFactor:0,child:Container(padding:EdgeInsets.all(3),width:20,height:20,alignment:Alignment.center,decoration:BoxDecoration(color:Color(0xffba160a),borderRadius:BorderRadius.circular(10),),child:Text('30',style:GoogleFonts.getFont('ABeeZee',textStyle:TextStyle(fontSize:11,color:Color(0xffe8e8e8),fontWeight:FontWeight.w400,fontStyle:FontStyle.normal,),),))),],),],)),),floatingActionButton:Container(padding:EdgeInsets.all(0),width:50,height:50,alignment:Alignment.center,decoration:BoxDecoration(color:Color(0xff1e2757),borderRadius:BorderRadius.circular(25),),child:Text('+',style:GoogleFonts.getFont('ABeeZee',textStyle:TextStyle(fontSize:25,color:Color(0xffe8e8e8),fontWeight:FontWeight.w400,fontStyle:FontStyle.normal,),),)),),)

    logger('ROOT COMPP ${flutterProject.rootComponent != null} ');
    if (flutterProject.rootComponent != null) {
      flutterProject.rootComponent!.forEach((component) {
        if(component.name=='Image.asset'){
          final imgName=(component.parameters[0].value as ImageData).imagePath;
          (component.parameters[0].value as ImageData).bytes=flutterProject!.byteCache[imgName];
        logger('SETTER $imgName');
        }
      });
    }
    componentSelectionCubit.init(
        flutterProject.rootComponent!, flutterProject.rootComponent!);

    componentOperationCubit.flutterProject = flutterProject;
    emit(FlutterProjectLoadedState(flutterProject));
  }
}
