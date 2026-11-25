import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mypgpms/core/routes/app_routes.dart';
import 'package:mypgpms/core/storage/preferences_service.dart';
import 'package:mypgpms/features/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:mypgpms/features/authentication/data/models/user_model.dart';
import 'package:mypgpms/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:mypgpms/features/authentication/domain/usecases/check_auth_status_usecase.dart';
import 'package:mypgpms/features/authentication/domain/usecases/forgot_password_usecase.dart';
import 'package:mypgpms/features/authentication/domain/usecases/login_usecase.dart';
import 'package:mypgpms/features/authentication/domain/usecases/refresh_token_usecase.dart';
import 'package:mypgpms/features/authentication/domain/usecases/verify_otp_usecase.dart';
import 'package:mypgpms/features/authentication/domain/usecases/verify_phone_usecase.dart';
import 'package:mypgpms/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:mypgpms/features/authentication/presentation/bloc/auth_event.dart';
import 'package:mypgpms/features/authentication/presentation/bloc/auth_state.dart';
import 'package:mypgpms/features/authentication/presentation/pages/forgot_password_page.dart';
import 'package:mypgpms/features/authentication/presentation/pages/login_page.dart';
import 'package:mypgpms/features/authentication/presentation/pages/splash_page.dart';
import 'package:mypgpms/features/dashboard/presentation/pages/resident_dashboard_page.dart';
import 'package:mypgpms/features/admission/presentation/bloc/admission_bloc.dart';
import 'package:mypgpms/features/admission/presentation/bloc/admission_event.dart';
import 'package:mypgpms/features/admission/presentation/pages/review_details_page.dart';
import 'package:mypgpms/features/authentication/domain/usecases/get_me_usecase.dart';
import 'package:mypgpms/features/authentication/domain/usecases/update_profile_usecase.dart';
import 'package:mypgpms/injection_container.dart' as di;

class MockAuthRemoteDataSource implements AuthRemoteDataSource {
  final bool shouldSucceed;
  final String successMessage;
  final String errorMessage;

  MockAuthRemoteDataSource({
    this.shouldSucceed = true,
    this.successMessage = 'Login successful',
    this.errorMessage = 'Invalid email or password',
  });

  @override
  Future<LoginResultModel> login({
    required String emailOrPhone,
    required String password,
    required bool rememberMe,
  }) async {
    if (shouldSucceed) {
      return LoginResultModel(
        success: true,
        message: successMessage,
        accessToken: 'mock_access_token_123',
        refreshToken: 'mock_refresh_token_456',
        user: const UserModel(
          id: '1',
          name: 'Niraj Vekariya',
          email: 'nirajvekariya2209@gmail.com',
          phoneNumber: '9426886960',
          role: 'admin',
          pgName: 'HouseNest Sunshine PG',
          pgAddress: 'Plot 45, Near St. Xavier College',
        ),
        rawJson: {
          'success': true,
          'message': successMessage,
          'data': {
            'user': {
              'id': 1,
              'name': 'Niraj Vekariya',
              'email': 'nirajvekariya2209@gmail.com',
              'phone': '9426886960',
              'role': 'admin',
              'pg': {
                'name': 'HouseNest Sunshine PG',
                'address': 'Plot 45, Near St. Xavier College',
              },
            },
            'access_token': 'mock_access_token_123',
            'refresh_token': 'mock_refresh_token_456',
          },
        },
      );
    } else {
      throw Exception(errorMessage);
    }
  }

  @override
  Future<LoginResultModel> refreshToken({required String refreshToken}) async {
    if (shouldSucceed) {
      return LoginResultModel(
        success: true,
        message: 'Token refreshed successfully',
        accessToken: 'refreshed_access_token_789',
        refreshToken: 'refreshed_refresh_token_012',
        user: const UserModel(
          id: '1',
          name: 'Niraj Vekariya',
          email: 'nirajvekariya2209@gmail.com',
          phoneNumber: '9426886960',
        ),
        rawJson: {
          'success': true,
          'message': 'Token refreshed successfully',
          'data': {
            'access_token': 'refreshed_access_token_789',
            'refresh_token': 'refreshed_refresh_token_012',
            'user': {
              'id': 1,
              'name': 'Niraj Vekariya',
              'email': 'nirajvekariya2209@gmail.com',
              'phone': '9426886960',
            },
          },
        },
      );
    } else {
      throw Exception(errorMessage);
    }
  }

  @override
  Future<void> resendOtp({required String phoneNumber}) async {}

  @override
  Future<String> sendForgotPasswordReset({required String emailOrPhone}) async {
    return 'Password reset link has been sent to your email address.';
  }

  @override
  Future<void> sendPhoneVerification({required String phoneNumber}) async {}

