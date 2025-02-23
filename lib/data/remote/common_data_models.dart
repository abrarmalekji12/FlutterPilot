import '../../models/template_model.dart';

class TemplatePaginate {
  final List<TemplateModel> models;
  final dynamic last;

  TemplatePaginate(this.models, this.last);
}

enum ProjectLoadError {
  notPermission,
  networkError,
  notFound,
  otherError,
}

class ProjectLoadErrorModel {
  final ProjectLoadError projectLoadError;
  final String? error;

  ProjectLoadErrorModel(this.projectLoadError, this.error);
}

class Optional<A, B> {
  final A? a;
  final B? b;

  Optional._(this.a, this.b);

  factory Optional.right(B b) {
    return Optional._(null, b);
  }

  factory Optional.left(A a) {
    return Optional._(a, null);
  }

  bool get isRight {
    return b != null;
  }

  bool get isLeft {
    return a != null;
  }

  A get left {
    return a!;
  }

  B get right {
    return b!;
  }
}

class DocData {
  final String collectId;
  final String docId;

  DocData(this.collectId, this.docId);
}
