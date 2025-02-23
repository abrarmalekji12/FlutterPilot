part of 'feedback_bloc.dart';

@immutable
abstract class FeedbackState {}

class FeedbackInitial extends FeedbackState {}

class FeedbackSubmitLoadingState extends FeedbackState {}

class FeedbackSubmitSuccessState extends FeedbackState {}

class FeedbackErrorState extends FeedbackState {
  final String message;

  FeedbackErrorState(this.message);
}
