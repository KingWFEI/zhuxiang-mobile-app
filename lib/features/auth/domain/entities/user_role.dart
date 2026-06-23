enum UserRole {
  tenant('TENANT'),
  housekeeper('HOUSEKEEPER'),
  landlord('LANDLORD'),
  admin('ADMIN');

  const UserRole(this.code);

  final String code;

  static UserRole fromCode(String? code) {
    final normalized = code?.trim().toUpperCase();
    return switch (normalized) {
      'HOUSEKEEPER' => UserRole.housekeeper,
      'LANDLORD' => UserRole.landlord,
      'ADMIN' => UserRole.admin,
      'TENANT' || null || '' => UserRole.tenant,
      _ => UserRole.tenant,
    };
  }

  bool get usesTenantShell => this == UserRole.tenant;

  bool get usesStaffShell =>
      this == UserRole.housekeeper || this == UserRole.admin;

  bool get requiresWebAdmin => this == UserRole.landlord;
}
