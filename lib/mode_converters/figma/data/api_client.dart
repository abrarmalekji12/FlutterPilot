import 'package:dio/dio.dart';
import 'package:retrofit/http.dart';

import 'models/figma_file_response.dart';
import 'models/figma_files_image_response.dart';
import 'models/figma_nodes_images_response.dart';

part 'api_client.g.dart';

@RestApi(baseUrl: 'https://api.figma.com/v1/')
abstract class FigmaApiClient {
  factory FigmaApiClient(Dio dio) {
    return _FigmaApiClient(dio);
  }

  @GET('files/{key}')
  Future<FigmaFileResponse> getFigmaFile(
      @Path('key') String key, @Header('Authorization') token); //X-FIGMA-TOKEN

  @GET('files/{key}/images')
  Future<FigmaFilesImageResponse> getFigmaFileImages(
      @Path('key') String key, @Header('Authorization') token);

  @GET('images/{key}')
  Future<FigmaNodesImagesResponse> getNodesImages(
      @Path('key') String key,
      @Header('Authorization') token,
      @Query('ids') String ids,
      @Query('format') String format,
      @Query('use_absolute_bounds') bool useAbsoluteBounds,
      {@Query('scale') String? scale});
}
