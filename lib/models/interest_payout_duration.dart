enum InterestPayoutDuration {
  immediately,
  per_tenure,
  on_maturity;

  String get displayName {
    switch (this) {
      case InterestPayoutDuration.immediately:
        return 'Immediate Payout';
      case InterestPayoutDuration.per_tenure:
        return 'Per Tenure Period';
      case InterestPayoutDuration.on_maturity:
        return 'On Maturity';
    }
  }
}