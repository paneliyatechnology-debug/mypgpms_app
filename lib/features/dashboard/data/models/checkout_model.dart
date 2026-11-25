/// Request payload for submitting a stay checkout request.
class CheckoutRequestPayload {
  final String departureDate; // Format: YYYY-MM-DD
  final String reason;
  final String? additionalNotes;

  CheckoutRequestPayload({
    required this.departureDate,
    required this.reason,
    this.additionalNotes,
  });

  Map<String, dynamic> toJson() {
    return {
      'departure_date': departureDate,
      'reason': reason,
      if (additionalNotes != null && additionalNotes!.trim().isNotEmpty)
        'additional_notes': additionalNotes!.trim(),
    };
  }

  factory CheckoutRequestPayload.fromJson(Map<String, dynamic> json) {
    return CheckoutRequestPayload(
      departureDate: json['departure_date']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      additionalNotes: json['additional_notes']?.toString(),
    );
  }
}
