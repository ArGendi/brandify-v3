enum Status{
  success,
  fail,
}

enum SellPlace{
  online,
  store,
  inEvent,
  other,
}

enum SocialMediaPlatform{
  facebook,
  instagram,
  tiktok,
  other,
}

enum PackageType{
  offline,
  online,
  shopify,
}

enum RegisterStatus{
  pass,
  backendError,
  missingParameters,
}

enum OrderDate{
  Today,
  Week,
  Month,
  ThreeMonths,
  SixMonths,
  Year,
  AllTime,
}

enum Privilege {
  viewSales,
  viewProfit,
  viewCostPrice,
  addProduct,
  editProduct,
  deleteProduct,
  viewReports,
  userManagement,
}

extension PrivilegeExtension on Privilege {
  String get asString {
    switch (this) {
      case Privilege.viewSales:
        return 'view_sales';
      case Privilege.viewProfit:
        return 'view_profit';
      case Privilege.viewCostPrice:
        return 'view_cost_price';
      case Privilege.addProduct:
        return 'add_product';
      case Privilege.editProduct:
        return 'edit_product';
      case Privilege.deleteProduct:
        return 'delete_product';
      case Privilege.viewReports:
        return 'view_reports';
      case Privilege.userManagement:
        return 'user_management';
    }
  }

  static Privilege? fromString(String value) {
    switch (value) {
      case 'view_sales':
        return Privilege.viewSales;
      case 'view_profit':
        return Privilege.viewProfit;
      case 'view_cost_price':
        return Privilege.viewCostPrice;
      case 'add_product':
        return Privilege.addProduct;
      case 'edit_product':
        return Privilege.editProduct;
      case 'delete_product':
        return Privilege.deleteProduct;
      case 'view_reports':
        return Privilege.viewReports;
      case 'user_management':
        return Privilege.userManagement;
      default:
        return null;
    }
  }
}