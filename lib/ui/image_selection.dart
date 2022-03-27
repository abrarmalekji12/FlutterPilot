import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../common/logger.dart';
import '../common/search_textfield.dart';
import '../constant/app_colors.dart';
import '../constant/font_style.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../common/custom_popup_menu_button.dart';
import '../cubit/component_operation/component_operation_cubit.dart';
import '../models/other_model.dart';
import 'package:shimmer/shimmer.dart';

class ImageSelectionWidget extends StatefulWidget {
  final ComponentOperationCubit componentOperationCubit;

  const ImageSelectionWidget({required this.componentOperationCubit, Key? key})
      : super(key: key);

  @override
  State<ImageSelectionWidget> createState() => _ImageSelectionWidgetState();
}

class _ImageSelectionWidgetState extends State<ImageSelectionWidget> {
  List<ImageData>? imageDataList;
  List<ImageData>? filteredImageDataList;
  final _controller = ScrollController();
  final _focusNode = FocusNode();
  final TextEditingController controller=TextEditingController();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      widget.componentOperationCubit.loadAllImages().then((imageList) {
        setState(() {
          imageDataList = imageList;
          filteredImageDataList=imageDataList;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.componentOperationCubit.state
            is! ComponentOperationLoadingState) {
          Get.back();
        }
      },
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
            width: dw(context, 60),
            height: dh(context, 70),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      ImagePicker()
                          .pickImage(
                        source: ImageSource.gallery,
                      )
                          .then((value) {
                        if (value != null) {
                          value.readAsBytes().then((bytes) {
                            logger(
                                '=== IMAGE SELECTED ${value.name}  || ${value.path}');
                            final imageData = ImageData(bytes, value.name);
                            widget.componentOperationCubit.byteCache[value.name]=bytes;
                            widget.componentOperationCubit
                                .uploadImage(imageData);
                            Get.back(result: imageData);
                          });
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      child: Text(
                        'Choose from device',
                        style: AppFontStyle.roboto(
                          17,
                          color: Colors.blueAccent,
                        ),
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blueAccent, width: 2),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: SearchTextField(
                    controller: controller,
                    hint: 'Search image..',
                    focusColor: AppColors.theme,
                    onTextChange: (text) {
                      _searchText = text.toLowerCase();
                      setState(() {
                        filteredImageDataList = imageDataList!
                            .where((element) =>
                                element.imageName!.toLowerCase().contains(_searchText))
                            .toList();
                      });
                    },
                    focusNode: _focusNode,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: BlocBuilder<ComponentOperationCubit,
                            ComponentOperationState>(
                        bloc: widget.componentOperationCubit,
                        builder: (context, state) {
                          if (state is ComponentOperationLoadingState) {
                            return Shimmer.fromColors(
                              child: GridView.builder(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 5),
                                  itemCount: 10,
                                  itemBuilder: (context, i) {
                                    return Container(
                                      color: const Color(0xfff2f2f2),
                                    );
                                  }),
                              baseColor: const Color(0xfff2f2f2),
                              highlightColor: Colors.white,
                            );
                          }
                          return GridView.builder(
                            restorationId: 'image grid builder',
                            controller: _controller,
                            key: const GlobalObjectKey('image grid'),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 5),
                            itemBuilder: (context, index) {
                              return InkWell(
                                onTap: () {

                                  widget.componentOperationCubit.byteCache[filteredImageDataList![index].imageName!]=filteredImageDataList![index].bytes!;
                                  Get.back(result: filteredImageDataList![index]);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: Card(
                                    child: Stack(
                                      children: [
                                        Center(
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.memory(
                                              filteredImageDataList![index].bytes!,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.bottomCenter,
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              filteredImageDataList![index].imageName!,
                                              overflow: TextOverflow.fade,
                                              style: AppFontStyle.roboto(13,fontWeight: FontWeight.w600,color: Colors.black),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          right: 10,
                                          top: 10,
                                          child: InkWell(
                                            child: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onTap: () {
                                              final imageData = filteredImageDataList!
                                                  .removeAt(index);
                                              widget.componentOperationCubit
                                                  .deleteImage(
                                                      imageData.imageName!);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                            itemCount: filteredImageDataList?.length ?? 0,
                          );
                        }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
