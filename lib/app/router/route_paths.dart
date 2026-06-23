class RoutePaths {
  const RoutePaths._();

  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const main = '/main';
  static const home = '/home';
  static const search = '/houses';
  static const houseList = '/house-list';
  static const houseSearch = '/house-search';
  static const houseSearchResult = '/house-search-result';
  static const houseFilter = '/house-filter';
  static const houseDetail = '/houses/:houseId';
  static const appointment = '/appointment';
  static const realNameAuth = '/real-name-auth';
  static const profile = '/profile';
  static const lease = '/leases';
  static const leaseDetail = ':leaseId';
  static const bill = '/bill';
  static const lock = '/lock';
  static const unlockRecords = '/locks/records';
  static const repair = '/repair';
  static const repairs = '/repairs';
  static const createRepair = '/repairs/create';
  static const repairRecords = '/repairs/records';
  static const repairDetail = '/repairs/:repairId';
  static const messageCenter = '/messages';
  static const customerService = '/customer-service';
  static const viewingAppointment = '/rental-flow/:houseId/viewing-appointment';
  static const viewingDetail = '/rental-flow/:houseId/viewing-detail';
  static const rentalApplication = '/rental-flow/:houseId/rental-application';
  static const realNameVerify = '/rental-flow/:houseId/real-name-verify';
  static const leaseContract = '/rental-flow/:houseId/lease-contract';
  static const rentalPayment = '/rental-flow/:houseId/payment';
  static const moveInComplete = '/rental-flow/:houseId/move-in-complete';
}
