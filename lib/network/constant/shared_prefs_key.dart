class SharedPrefsKey{
  const SharedPrefsKey._();

  static const String isToCacheKey = "isToCache";
  static const String isToRefreshKey = "isToRefresh";
  static const String expiryDurationInDaysKey = "expiryDurationInDays";

  // used on map
  static const String expiryDateMapKey = "expiryDate";
  static const String dataMapKey = "data";
}