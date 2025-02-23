import 'package:flutter/widgets.dart';

import '../models/project_model.dart';

abstract class Collections {
  static const SEARCH_ICON = 'assets/icons/search_icon.png';
  static const kCustomComponents = 'customComponents';
  static const kProjects = 'projects';
  static const kFeedbacks = 'feedbacks';
  static const kUsers = 'users';
  static const kCommits = 'commits';
  static const kVersionControl = 'versionControl';
  static const kComponents = 'components';
  static const kScreens = 'screens';
  static const kTemplates = 'templates';
  static const kScreenTemplates = 'screenTemplates';

  static const kProjectInfo = 'projectInfo';
  static const kFavourites = 'favourites';
  static const kStorage = 'storage';
  static const kImages = 'images';

  static const kPaintObjs = 'paintObjs';
}

class ImageRef {
  static userImages(String id, String name) => 'users/$id/$name';
  static publicImages(String name) => 'public/$name';
  static templateImage(String name) => 'templates/$name';

  static String projectThumbnail(FVBProject project) =>
      'projects/${project.id}/thumbnail.jpg';
}

const String appLink = 'https://flutterpilot.web.app/';
// 'https://flutter-visual-builder.web.app/'

GlobalKey? deviceScaffoldMessenger;

GlobalKey? dialogNavigationKey;
const wEmailRegex =
    "^[a-zA-Z0-9.a-zA-Z0-9.!#\$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+.[a-zA-Z]+";
const minPasswordLength = 6;

GlobalKey<NavigatorState>? navigationKey;

GlobalKey<NavigatorState> get debugNavigatorKey => GlobalKey();

GlobalKey<NavigatorState> get releaseNavigatorKey => GlobalKey();

GlobalKey<NavigatorState> get debugDeviceScaffoldMessenger => GlobalKey();

GlobalKey<NavigatorState> get releaseDeviceScaffoldMessenger => GlobalKey();
