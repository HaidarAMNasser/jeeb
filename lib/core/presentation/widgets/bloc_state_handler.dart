import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_circle_indicator.dart';
import 'package:jeeb_app/core/presentation/widgets/empty_state_widget.dart';
import 'package:jeeb_app/core/presentation/widgets/error_state_widget.dart';


class BlocStateHandler<B extends StateStreamable<S>, S> extends StatelessWidget {
  /// The bloc to listen to
  final B bloc;

  /// Builder for the success/loaded state
  final Widget Function(BuildContext context, S state) successBuilder;

  /// Optional custom loading widget
  final Widget? loadingWidget;

  /// Optional custom error widget builder
  final Widget Function(BuildContext context, String message, VoidCallback? onRetry)? errorBuilder;

  /// Optional custom empty state widget builder
  final Widget Function(BuildContext context)? emptyBuilder;

  /// Function to check if state is loading
  final bool Function(S state)? isLoading;

  /// Function to check if state is error
  final bool Function(S state)? isError;

  /// Function to get error message from error state
  final String Function(S state)? getErrorMessage;

  /// Function to check if state is success/loaded
  final bool Function(S state)? isSuccess;

  /// Function to check if state is empty (optional)
  final bool Function(S state)? isEmpty;

  /// Function to get retry callback (optional)
  final VoidCallback? Function(S state)? getRetryCallback;

  /// Empty state message (used if emptyBuilder is not provided)
  final String? emptyMessage;

  const BlocStateHandler({
    super.key,
    required this.bloc,
    required this.successBuilder,
    this.loadingWidget,
    this.errorBuilder,
    this.emptyBuilder,
    this.isLoading,
    this.isError,
    this.getErrorMessage,
    this.isSuccess,
    this.isEmpty,
    this.getRetryCallback,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<B, S>(
      bloc: bloc,
      builder: (context, state) {
        // Check loading state
        if (_checkLoading(state)) {
          return loadingWidget ?? const CustomCircleIndicator();
        }

        // Check error state
        if (_checkError(state)) {
          final errorMsg = _getErrorMessage(state);
          final onRetry = _getRetryCallback(state);
          final isNetworkError = _isNetworkError(errorMsg);
          final displayMessage = isNetworkError 
              ? AppTranslation.noInternetConnection 
              : errorMsg;
          
          if (errorBuilder != null) {
            return errorBuilder!(context, displayMessage, onRetry);
          }
          return ErrorStateWidget(
            message: displayMessage,
            icon: isNetworkError ? Icons.wifi_off : Icons.error_outline,
            onRetry: onRetry,
          );
        }

        // Check empty state (optional)
        if (isEmpty != null && isEmpty!(state)) {
          if (emptyBuilder != null) {
            return emptyBuilder!(context);
          }
          return EmptyStateWidget(
            message: emptyMessage ?? 'No data available',
          );
        }

        // Check success state
        if (_checkSuccess(state)) {
          return successBuilder(context, state);
        }

        // Default: show loading
        return loadingWidget ?? const CustomCircleIndicator();
      },
    );
  }

  bool _checkLoading(S state) {
    if (isLoading != null) {
      return isLoading!(state);
    }
    // Try to detect loading state by class name or property
    final stateStr = state.toString();
    if (stateStr.contains('Loading')) {
      return true;
    }
    // Try to access isLoading property via reflection-like check
    try {
      final dynamic stateDynamic = state;
      if (stateDynamic.isLoading == true) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  bool _checkError(S state) {
    if (isError != null) {
      return isError!(state);
    }
    // Try to detect error state by class name or property
    final stateStr = state.toString();
    if (stateStr.contains('Error')) {
      return true;
    }
    // Try to access errorMessage or message property
    try {
      final dynamic stateDynamic = state;
      if (stateDynamic.errorMessage != null || stateDynamic.message != null) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  String _getErrorMessage(S state) {
    if (getErrorMessage != null) {
      return getErrorMessage!(state);
    }
    // Try to get error message from state
    try {
      final dynamic stateDynamic = state;
      return stateDynamic.message ?? stateDynamic.errorMessage ?? 'An error occurred';
    } catch (_) {
      return 'An error occurred';
    }
  }

  bool _checkSuccess(S state) {
    if (isSuccess != null) {
      return isSuccess!(state);
    }
    // Try to detect success/loaded state by class name
    final stateStr = state.toString();
    if (stateStr.contains('Loaded') || stateStr.contains('Success')) {
      return true;
    }
    // If not loading and not error, assume success
    return !_checkLoading(state) && !_checkError(state);
  }

  VoidCallback? _getRetryCallback(S state) {
    if (getRetryCallback != null) {
      return getRetryCallback!(state);
    }
    return null;
  }

  /// Check if the error message indicates a network error
  bool _isNetworkError(String message) {
    final lowerMessage = message.toLowerCase();
    return lowerMessage.contains('network') ||
        lowerMessage.contains('internet') ||
        lowerMessage.contains('connection') ||
        lowerMessage.contains('no internet') ||
        lowerMessage.contains('check your network');
  }
}

