import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';

import '../common/common_methods.dart';
import '../common/custom_popup_menu_button.dart';
import '../common/extension_util.dart';
import '../common/logger.dart';
import '../common/responsive/responsive_widget.dart';
import '../common/web/io_lib.dart';
import '../constant/color_assets.dart';
import '../constant/font_style.dart';
import '../cubit/component_operation/operation_cubit.dart';
import '../models/other_model.dart';
import '../models/project_model.dart';
import '../widgets/button/app_close_button.dart';
import '../widgets/message/empty_text.dart';
import '../widgets/textfield/appt_search_field.dart';
import 'navigation/animated_dialog.dart';

class ImageSelectionWidget extends StatefulWidget {
  final bool selectionEnable;
  final OperationCubit operationCubit;
  final ValueChanged<FVBImage>? onSelected;

  const ImageSelectionWidget(
      {required this.operationCubit,
      this.onSelected,
      this.selectionEnable = true,
      Key? key})
      : super(key: key);

  @override
  State<ImageSelectionWidget> createState() => _ImageSelectionWidgetState();
}

class _ImageSelectionWidgetState extends State<ImageSelectionWidget> {
  static List<FVBImage>? filteredImageDataList;
  final _controller = ScrollController();
  final _focusNode = FocusNode();
  final TextEditingController controller = TextEditingController();
  String _searchText = '';
  late FVBProject project;

