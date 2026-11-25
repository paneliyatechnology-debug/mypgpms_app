import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/socket_service.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/usecases/check_auth_status_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/verify_phone_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final VerifyPhoneUseCase verifyPhoneUseCase;
  final VerifyOtpUseCase verifyOtpUseCase;
  final ForgotPasswordUseCase forgotPasswordUseCase;
  final CheckAuthStatusUseCase checkAuthStatusUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.verifyPhoneUseCase,
    required this.verifyOtpUseCase,
    required this.forgotPasswordUseCase,
    required this.checkAuthStatusUseCase,
  }) : super(AuthInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<PhoneVerificationSubmitted>(_onPhoneVerificationSubmitted);
    on<OtpSubmitted>(_onOtpSubmitted);
    on<OtpResendRequested>(_onOtpResendRequested);
    on<ForgotPasswordSubmitted>(_onForgotPasswordSubmitted);
    on<AuthResetState>(_onAuthResetState);
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final result = await loginUseCase(
        emailOrPhone: event.emailOrPhone,
        password: event.password,
        rememberMe: event.rememberMe,
      );

      if (result.success && result.user != null) {
        try {
          di.sl<SocketService>().connect();
        } catch (_) {}
        emit(AuthLoginSuccess(
          user: result.user!,
          message: result.message.isNotEmpty ? result.message : 'Login successful',
        ));
      } else {
        emit(AuthError(message: result.message.isNotEmpty ? result.message : 'Login failed'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  void _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) {
    if (checkAuthStatusUseCase()) {
      final user = checkAuthStatusUseCase.getSavedUser();
      if (user != null) {
        emit(AuthAuthenticated(user: user));
        return;
      }
    }
    emit(AuthUnauthenticated());
  }

  Future<void> _onPhoneVerificationSubmitted(
    PhoneVerificationSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await verifyPhoneUseCase(phoneNumber: event.phoneNumber);
      emit(PhoneVerificationSuccess(phoneNumber: event.phoneNumber));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onOtpSubmitted(
    OtpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await verifyOtpUseCase(
        phoneNumber: event.phoneNumber,
        otp: event.otp,
      );
      emit(OtpVerificationSuccess(user: user));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onOtpResendRequested(
    OtpResendRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await verifyOtpUseCase.resend(phoneNumber: event.phoneNumber);
      emit(const OtpResentSuccess());
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onForgotPasswordSubmitted(
    ForgotPasswordSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final message = await forgotPasswordUseCase(emailOrPhone: event.emailOrPhone);
      emit(ForgotPasswordSuccess(
        emailOrPhone: event.emailOrPhone,
        message: message,
      ));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  void _onAuthResetState(
    AuthResetState event,
    Emitter<AuthState> emit,
  ) {
    emit(AuthInitial());
  }
}
