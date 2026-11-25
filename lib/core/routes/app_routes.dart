import 'package:flutter/material.dart';
import '../../features/authentication/presentation/pages/splash_page.dart';
import '../../features/authentication/presentation/pages/welcome_page.dart';
import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/authentication/presentation/pages/phone_verification_page.dart';
import '../../features/authentication/presentation/pages/otp_verification_page.dart';
import '../../features/authentication/presentation/pages/forgot_password_page.dart';
import '../../features/dashboard/presentation/pages/admission_invitation_page.dart';
import '../../features/dashboard/presentation/pages/resident_dashboard_page.dart';
import '../../features/dashboard/presentation/pages/notifications_page.dart';
import '../../features/dashboard/presentation/pages/notice_details_page.dart';
import '../../features/dashboard/presentation/pages/today_menu_page.dart';
import '../../features/dashboard/presentation/pages/weekly_menu_page.dart';
import '../../features/dashboard/presentation/pages/menu_feedback_page.dart';
import '../../features/dashboard/presentation/pages/visitors_page.dart';
import '../../features/dashboard/presentation/pages/add_visitor_page.dart';
import '../../features/dashboard/presentation/pages/digital_id_page.dart';
import '../../features/dashboard/presentation/pages/payments_page.dart';
import '../../features/dashboard/presentation/pages/payment_details_page.dart';
import '../../features/dashboard/presentation/pages/rent_details_page.dart';
import '../../features/dashboard/presentation/pages/payment_method_page.dart';
import '../../features/dashboard/presentation/pages/payment_transaction_page.dart';
import '../../features/dashboard/presentation/pages/upi_payment_page.dart';
import '../../features/dashboard/presentation/pages/payment_success_page.dart';
import '../../features/dashboard/presentation/pages/receipt_pdf_viewer_page.dart';
import '../../features/dashboard/presentation/pages/services_page.dart';
import '../../features/dashboard/presentation/pages/report_issue_page.dart';
import '../../features/dashboard/presentation/pages/create_complaint_page.dart';
import '../../features/dashboard/presentation/pages/my_complaints_page.dart';
import '../../features/dashboard/presentation/pages/complaint_details_page.dart';
import '../../features/dashboard/data/models/complaint_model.dart';
import '../../features/dashboard/data/models/visitor_model.dart';
import '../../features/dashboard/presentation/pages/complaint_feedback_page.dart';
import '../../features/dashboard/presentation/pages/profile_page.dart';
import '../../features/dashboard/presentation/pages/edit_profile_page.dart';
import '../../features/dashboard/presentation/pages/personal_information_page.dart';
import '../../features/dashboard/presentation/pages/room_property_details_page.dart';
import '../../features/dashboard/presentation/pages/documents_agreement_page.dart';
import '../../features/dashboard/presentation/pages/emergency_contact_page.dart';
import '../../features/dashboard/presentation/pages/notification_settings_page.dart';
import '../../features/dashboard/presentation/pages/room_shift_page.dart';
import '../../features/dashboard/presentation/pages/request_room_shift_page.dart';
import '../../features/dashboard/presentation/pages/staff_directory_page.dart';
import '../../features/dashboard/data/models/checkout_model.dart';
import '../../features/dashboard/presentation/pages/checkout_request_page.dart';
import '../../features/dashboard/presentation/pages/checkout_review_noc_page.dart';
import '../../features/dashboard/presentation/pages/checkout_status_page.dart';
import '../../features/admission/presentation/pages/personal_details_page.dart';
import '../../features/admission/presentation/pages/address_contact_page.dart';
import '../../features/admission/presentation/pages/document_upload_page.dart';
import '../../features/admission/presentation/pages/agreement_signature_page.dart';
import '../../features/admission/presentation/pages/review_details_page.dart';
import '../../features/admission/presentation/pages/room_confirmation_page.dart';