  @override
  void initState() {
    super.initState();
    if (widget.operationCubit.imageDataList == null) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        widget.operationCubit
            .loadAllImages(widget.operationCubit.project!.userId)
            .then((imageList) {
          setState(() {
            filteredImageDataList = widget.operationCubit.imageDataList;
          });
        });
      });
    } else {
      filteredImageDataList = widget.operationCubit.imageDataList;
    }
    project = widget.operationCubit.project!;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener(
      bloc: widget.operationCubit,
      listener: (context, state) {
        if (state is ComponentOperationErrorState) {
          showToast(state.msg);
        }
      },
      child: Padding(
        padding:
            widget.selectionEnable ? const EdgeInsets.all(20) : EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        'Images',
                        style: widget.selectionEnable
                            ? AppFontStyle.headerStyle()
                            : AppFontStyle.titleStyle(),
                      ),
                      30.wBox,
                      InkWell(
                        onTap: _pickFiles,
                        borderRadius: BorderRadius.circular(8),
                        child: const Icon(
                          Icons.add,
                          color: ColorAssets.theme,
                        ),
                      ),
                      10.wBox,
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          widget.operationCubit
                              .loadAllImages(
                                  widget.operationCubit.project!.userId)
                              .then((imageList) {
                            setState(() {
                              filteredImageDataList =
                                  widget.operationCubit.imageDataList;
                            });
                          });
                        },
                        child: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                ),
                if (widget.selectionEnable)
                   AppCloseButton(
                    onTap:()=> AnimatedDialog.hide(context),
                  )
              ],
            ),
            10.hBox,
            SizedBox(
              height: 300,
              child: Column(
                children: [
                  Container(
                    height: 35,
                    margin: const EdgeInsets.symmetric(vertical: 8)
                        .copyWith(right: 10),
                    child: AppSearchField(
                      controller: controller,
                      hint: 'Search image..',
                      onChanged: (text) {
                        _searchText = text.toLowerCase();
                        setState(() {
                          filteredImageDataList = widget
                              .operationCubit.imageDataList!
                              .where((element) => element.name!
                                  .toLowerCase()
                                  .contains(_searchText))
                              .toList();
                        });
                      },
                      focusNode: _focusNode,
                    ),
                  ),
                  Expanded(
                    child: BlocBuilder<OperationCubit, OperationState>(
                        bloc: widget.operationCubit,
                        builder: (context, state) {
                          if (state is ComponentOperationLoadingState) {
                            return Shimmer.fromColors(
                              child: GridView.builder(
                                  shrinkWrap: true,
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
                          if (filteredImageDataList?.isEmpty ?? true) {
                            return const EmptyTextIconWidget(
                              text: 'No images',
                              icon: Icons.image,
                            );
                          }
                          return GridView.builder(
                            padding: const EdgeInsets.all(5),
                            restorationId: 'image grid builder',
                            controller: _controller,
                            shrinkWrap: true,
                            gridDelegate:
                                SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent:
                                        Responsive.isDesktop(context)
                                            ? 150
                                            : 100),
                            itemBuilder: (context, index) {
                              return StatefulBuilder(
                                  builder: (context, setState2) {
                                return InkWell(
                                  enableFeedback: widget.selectionEnable,
                                  onTap: widget.selectionEnable
                                      ? () {
                                          byteCache[
                                                  filteredImageDataList![index]
                                                      .name!] =
                                              filteredImageDataList![index]
                                                  .bytes!;
                                          if (!widget
                                              .operationCubit.project!.imageList
                                              .contains(
                                                  filteredImageDataList![index]
                                                      .name!)) {
                                            widget.operationCubit.project!
                                                .imageList
                                                .add(filteredImageDataList![
                                                        index]
                                                    .name!);
                                          }
                                          widget.onSelected?.call(
                                              filteredImageDataList![index]);
                                          AnimatedDialog.hide(context);
                                        }
                                      : null,
                                  child: Container(
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: ColorAssets.colorD0D5EF,
                                          width: 0.5,
                                        )),
                                    margin: const EdgeInsets.all(5),
                                    clipBehavior: Clip.hardEdge,
                                    child: Stack(
                                      children: [
                                        Center(
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child:
                                                (!filteredImageDataList![index]
                                                        .name!
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
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: ColorAssets.theme,
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                ),
                                                padding:
                                                    const EdgeInsets.all(4),
                                                child: Transform.scale(
                                                  scale: 0.8,
                                                  child: Checkbox(
                                                    fillColor:
                                                        WidgetStateProperty.all(
                                                            Colors.white),
                                                    materialTapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                    checkColor:
                                                        ColorAssets.theme,
                                                    value: project.imageList
                                                        .contains(
                                                            filteredImageDataList![
                                                                    index]
                                                                .name),
                                                    onChanged: (value) {
                                                      if (value != null) {
                                                        if (!value) {
                                                          project.imageList.remove(
                                                              filteredImageDataList![
                                                                      index]
                                                                  .name!);
                                                        } else {
                                                          project.imageList.add(
                                                              filteredImageDataList![
                                                                      index]
                                                                  .name!);
                                                        }
                                                        widget.operationCubit
                                                            .updateProjectConfig(
                                                                'imageList',
                                                                project
                                                                    .imageList);
                                                        setState2(() {});
                                                      }
                                                    },
                                                    visualDensity:
                                                        const VisualDensity(
                                                            horizontal: -4,
                                                            vertical: -4),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.bottomCenter,
                                          child: InkWell(
                                            onTap: () {
                                              Clipboard.setData(ClipboardData(
                                                  text: filteredImageDataList![
                                                              index]
                                                          .name ??
                                                      ''));
                                              showToast('Copied!');
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withOpacity(0.4)),
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      filteredImageDataList![
                                                              index]
                                                          .name!,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: AppFontStyle.lato(
                                                          13,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: Colors.white),
                                                    ),
                                                  ),
                                                  if (!widget
                                                      .selectionEnable) ...[
                                                    const SizedBox(
                                                      width: 5,
                                                    ),
                                                    const Icon(
                                                      Icons.copy,
                                                      size: 14,
                                                      color: Colors.white,
                                                    )
                                                  ]
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          right: 4,
                                          top: 4,
                                          child: CustomPopupMenuButton(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                color: Colors.black
                                                    .withOpacity(0.4),
                                              ),
                                              padding: const EdgeInsets.all(4),
                                              child: const Icon(
                                                Icons.more_vert,
                                                size: 20,
                                                color: Colors.white,
                                              ),
                                            ),
                                            itemBuilder:
                                                (BuildContext context) => [
                                              const CustomPopupMenuItem(
                                                value: 0,
                                                child: Text('Delete'),
                                              ),
                                              const CustomPopupMenuItem(
                                                value: 1,
                                                child: Text(
                                                    'Upload to public library'),
                                              )
                                            ],
                                            onSelected: (i) {
                                              switch (i) {
                                                case 0:
                                                  showConfirmDialog(
                                                      title: 'Alert!',
                                                      subtitle:
                                                          'Do you really want to delete this image?',
                                                      context: context,
                                                      positive: 'Yes',
                                                      negative: 'Cancel',
                                                      onPositiveTap: () {
                                                        final imageData =
                                                            filteredImageDataList!
                                                                .removeAt(
                                                                    index);
                                                        widget.operationCubit
                                                            .deleteImage(
                                                                imageData
                                                                    .name!);
                                                      });
                                                  break;
                                                case 1:
                                                  showConfirmDialog(
                                                      title: 'Alert!',
                                                      subtitle:
                                                          'Do you really want to upload this image to public library, anyone will be able to use it?',
                                                      context: context,
                                                      positive: 'Yes',
                                                      negative: 'Cancel',
                                                      onPositiveTap: () {
                                                        widget.operationCubit
                                                            .uploadPublicImage(
                                                                filteredImageDataList![
                                                                    index]);
                                                      });
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              });
                            },
                            itemCount: filteredImageDataList?.length ?? 0,
                          );
                        }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _onBytesGot(Uint8List bytes, String name) {
    final imageData = FVBImage(bytes: bytes, name: name);
    byteCache[name] = bytes;
    // widget.operationCubit.uploadImage(imageData).then((value) => null);
    if (widget.selectionEnable) {
      Navigator.pop(context, imageData);
    } else {
      setState(() {
        widget.operationCubit.imageDataList?.add(imageData);
      });
    }
  }

  void _pickFiles() {
    pickImages((value) {
      if (value.isNotEmpty) {
        _onBytesGot(value.first.bytes!, value.first.name!);
      }
    });
  }
}

void pickImages(ValueChanged<List<FVBImage>> onPicked) {
  if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
    ImagePicker()
        .pickImage(
      source: ImageSource.gallery,
    )
        .then((value) {
      if (value != null) {
        value.readAsBytes().then((bytes) {
          logger('=== IMAGE SELECTED ${value.name}  || ${value.path}');
          onPicked.call([
            FVBImage(bytes: bytes, name: value.name),
          ]);
        });
      }
    });
  } else {
    FilePicker.platform
        .pickFiles(
            withData: true,
            dialogTitle: 'Pick Image',
            type: FileType.custom,
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
        onPicked.call([
          FVBImage(bytes: file.bytes, name: file.name),
        ]);
      }
    });
  }
}
