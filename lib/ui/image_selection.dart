import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';

import '../common/io_lib.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../common/logger.dart';
import '../common/responsive/responsive_widget.dart';
import '../common/search_textfield.dart';
import '../constant/app_colors.dart';
import '../constant/font_style.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../common/custom_popup_menu_button.dart';
import '../cubit/component_operation/component_operation_cubit.dart';
import '../models/other_model.dart';
import 'package:shimmer/shimmer.dart';

import '../models/project_model.dart';

class ImageSelectionWidget extends StatefulWidget {
  final bool selectionEnable;
  final ComponentOperationCubit componentOperationCubit;

  const ImageSelectionWidget(
      {required this.componentOperationCubit,
      this.selectionEnable = true,
      Key? key})
      : super(key: key);

  @override
  State<ImageSelectionWidget> createState() => _ImageSelectionWidgetState();
}

class _ImageSelectionWidgetState extends State<ImageSelectionWidget> {
  static List<ImageData>? filteredImageDataList;
  final _controller = ScrollController();
  final _focusNode = FocusNode();
  final TextEditingController controller = TextEditingController();
  String _searchText = '';
  late FlutterProject project;

  @override
  void initState() {
    super.initState();
    if (widget.componentOperationCubit.imageDataList == null) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        widget.componentOperationCubit.loadAllImages().then((imageList) {
          setState(() {
            filteredImageDataList =
                widget.componentOperationCubit.imageDataList;
          });
        });
      });
    } else {
      filteredImageDataList = widget.componentOperationCubit.imageDataList;
    }
    project = widget.componentOperationCubit.project!;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.componentOperationCubit.state
            is! ComponentOperationLoadingState) {
          Navigator.pop(context);
        }
      },
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
            width: Responsive.isLargeScreen(context)
                ? dw(context, 60)
                : double.infinity,
            height: dh(context, 70),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
                            ImagePicker()
                                .pickImage(
                              source: ImageSource.gallery,
                            )
                                .then((value) {
                              if (value != null) {
                                value.readAsBytes().then((bytes) {
                                  logger(
                                      '=== IMAGE SELECTED ${value.name}  || ${value.path}');
                                  _onBytesGot(bytes, value.name);
                                });
                              }
                            });
                          } else {
                            FilePicker.platform
                                .pickFiles(
                                    withData: true,
                                    dialogTitle: 'Pick Image',
                                    type: FileType.any,
                                    allowedExtensions: [
                                      'png',
                                      'jpg',
                                      'jpeg',
                                      'gif',
                                      'bmp',
                                      'webp',
                                      'tiff',
                                      'ico',
                                      'svg'
                                    ],
                                    allowMultiple: false)
                                .then((files) {
                              if (files != null && files.files.isNotEmpty) {
                                final file = files.files.first;
                                _onBytesGot(
                                    file.bytes!, files.files.first.name);
                              }
                            });
                          }
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
                            border:
                                Border.all(color: Colors.blueAccent, width: 2),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                        onPressed: () {
                          widget.componentOperationCubit
                              .loadAllImages()
                              .then((imageList) {
                            setState(() {
                              filteredImageDataList =
                                  widget.componentOperationCubit.imageDataList;
                            });
                          });
                        },
                        icon: const Icon(Icons.refresh))
                  ],
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
                        filteredImageDataList = widget
                            .componentOperationCubit.imageDataList!
                            .where((element) => element.imageName!
                                .toLowerCase()
                                .contains(_searchText))
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
                          if (widget.componentOperationCubit.imageDataList==null) {
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
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 200),
                            itemBuilder: (context, index) {
                              return StatefulBuilder(
                                  builder: (context, setState2) {
                                return InkWell(
                                  enableFeedback: widget.selectionEnable,
                                  onTap: widget.selectionEnable
                                      ? () {
                                          widget.componentOperationCubit
                                                      .byteCache[
                                                  filteredImageDataList![index]
                                                      .imageName!] =
                                              filteredImageDataList![index]
                                                  .bytes!;
                                          if(!widget.componentOperationCubit.project!.imageList.contains(filteredImageDataList![index].imageName!)) {
                                            widget.componentOperationCubit.project!.imageList.add(filteredImageDataList![index].imageName!);
                                          }
                                          Navigator.pop(context,
                                              filteredImageDataList![index]);
                                        }
                                      : null,
                                  child: Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: Card(
                                      child: Stack(
                                        children: [
                                          Center(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: (!filteredImageDataList![
                                                          index]
                                                      .imageName!
                                                      .endsWith('.svg')
                                                  ? Image.memory(
                                                      filteredImageDataList![
                                                              index]
                                                          .bytes!,
                                                      fit: BoxFit.contain,
                                                    )
                                                  : SvgPicture.memory(
                                                      filteredImageDataList![
                                                              index]
                                                          .bytes!,
                                                      fit: BoxFit.contain,
                                                    )),
                                            ),
                                          ),
                                          Align(
                                            alignment: Alignment.topLeft,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: AppColors.theme,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              padding: const EdgeInsets.all(4),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Checkbox(
                                                    fillColor:
                                                        MaterialStateProperty
                                                            .all(Colors.white),
                                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                    checkColor: AppColors.theme,
                                                    value: project.imageList
                                                        .contains(
                                                            filteredImageDataList![
                                                                    index]
                                                                .imageName),
                                                    onChanged: (value) {
                                                      if (value != null) {
                                                        if (!value) {
                                                          project.imageList.remove(
                                                              filteredImageDataList![
                                                                      index]
                                                                  .imageName!);
                                                        } else {
                                                          project.imageList.add(
                                                              filteredImageDataList![
                                                                      index]
                                                                  .imageName!);
                                                        }
                                                        widget.componentOperationCubit.updateProjectConfig('image_list', project.imageList);
                                                        setState2(() {});
                                                      }
                                                    },
                                                    visualDensity:
                                                        const VisualDensity(
                                                            horizontal: -4,
                                                            vertical: -4),
                                                  ),
                                                  const SizedBox(
                                                    width: 5,
                                                  ),
                                                  Text(
                                                    'Add',
                                                    style: AppFontStyle.roboto(
                                                        13,
                                                        color: Colors.white),
                                                  )
                                                ],
                                              ),
                                            ),
                                          ),
                                          Align(
                                            alignment: Alignment.bottomCenter,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.2)),
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: InkWell(
                                                onTap: () {
                                                  Clipboard.setData(ClipboardData(
                                                      text:
                                                          filteredImageDataList![
                                                                  index]
                                                              .imageName));
                                                },
                                                child: Text(
                                                  filteredImageDataList![index]
                                                      .imageName!,
                                                  overflow: TextOverflow.fade,
                                                  style: AppFontStyle.roboto(12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.black),
                                                ),
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
                                                final imageData =
                                                    filteredImageDataList!
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
                              });
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

  _onBytesGot(Uint8List bytes, String name) {
    final imageData = ImageData(bytes, name);
    widget.componentOperationCubit.byteCache[name] = bytes;
    widget.componentOperationCubit.uploadImage(imageData);
    if (widget.selectionEnable) {
      Navigator.pop(context, imageData);
    } else {
      setState(() {
        widget.componentOperationCubit.imageDataList?.add(imageData);
      });
    }
  }
}