  @override
  Future<UserModel> verifyOtp({required String phoneNumber, required String otp}) async {
    return const UserModel(
      id: '1',
      name: 'Niraj Vekariya',
      email: 'nirajvekariya2209@gmail.com',
      phoneNumber: '9426886960',
    );
  }

  @override
  Future<UserModel> getMe() async {
    return const UserModel(
      id: '2',
      name: 'Jasmin Korat',
      email: 'jasminkorat04@gmail.com',
      phoneNumber: '9510442798',
      gender: 'male',
      dateOfBirth: '18-11-2026',
      buildingName: 'Block A',
      floorName: '1st Floor',
      roomNo: '101',
      bedNumber: '1',
      roomType: 'triple',
    );
  }

  @override
  Future<Map<String, dynamic>> updateProfile({
    required Map<String, dynamic> fields,
    Map<String, String?>? filePaths,
  }) async {
    if (shouldSucceed) {
      return {
        'success': true,
        'message': 'Profile updated successfully',
      };
    } else {
      throw Exception(errorMessage);
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PreferencesService & Auth Storage Tests', () {
    test('PreferencesService saves and retrieves auth session accurately', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final prefService = PreferencesService(prefs);

      expect(prefService.isLoggedIn, false);
      expect(prefService.accessToken, null);

      final dummyResponse = {
        'success': true,
        'message': 'Login successful',
        'data': {
          'user': {
            'id': 1,
            'name': 'Niraj Vekariya',
            'email': 'nirajvekariya2209@gmail.com',
            'phone': '9426886960',
          },
          'access_token': 'test_token_abc',
          'refresh_token': 'test_refresh_def',
        },
      };

      await prefService.saveLoginResponse(responseJson: dummyResponse);

      expect(prefService.isLoggedIn, true);
      expect(prefService.accessToken, 'test_token_abc');
      expect(prefService.refreshToken, 'test_refresh_def');

      final savedUser = prefService.getSavedUser();
      expect(savedUser, isNotNull);
      expect(savedUser!['name'], 'Niraj Vekariya');

      await prefService.clearAuth();
      expect(prefService.isLoggedIn, false);
      expect(prefService.accessToken, null);
    });
  });

  group('AuthBloc Login & Persistence Flow', () {
    test('LoginSubmitted saves response to SharedPreferences and emits AuthLoginSuccess with API message', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final prefService = PreferencesService(prefs);

      final mockDataSource = MockAuthRemoteDataSource(
        shouldSucceed: true,
        successMessage: 'Login successful',
      );

      final repository = AuthRepositoryImpl(
        remoteDataSource: mockDataSource,
        preferencesService: prefService,
      );

      final loginUseCase = LoginUseCase(repository);
      final checkAuthStatusUseCase = CheckAuthStatusUseCase(repository);

      final bloc = AuthBloc(
        loginUseCase: loginUseCase,
        checkAuthStatusUseCase: checkAuthStatusUseCase,
        verifyPhoneUseCase: VerifyPhoneUseCase(repository),
        verifyOtpUseCase: VerifyOtpUseCase(repository),
        forgotPasswordUseCase: ForgotPasswordUseCase(repository),
      );

      expect(prefService.isLoggedIn, false);

      bloc.add(const LoginSubmitted(
        emailOrPhone: 'nirajvekariya2209@gmail.com',
        password: 'Niraj@123',
        rememberMe: true,
      ));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          predicate<AuthLoginSuccess>((state) =>
              state.message == 'Login successful' &&
              state.user.name == 'Niraj Vekariya'),
        ]),
      );

      expect(prefService.isLoggedIn, true);
      expect(prefService.accessToken, 'mock_access_token_123');
    });

    test('LoginSubmitted on failure emits AuthError with server error message', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final prefService = PreferencesService(prefs);

      final mockDataSource = MockAuthRemoteDataSource(
        shouldSucceed: false,
        errorMessage: 'Invalid email or password',
      );

      final repository = AuthRepositoryImpl(
        remoteDataSource: mockDataSource,
        preferencesService: prefService,
      );

      final loginUseCase = LoginUseCase(repository);
      final checkAuthStatusUseCase = CheckAuthStatusUseCase(repository);

      final bloc = AuthBloc(
        loginUseCase: loginUseCase,
        checkAuthStatusUseCase: checkAuthStatusUseCase,
        verifyPhoneUseCase: VerifyPhoneUseCase(repository),
        verifyOtpUseCase: VerifyOtpUseCase(repository),
        forgotPasswordUseCase: ForgotPasswordUseCase(repository),
      );

      bloc.add(const LoginSubmitted(
        emailOrPhone: 'wrong@example.com',
        password: 'wrong',
        rememberMe: true,
      ));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          predicate<AuthError>((state) => state.message.contains('Invalid email or password')),
        ]),
      );

      expect(prefService.isLoggedIn, false);
    });

    test('ForgotPasswordSubmitted emits ForgotPasswordSuccess with server message', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final prefService = PreferencesService(prefs);

      final mockDataSource = MockAuthRemoteDataSource();
      final repository = AuthRepositoryImpl(
        remoteDataSource: mockDataSource,
        preferencesService: prefService,
      );

      final bloc = AuthBloc(
        loginUseCase: LoginUseCase(repository),
        checkAuthStatusUseCase: CheckAuthStatusUseCase(repository),
        verifyPhoneUseCase: VerifyPhoneUseCase(repository),
        verifyOtpUseCase: VerifyOtpUseCase(repository),
        forgotPasswordUseCase: ForgotPasswordUseCase(repository),
      );

      bloc.add(const ForgotPasswordSubmitted(
        emailOrPhone: 'nirajvekariya2209@gmail.com',
      ));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          predicate<ForgotPasswordSuccess>((state) =>
              state.message == 'Password reset link has been sent to your email address.' &&
              state.emailOrPhone == 'nirajvekariya2209@gmail.com'),
        ]),
      );
    });

    test('RefreshTokenUseCase successfully refreshes tokens and updates PreferencesService', () async {
      SharedPreferences.setMockInitialValues({
        PreferencesService.keyIsLoggedIn: true,
        PreferencesService.keyAccessToken: 'old_access_token',
        PreferencesService.keyRefreshToken: 'old_refresh_token',
      });
      final prefs = await SharedPreferences.getInstance();
      final prefService = PreferencesService(prefs);

      final mockDataSource = MockAuthRemoteDataSource(shouldSucceed: true);
      final repository = AuthRepositoryImpl(
        remoteDataSource: mockDataSource,
        preferencesService: prefService,
      );

      final refreshTokenUseCase = RefreshTokenUseCase(repository);

      final result = await refreshTokenUseCase();

      expect(result.success, true);
      expect(result.accessToken, 'refreshed_access_token_789');
      expect(result.refreshToken, 'refreshed_refresh_token_012');

      expect(prefService.accessToken, 'refreshed_access_token_789');
      expect(prefService.refreshToken, 'refreshed_refresh_token_012');
    });
  });

  group('Splash Page Session Reload & Redirection Tests', () {
    setUp(() async {
      await di.sl.reset();
    });

    tearDown(() async {
      await di.sl.reset();
    });

    testWidgets('Splash routes directly to Invitation (/invitation) when is_complete_profile is false', (tester) async {
      SharedPreferences.setMockInitialValues({
        PreferencesService.keyIsLoggedIn: true,
        PreferencesService.keyIsCompleteProfile: false,
        PreferencesService.keyAccessToken: 'valid_token_xyz',
        PreferencesService.keyUserData: '{"id":2,"name":"Jasmin Korat","email":"jasminkorat04@gmail.com","is_complete_profile":false}',
      });

      await di.initDependencies();

      String? pushedRoute;
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.splash) {
              return MaterialPageRoute(builder: (_) => const SplashPage());
            }
            pushedRoute = settings.name;
            return MaterialPageRoute(builder: (_) => Scaffold(body: Text('Route: ${settings.name}')));
          },
          initialRoute: AppRoutes.splash,
        ),
      );

      // Trigger navigation
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      expect(pushedRoute, AppRoutes.invitation);
    });

    testWidgets('Splash routes directly to Resident Dashboard (/dashboard) when is_complete_profile is true', (tester) async {
      SharedPreferences.setMockInitialValues({
        PreferencesService.keyIsLoggedIn: true,
        PreferencesService.keyIsCompleteProfile: true,
        PreferencesService.keyAccessToken: 'valid_token_xyz',
        PreferencesService.keyUserData: '{"id":2,"name":"Jasmin Korat","email":"jasminkorat04@gmail.com","is_complete_profile":true}',
      });

      await di.initDependencies();

      String? pushedRoute;
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.splash) {
              return MaterialPageRoute(builder: (_) => const SplashPage());
            }
            pushedRoute = settings.name;
            return MaterialPageRoute(builder: (_) => Scaffold(body: Text('Route: ${settings.name}')));
          },
          initialRoute: AppRoutes.splash,
        ),
      );

      // Trigger navigation
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      expect(pushedRoute, AppRoutes.dashboard);
    });

    testWidgets('Splash routes to Login (/login) when no user session is available in SharedPreferences', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({});
      await di.initDependencies();

      String? pushedRoute;
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.splash) {
              return MaterialPageRoute(builder: (_) => const SplashPage());
            }
            pushedRoute = settings.name;
            return MaterialPageRoute(builder: (_) => Scaffold(body: Text('Route: ${settings.name}')));
          },
          initialRoute: AppRoutes.splash,
        ),
      );

      // Trigger navigation
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      expect(pushedRoute, AppRoutes.login);
    });

    testWidgets('ForgotPasswordPage does not overflow when keyboard opens', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({});
      await di.initDependencies();

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>(create: (_) => di.sl<AuthBloc>()),
          ],
          child: const MaterialApp(
            home: ForgotPasswordPage(),
          ),
        ),
      );

      // Simulate keyboard open by setting viewInsets
      tester.view.viewInsets = const FakeViewPadding(bottom: 800);
      addTearDown(tester.view.resetViewInsets);

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Send Reset Link'), findsOneWidget);
    });

    testWidgets('LoginPage does not overflow when keyboard opens', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({});
      await di.initDependencies();

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>(create: (_) => di.sl<AuthBloc>()),
          ],
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Simulate keyboard open by setting viewInsets
      tester.view.viewInsets = const FakeViewPadding(bottom: 800);
      addTearDown(tester.view.resetViewInsets);

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);
    });

    testWidgets('ResidentDashboardPage renders greeting, property banner, rent due, and tabs', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      const realJsonStr = '''
{
    "id": 2,
    "name": "Jasmin Korat",
    "email": "jasminkorat04@gmail.com",
    "phone": "9510442798",
    "gender": "male",
    "profile_photo": "user-123.jpg",
    "profile_photo_url": "https://api.mypgpms.com/uploads/users/user-123.jpg",
    "status": "active",
    "role": "resident",
    "is_complete_profile": true,
    "personal_info": {
        "name": "Jasmin Korat",
        "date_of_birth": "18-11-2026",
        "gender": "male"
    },
    "room_info": {
        "room_id": 1,
        "room_no": "101",
        "room_type": "triple",
        "building_name": "Block A",
        "floor_name": "1st Floor",
        "bed_number": "1",
        "monthly_rent": 8000,
        "check_in_date": "18-11-2026 00:00",
        "pg_name": "HouseNest Sunshine PG"
    }
}
''';

      SharedPreferences.setMockInitialValues({
        PreferencesService.keyIsLoggedIn: true,
        PreferencesService.keyAccessToken: 'valid_token_xyz',
        PreferencesService.keyUserData: realJsonStr,
      });
      await di.initDependencies();

      await tester.pumpWidget(
        const MaterialApp(
          home: ResidentDashboardPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Good morning,'), findsOneWidget);
      expect(find.text('Jasmin Korat'), findsOneWidget);
    });

    testWidgets('Submitting profile update calls updateProfile, getMe, saves local storage, and redirects to dashboard', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({
        PreferencesService.keyIsLoggedIn: true,
        PreferencesService.keyAccessToken: 'mock_token',
        PreferencesService.keyIsCompleteProfile: false,
      });
      await di.initDependencies();

      final prefs = await SharedPreferences.getInstance();
      final prefService = PreferencesService(prefs);
      final mockDataSource = MockAuthRemoteDataSource(shouldSucceed: true);
      final repo = AuthRepositoryImpl(
        remoteDataSource: mockDataSource,
        preferencesService: prefService,
      );
      final updateProfileUseCase = UpdateProfileUseCase(repo);
      final getMeUseCase = GetMeUseCase(repo);

      final admissionBloc = AdmissionBloc(
        getMeUseCase: getMeUseCase,
        updateProfileUseCase: updateProfileUseCase,
        preferencesService: prefService,
      );

      // Prepopulate admission state
      admissionBloc.add(const UpdatePersonalDetails(
        fullName: 'Kishan Patel',
        dateOfBirth: '20-08-1999',
        gender: 'male',
        phone: '9876452598',
        email: 'kishan.patel@example.com',
      ));
      admissionBloc.add(const UpdateAddressContact(
        addressLine1: '45 Green park society',
        city: 'Rajkot',
        state: 'Gujarat',
        pincode: '465601',
        emergencyName: 'Rupaliben Patel',
        emergencyRelationship: 'Mother',
        emergencyPhone: '9876452598',
      ));
      admissionBloc.add(const ToggleAgreement(true));

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRoutes.dashboard: (context) => const ResidentDashboardPage(),
          },
          home: BlocProvider<AdmissionBloc>.value(
            value: admissionBloc,
            child: const ReviewDetailsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Submit Application'), findsOneWidget);
      await tester.tap(find.text('Submit Application'));
      await tester.pumpAndSettle();

      // Check user profile complete is now true in local storage
      expect(prefService.isCompleteProfile, isTrue);
      // Navigated to Dashboard
      expect(find.byType(ResidentDashboardPage), findsOneWidget);
    });
  });
}
