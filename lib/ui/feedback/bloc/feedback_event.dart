part of 'feedback_bloc.dart';

@immutable
abstract class FeedbackEvent {}

class SubmitFeedbackEvent extends FeedbackEvent {
  final FVBFeedback feedback;

  SubmitFeedbackEvent(this.feedback);
}
