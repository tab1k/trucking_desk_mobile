import 'package:flutter_riverpod/flutter_riverpod.dart';

enum GlobalErrorType { none, noConnection, serverError }

class GlobalErrorState {
  final GlobalErrorType type;
  final String? message;

  const GlobalErrorState({this.type = GlobalErrorType.none, this.message});
}

class GlobalErrorNotifier extends StateNotifier<GlobalErrorState> {
  GlobalErrorNotifier() : super(const GlobalErrorState());

  void showNoConnection() {
    if (state.type != GlobalErrorType.noConnection) {
      state = const GlobalErrorState(type: GlobalErrorType.noConnection);
    }
  }

  void showServerError({String? message}) {
    if (state.type != GlobalErrorType.serverError) {
      state = GlobalErrorState(
        type: GlobalErrorType.serverError,
        message: message,
      );
    }
  }

  void clear() {
    if (state.type != GlobalErrorType.none) {
      state = const GlobalErrorState(type: GlobalErrorType.none);
    }
  }
}

final globalErrorProvider =
    StateNotifierProvider<GlobalErrorNotifier, GlobalErrorState>((ref) {
      return GlobalErrorNotifier();
    });
