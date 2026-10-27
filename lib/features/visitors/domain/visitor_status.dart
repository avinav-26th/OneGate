enum VisitorStatus {
  registered('Registered'),
  checkedIn('Checked In'),
  checkedOut('Checked Out');

  final String label;
  const VisitorStatus(this.label);

  static VisitorStatus fromString(String? value) {
    if (value == null) return VisitorStatus.registered;
    final normalized = value.trim().toLowerCase();
    if (normalized == 'checked in' || normalized == 'checkedin') {
      return VisitorStatus.checkedIn;
    }
    if (normalized == 'checked out' || normalized == 'checkedout') {
      return VisitorStatus.checkedOut;
    }
    return VisitorStatus.registered;
  }

  String toApiString() => label;
}