/// Centralized routes management for MYPGPMS.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String phoneVerification = '/phone-verification';
  static const String otpVerification = '/otp-verification';
  static const String forgotPassword = '/forgot-password';
  static const String invitation = '/invitation';
  static const String dashboard = '/dashboard';
  static const String notifications = '/notifications';
  static const String noticeDetails = '/notice-details';
  static const String todayMenu = '/today-menu';
  static const String weeklyMenu = '/weekly-menu';
  static const String menuFeedback = '/menu-feedback';
  static const String visitors = '/visitors';
  static const String addVisitor = '/add-visitor';
  static const String digitalId = '/digital-id';
  static const String payments = '/payments';
  static const String paymentDetails = '/payment-details';
  static const String rentDetails = '/rent-details';
  static const String paymentMethod = '/payment-method';
  static const String paymentTransaction = '/payment-transaction';
  static const String upiPayment = '/upi-payment';
  static const String paymentSuccess = '/payment-success';
  static const String paymentReceipt = '/payment-receipt';
  static const String services = '/services';
  static const String reportIssue = '/report-issue';
  static const String createComplaint = '/create-complaint';
  static const String myComplaints = '/my-complaints';
  static const String complaintDetails = '/complaint-details';
  static const String complaintFeedback = '/complaint-feedback';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String personalInformation = '/personal-information';
  static const String roomPropertyDetails = '/room-property-details';
  static const String documentsAgreement = '/documents-agreement';
  static const String emergencyContact = '/emergency-contact';
  static const String notificationSettings = '/notification-settings';
  static const String roomShift = '/room-shift';
  static const String requestRoomShift = '/request-room-shift';
  static const String staffDirectory = '/staff-directory';
  static const String checkoutRequest = '/checkout-request';
  static const String checkoutReviewNoc = '/checkout-review-noc';
  static const String checkoutStatus = '/checkout-status';
  static const String admissionPersonal = '/admission/personal';
  static const String admissionAddress = '/admission/address';
  static const String admissionDocuments = '/admission/documents';
  static const String admissionRoomBed = '/admission/room-bed';
  static const String admissionAgreement = '/admission/agreement';
  static const String admissionReview = '/admission/review';
  static const String admissionSuccess = '/admission/success';
  static const String admissionConfirmed = '/admission/confirmed';
  static const String applicationStatus = '/admission/status';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _buildRoute(const SplashPage(), settings);
      case welcome:
        return _buildRoute(const WelcomePage(), settings);
      case login:
        return _buildRoute(const LoginPage(), settings);
      case phoneVerification:
        return _buildRoute(const PhoneVerificationPage(), settings);
      case otpVerification:
        final phoneNumber = settings.arguments as String?;
        return _buildRoute(
          OtpVerificationPage(phoneNumber: phoneNumber),
          settings,
        );
      case forgotPassword:
        return _buildRoute(const ForgotPasswordPage(), settings);
      case invitation:
        return _buildRoute(const AdmissionInvitationPage(), settings);
      case dashboard:
        return _buildRoute(const ResidentDashboardPage(), settings);
      case notifications:
        return _buildRoute(const NotificationsPage(), settings);
      case noticeDetails:
        return _buildRoute(NoticeDetailsPage(arguments: settings.arguments), settings);
      case todayMenu:
        return _buildRoute(const TodayMenuPage(), settings);
      case weeklyMenu:
        return _buildRoute(const WeeklyMenuPage(), settings);
      case menuFeedback:
        return _buildRoute(const MenuFeedbackPage(), settings);
      case visitors:
        return _buildRoute(const VisitorsPage(), settings);
      case addVisitor:
        final initialVisitor = settings.arguments is VisitorItemModel ? settings.arguments as VisitorItemModel : null;
        return _buildRoute(AddVisitorPage(initialVisitor: initialVisitor), settings);
      case digitalId:
        return _buildRoute(const DigitalIdPage(), settings);
      case payments:
        return _buildRoute(const PaymentsPage(), settings);
      case rentDetails:
        return _buildRoute(RentDetailsPage(payment: settings.arguments), settings);
      case paymentDetails:
        return _buildRoute(PaymentDetailsPage(paymentId: settings.arguments ?? 1), settings);
      case paymentMethod:
        return _buildRoute(PaymentMethodPage(paymentId: settings.arguments), settings);
      case paymentTransaction:
        return _buildRoute(PaymentTransactionPage(arguments: settings.arguments), settings);
      case upiPayment:
        return _buildRoute(const UpiPaymentPage(), settings);
      case paymentSuccess:
        return _buildRoute(PaymentSuccessPage(arguments: settings.arguments), settings);
      case paymentReceipt:
        return _buildRoute(ReceiptPdfViewerPage(arguments: settings.arguments), settings);
      case services:
        return _buildRoute(const ServicesPage(), settings);
      case reportIssue:
        return _buildRoute(const ReportIssuePage(), settings);
      case createComplaint:
        final cat = settings.arguments as String?;
        return _buildRoute(CreateComplaintPage(initialCategory: cat), settings);
      case myComplaints:
        return _buildRoute(const MyComplaintsPage(), settings);
      case complaintDetails:
        if (settings.arguments is ComplaintItemModel) {
          return _buildRoute(
            ComplaintDetailsPage(complaint: settings.arguments as ComplaintItemModel),
            settings,
          );
        } else if (settings.arguments is int) {
          return _buildRoute(
            ComplaintDetailsPage(complaintId: settings.arguments as int),
            settings,
          );
        }
        return _buildRoute(const ComplaintDetailsPage(), settings);
      case complaintFeedback:
        return _buildRoute(const ComplaintFeedbackPage(), settings);
      case profile:
        return _buildRoute(const ProfilePage(), settings);
      case editProfile:
        return _buildRoute(const EditProfilePage(), settings);
      case personalInformation:
        return _buildRoute(const PersonalInformationPage(), settings);
      case roomPropertyDetails:
        return _buildRoute(const RoomPropertyDetailsPage(), settings);
      case documentsAgreement:
        return _buildRoute(const DocumentsAgreementPage(), settings);
      case emergencyContact:
        return _buildRoute(const EmergencyContactPage(), settings);
      case notificationSettings:
        return _buildRoute(const NotificationSettingsPage(), settings);
      case roomShift:
        return _buildRoute(const RoomShiftPage(), settings);
      case requestRoomShift:
        final initialRoom = settings.arguments as String?;
        return _buildRoute(RequestRoomShiftPage(initialRoom: initialRoom), settings);
      case staffDirectory:
        return _buildRoute(const StaffDirectoryPage(), settings);
      case checkoutRequest:
        return _buildRoute(const CheckoutRequestPage(), settings);
      case checkoutReviewNoc:
        final payload = settings.arguments as CheckoutRequestPayload?;
        return _buildRoute(CheckoutReviewNocPage(payload: payload), settings);
      case checkoutStatus:
        return _buildRoute(const CheckoutStatusPage(), settings);
      case admissionPersonal:
        return _buildRoute(const PersonalDetailsPage(), settings);
      case admissionAddress:
        return _buildRoute(const AddressContactPage(), settings);
      case admissionDocuments:
        return _buildRoute(const DocumentUploadPage(), settings);
      case admissionAgreement:
        return _buildRoute(const AgreementSignaturePage(), settings);
      case admissionReview:
        return _buildRoute(const ReviewDetailsPage(), settings);
      case admissionConfirmed:
        return _buildRoute(const RoomConfirmationPage(), settings);
      default:
        return _buildRoute(
          Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
          settings,
        );
    }
  }

  static PageRouteBuilder _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }
}

