import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserEntity user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthLoginSuccess extends AuthState {
  final UserEntity user;
  final String message;

  const AuthLoginSuccess({
    required this.user,
    this.message = 'Login successful',
  });

  @override
  List<Object?> get props => [user, message];
}

class PhoneVerificationSuccess extends AuthState {
  final String phoneNumber;

  const PhoneVerificationSuccess({required this.phoneNumber});

  @override
  List<Object?> get props => [phoneNumber];
}

class OtpVerificationSuccess extends AuthState {
  final UserEntity user;

  const OtpVerificationSuccess({required this.user});

  @override
  List<Object?> get props => [user];
}

class OtpResentSuccess extends AuthState {
  final String message;

  const OtpResentSuccess({this.message = 'Verification code resent successfully'});

  @override
  List<Object?> get props => [message];
}

class ForgotPasswordSuccess extends AuthState {
  final String emailOrPhone;
  final String message;

  const ForgotPasswordSuccess({
    required this.emailOrPhone,
    this.message = 'Password reset link has been sent to your email address.',
  });

  @override
  List<Object?> get props => [emailOrPhone, message];
}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}
