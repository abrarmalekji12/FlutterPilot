import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/remote/firestore/firebase_bridge.dart';
import '../model/feedback.dart';

part 'feedback_event.dart';
part 'feedback_state.dart';

class FeedbackBloc extends Bloc<FeedbackEvent, FeedbackState> {
  FeedbackBloc() : super(FeedbackInitial()) {
    on<FeedbackEvent>((event, emit) {});

    on<SubmitFeedbackEvent>(_submitFeedback);
  }

  FutureOr<void> _submitFeedback(
      SubmitFeedbackEvent event, Emitter<FeedbackState> emit) async {
    try {
      emit(FeedbackSubmitLoadingState());
      await dataBridge.addFeedback(event.feedback);
      emit(FeedbackSubmitSuccessState());
    } on Exception catch (e) {
      emit(FeedbackErrorState(e.toString()));
    }
  }
}
