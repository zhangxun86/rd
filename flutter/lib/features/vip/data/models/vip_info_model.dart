// Model for the individual price list items
class PriceListItemModel {
  final int id;
  final String name;
  final String price;
  final String? tag;
  final String? note;
  final String? tipMsg;
  final String? tipUrl;

  PriceListItemModel({
    required this.id,
    required this.name,
    required this.price,
    this.tag,
    this.note,
    this.tipMsg,
    this.tipUrl
  });

  factory PriceListItemModel.fromJson(Map<String, dynamic> json) {
    return PriceListItemModel(
      id: json['id'] as int,
      name: json['name'] as String,
      price: json['price'] as String,
      tag: json['tag'] as String?,
      note: json['note'] as String?,
      tipMsg: json['tip_msg'] as String?,
      tipUrl: json['tip_url'] as String?,
    );
  }
}

// Model for the overall response data
class VipInfoModel {
  final List<PriceListItemModel> priceList;
  // Add other fields like vip_info, is_buy_vip if needed

  VipInfoModel({required this.priceList});

  factory VipInfoModel.fromJson(Map<String, dynamic> json) {
    var list = (json['price_list'] as List<dynamic>?) ?? [];
    List<PriceListItemModel> priceListItems = list.map((i) => PriceListItemModel.fromJson(i)).toList();

    return VipInfoModel(priceList: priceListItems);
  }
}