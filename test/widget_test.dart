import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mypgpms/core/constants/app_strings.dart';
import 'package:mypgpms/core/storage/preferences_service.dart';
import 'package:mypgpms/features/admission/presentation/pages/address_contact_page.dart';import 'package:mypgpms/features/admission/presentation/bloc/admission_bloc.dart';

import 'package:mypgpms/features/admission/presentation/pages/agreement_signature_page.dart';
import 'package:mypgpms/features/admission/presentation/pages/document_upload_page.dart';
import 'package:mypgpms/features/admission/presentation/pages/personal_details_page.dart';
import 'package:mypgpms/features/admission/presentation/pages/review_details_page.dart';
import 'package:mypgpms/features/admission/presentation/pages/room_confirmation_page.dart';
import 'package:mypgpms/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:mypgpms/features/authentication/presentation/pages/forgot_password_page.dart';
import 'package:mypgpms/features/authentication/presentation/pages/login_page.dart';
import 'package:mypgpms/features/authentication/presentation/pages/phone_verification_page.dart';
import 'package:mypgpms/features/authentication/presentation/pages/welcome_page.dart';
import 'package:mypgpms/features/dashboard/presentation/pages/admission_invitation_page.dart';
import 'package:mypgpms/injection_container.dart' as di;
import 'package:mypgpms/main.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  tearDown(() async {
    await di.sl.reset();
  });

  testWidgets('MYPGPMS App smoke test renders splash', (WidgetTester tester) async {
    await tester.pumpWidget(const MYPGPMSApp());
    expect(find.text('Better Stays, Brighter Days.'), findsOneWidget);
  });

  testWidgets('WelcomePage renders title, subtitle, and action buttons', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WelcomePage(),
      ),
    );
    expect(find.text('Your home\naway from home'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('I already have an account'), findsOneWidget);
  });

  testWidgets('LoginPage renders welcome back, inputs, and login button', (WidgetTester tester) async {
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
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Remember me'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
  });

  testWidgets('PhoneVerificationPage renders title, inputs, and continue button', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(create: (_) => di.sl<AuthBloc>()),
        ],
        child: const MaterialApp(
          home: PhoneVerificationPage(),
        ),
      ),
    );
    expect(find.text('Verify your number'), findsOneWidget);
    expect(find.text('Verify your phone number'), findsOneWidget);
    expect(find.text('Enter your phone number'), findsOneWidget);
    expect(find.text('+91'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    // Tap continue with empty field to trigger validation error
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Verify error text is displayed properly outside the input box
    expect(find.text('Please enter your phone number'), findsOneWidget);
  });

  testWidgets('ForgotPasswordPage renders title, inputs, and send reset link button', (WidgetTester tester) async {
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
    expect(find.text(AppStrings.forgotPasswordTitle), findsOneWidget);
    expect(find.text(AppStrings.forgotPasswordSubtitle), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text(AppStrings.sendResetLink), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is RichText && widget.text.toPlainText().contains('Log In'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('AdmissionInvitationPage renders invitation badge, title, room specs, and start application button', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdmissionInvitationPage(),
      ),
    );
    expect(find.text(AppStrings.invitation), findsOneWidget);
    expect(find.text(AppStrings.invitedTitle), findsOneWidget);
    expect(find.text(AppStrings.propertyNameSample), findsOneWidget);
    expect(find.text(AppStrings.propertyCitySample), findsOneWidget);
    expect(find.text(AppStrings.roomSample), findsOneWidget);
    expect(find.text(AppStrings.bedSample), findsOneWidget);
    expect(find.text(AppStrings.roomTypeSample), findsOneWidget);
    expect(find.text(AppStrings.rentSample), findsOneWidget);
    expect(find.text(AppStrings.startApplication), findsOneWidget);
    expect(find.text(AppStrings.needHelp), findsOneWidget);
  });

  testWidgets('AdmissionInvitationPage displays dynamic building, floor, room, bed, and room_type when user data exists', (WidgetTester tester) async {
    final prefs = di.sl<PreferencesService>();
    await prefs.saveLoginResponse(
      responseJson: {
        'success': true,
        'message': 'Login successful',
        'data': {
          'access_token': 'test_token',
          'refresh_token': 'test_refresh',
          'user': {
            'id': 2,
            'name': 'Jasmin Korat',
            'email': 'jasminkorat04@gmail.com',
            'phone': '9510442798',
            'is_complete_profile': false,
            'pg': {
              'name': 'HouseNest Sunshine PG',
              'city': 'Main Branch',
            },
            'room_info': {
              'building_name': 'Block A',
              'floor_name': '1st Floor',
              'room_no': '101',
              'bed_number': '1',
              'room_type': 'triple',
              'monthly_rent': 8000,
            },
          },
        },
      },
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: AdmissionInvitationPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('HouseNest Sunshine PG'), findsOneWidget);
    expect(find.text('Main Branch'), findsOneWidget);
    expect(find.text('Block A'), findsOneWidget);
    expect(find.text('1st Floor'), findsOneWidget);
    expect(find.text('Room 101'), findsOneWidget);
    expect(find.text('Bed 1'), findsOneWidget);
    expect(find.text('Triple Sharing'), findsOneWidget);
    expect(find.text('Rs. 8000/month'), findsOneWidget);

    // Clean up
    await prefs.clearAuth();
  });

  testWidgets('PersonalDetailsPage renders form elements, gender chips and validates fields', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AdmissionBloc>(create: (_) => di.sl<AdmissionBloc>()),
        ],
        child: const MaterialApp(
          home: PersonalDetailsPage(),
        ),
      ),
    );
    expect(find.text('Personal Details'), findsOneWidget);
    expect(find.text(AppStrings.tellUsAboutYourself), findsOneWidget);
    expect(find.text('Full name *'), findsOneWidget);
    expect(find.text('Date of birth *'), findsOneWidget);
    expect(find.text('Gender *'), findsOneWidget);
    expect(find.text('Male'), findsOneWidget);
    expect(find.text('Female'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    // Tap next to trigger required field validations
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your full name'), findsOneWidget);
    expect(find.text('Please select your date of birth'), findsOneWidget);
    expect(find.text('Please enter your phone number'), findsOneWidget);
    expect(find.text('Please enter your email address'), findsOneWidget);
  });

  testWidgets('PersonalDetailsPage automatically pre-fills user details from saved user profile', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final prefs = di.sl<PreferencesService>();
    await prefs.saveUserData({
      'name': 'Jasmin Korat',
      'email': 'jasminkorat04@gmail.com',
      'phone': '9510442798',
      'personal_info': {
        'name': 'Jasmin Korat',
        'date_of_birth': '18-11-2026',
        'gender': 'male',
      },
      'contact_info': {
        'phone': '9510442798',
        'email': 'jasminkorat04@gmail.com',
      },
    });

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AdmissionBloc>(create: (_) => di.sl<AdmissionBloc>()),
        ],
        child: const MaterialApp(
          home: PersonalDetailsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Jasmin Korat'), findsOneWidget);
    expect(find.text('18/11/2026'), findsOneWidget);
    expect(find.text('9510442798'), findsOneWidget);
    expect(find.text('jasminkorat04@gmail.com'), findsOneWidget);

    await prefs.clearAuth();
  });

  testWidgets('AddressContactPage renders address and emergency inputs', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AdmissionBloc>(create: (_) => di.sl<AdmissionBloc>()),
        ],
        child: const MaterialApp(
          home: AddressContactPage(),
        ),
      ),
    );
    expect(find.text(AppStrings.addressEmergencyTitle), findsOneWidget);
    expect(find.text(AppStrings.currentAddress), findsOneWidget);
    expect(find.text(AppStrings.emergencyContact), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('DocumentUploadPage renders document cards with upload triggers', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(466, 1024);
    tester.view.devicePixelRatio = 1.2;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AdmissionBloc>(create: (_) => di.sl<AdmissionBloc>()),
        ],
        child: const MaterialApp(
          home: DocumentUploadPage(),
        ),
      ),
    );
    expect(find.text('Document Upload'), findsOneWidget);
    expect(find.text('Upload Documents'), findsOneWidget);
    expect(find.text('Upload File'), findsWidgets);
    await tester.tap(find.text('Upload File').first);
    await tester.pumpAndSettle();
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
  });

  testWidgets('AgreementSignaturePage renders resident agreement and terms checkbox', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AdmissionBloc>(create: (_) => di.sl<AdmissionBloc>()),
        ],
        child: const MaterialApp(
          home: AgreementSignaturePage(),
        ),
      ),
    );
    expect(find.text(AppStrings.agreementTitle), findsOneWidget);
    expect(find.text(AppStrings.residentAgreementPdf), findsOneWidget);
    expect(find.text(AppStrings.clearSignature), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('ReviewDetailsPage renders summary and edit triggers', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AdmissionBloc>(create: (_) => di.sl<AdmissionBloc>()),
        ],
        child: const MaterialApp(
          home: ReviewDetailsPage(),
        ),
      ),
    );
    expect(find.text('Review Your Details'), findsWidgets);
    expect(find.text(AppStrings.submitApplication), findsOneWidget);
    expect(find.text(AppStrings.edit), findsWidgets);
  });

  testWidgets('RoomConfirmationPage renders confirmation banner and dashboard button', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: RoomConfirmationPage(),
      ),
    );
    expect(find.text('Congratulations!'), findsOneWidget);
    expect(find.text(AppStrings.goToDashboard), findsOneWidget);
  });
}
