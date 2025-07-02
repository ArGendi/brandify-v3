import 'package:brandify/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Cache{
  static late SharedPreferences sharedPreferences;

  static Future<void> init() async{
    sharedPreferences = await SharedPreferences.getInstance();
  }

  static Future<void> setUserId(int value) async{
    await sharedPreferences.setInt("userId", value);
  }

  static int? getUserId(){
    return sharedPreferences.getInt("userId");
  }

  static Future<void> setTotal(int value) async{
    await sharedPreferences.setInt("total", value);
  }

  static int? getTotal(){
    return sharedPreferences.getInt("total");
  }

  static Future<void> setProfit(int value) async{
    await sharedPreferences.setInt("profit", value);
  }

  static int? getProfit(){
    return sharedPreferences.getInt("profit");
  }

  static Future<void> setPackageType(String value) async{
    await sharedPreferences.setString("packageType", value);
  }

  static String? getPackageType(){
    return sharedPreferences.getString("packageType");
  }

  static Future<void> setName(String value) async{
    await sharedPreferences.setString("name", value);
  }

  static String? getName(){
    return sharedPreferences.getString("name");
  }

  static Future<void> setPhone(String value) async{
    await sharedPreferences.setString("phone", value);
  }

  static String? getPhone(){
    return sharedPreferences.getString("phone");
  }

  static Future<void> clear() async{
    String? languageCode = sharedPreferences.getString('languageCode');
    await sharedPreferences.clear();
    if (languageCode != null) {
      await sharedPreferences.setString('languageCode', languageCode);
    }
  }

  // Total Orders
    static Future<void> setTotalOrders(int value) async{
      sharedPreferences.setInt('totalOrders', value);
    }
  
    static int? getTotalOrders() {
      return sharedPreferences.getInt('totalOrders');
    }
  
    // Total Profit
    static Future<void> setTotalProfit(int value) async{
      sharedPreferences.setInt('totalProfit', value);
    }
  
    static int? getTotalProfit() {
      return sharedPreferences.getInt('totalProfit');
    }
    
  
  static Future<void> setInitialUserData({
    required String name,
    required String email,
    
    String packageType = PACKAGE_TYPE_ONLINE,
    int total = 0,
    int totalProfit = 0,
    int totalOrders = 0,
  }) async{
    setName(name);
    setEmail(email);
    setPackageType(packageType);
    setTotal(total);
    setTotalProfit(totalProfit);
    setTotalOrders(totalOrders);
  }

  static Future<void> setLanguage(String languageCode) async{
    sharedPreferences.setString('languageCode', languageCode);
  }
  
  static String? getLanguage(){
    return sharedPreferences.getString('languageCode');
  }

  static Future<void> setBool(String key, bool value) async {
    await sharedPreferences.setBool(key, value);
  }

  static bool? getBool(String key) {
    return sharedPreferences.getBool(key);
  }

  static String? getEmail() {
    return sharedPreferences.getString("email");
  }

  static Future<void> setEmail(String value) async {
    await sharedPreferences.setString("email", value);
  }
}