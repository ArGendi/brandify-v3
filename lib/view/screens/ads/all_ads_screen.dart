import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:brandify/constants.dart';
import 'package:brandify/cubits/ads/ads_cubit.dart';
import 'package:brandify/models/ad.dart';
import 'package:brandify/view/screens/ads/ads_screen.dart';
import 'package:brandify/view/widgets/ad_item.dart';
import 'package:brandify/view/widgets/platform_totals_card.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:brandify/view/widgets/detail_row.dart';

class AllAdsScreen extends StatefulWidget {
  const AllAdsScreen({super.key});

  @override
  State<AllAdsScreen> createState() => _AllAdsScreenState();
}

class _AllAdsScreenState extends State<AllAdsScreen> {
  DateTimeRange? selectedDateRange;

  @override
  void initState() {
    super.initState();
    AdsCubit.get(context).getAllAds().then((_) {
      AdsCubit.get(context).sortAdsByDate(descending: true);
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: selectedDateRange ?? DateTimeRange(
        start: DateTime.now().subtract(Duration(days: 7)),
        end: DateTime.now(),
      ),
    );
    if (picked != null) {
      setState(() {
        selectedDateRange = picked;
      });
      AdsCubit.get(context).filterAdsByDate(picked.start, picked.end);
    }
  }

  Widget _buildPlatformTotals() {
    final ads = AdsCubit.get(context).filteredAds;
    final platformTotals = <String, double>{};
    
    for (var ad in ads) {
      if (ad.platform?.name != null) {
        platformTotals[ad.platform!.name] = (platformTotals[ad.platform!.name] ?? 0) + (ad.cost ?? 0);
      }
    }

    return PlatformTotalsCard(platformTotals: platformTotals);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.ads,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: mainColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          // gradient: LinearGradient(
          //   begin: Alignment.topCenter,
          //   end: Alignment.bottomCenter,
          //   colors: [mainColor, Color(0xFFF5F5F5)],
          //   stops: [0.0, 0.3],
          // ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: BlocBuilder<AdsCubit, AdsState>(
            builder: (context, state) {
              return Visibility(
                visible: AdsCubit.get(context).ads.isNotEmpty,
                replacement: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        FontAwesomeIcons.bullhorn,
                        color: Colors.grey,
                        size: 50,
                      ),
                      // Image.asset(
                      //   "assets/images/empty.png",
                      //   height: 200, 
                      // ),
                      const SizedBox(
                        height: 20,
                      ),
                       Text(
                        AppLocalizations.of(context)!.noAdsDesc,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          //fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      // Text(
                      //   "No Ads Yet",
                      //   style: TextStyle(
                      //     fontSize: 18,
                      //     fontWeight: FontWeight.w500,
                      //     color: Colors.grey[600],
                      //   ),
                      // )
                    ],
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (selectedDateRange != null)
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.date_range, color: mainColor, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${AppLocalizations.of(context)!.from} ${DateFormat('MMM d, y').format(selectedDateRange!.start)} ${AppLocalizations.of(context)!.to} ${DateFormat('MMM d, y').format(selectedDateRange!.end)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: 20),
                      _buildPlatformTotals(),
                      SizedBox(height: 20),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemBuilder: (context, i) {
                          if(i < AdsCubit.get(context).filteredAds.length){
                            return Row(
                              children: [
                                Expanded(
                                  child: AdItem(
                                    ad: AdsCubit.get(context).filteredAds[i],
                                    color: AdsCubit.get(context).getAdColor(AdsCubit.get(context).filteredAds[i]),
                                    icon: AdsCubit.get(context).getAdIcon(AdsCubit.get(context).filteredAds[i]),
                                    onTap: context.read<AdsCubit>().showEnhancedAdDetails,
                                  ),
                                ),
                                SizedBox(width: 5),
                                IconButton(
                                  onPressed: () async {
                                    final confirmed = await showModalBottomSheet<bool>(
                                      context: context,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                        ),
                                        padding: EdgeInsets.all(20),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 4,
                                              margin: EdgeInsets.only(bottom: 20),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[300],
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                            ),
                                            Text(
                                              AppLocalizations.of(context)!.deleteAdvertisement,
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red,
                                              ),
                                            ),
                                            SizedBox(height: 15),
                                            Text(
                                              AppLocalizations.of(context)!.deleteAdConfirm,
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                            SizedBox(height: 25),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: OutlinedButton(
                                                    onPressed: () => Navigator.pop(context, false),
                                                    style: OutlinedButton.styleFrom(
                                                      padding: EdgeInsets.symmetric(vertical: 15),
                                                      side: BorderSide(color: Colors.grey),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                    ),
                                                    child: Text(AppLocalizations.of(context)!.cancel),
                                                  ),
                                                ),
                                                SizedBox(width: 15),
                                                Expanded(
                                                  child: ElevatedButton(
                                                    onPressed: () => Navigator.pop(context, true),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.red,
                                                      foregroundColor: Colors.white,
                                                      padding: EdgeInsets.symmetric(vertical: 15),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                    ),
                                                    child: Text(AppLocalizations.of(context)!.delete),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                    
                                    if (confirmed == true) {
                                      await AdsCubit.get(context).deleteAd(context, AdsCubit.get(context).filteredAds[i]);
                                    }
                                  }, 
                                  icon: Icon(Icons.delete_outline, color: Colors.red),
                                )
                              ],
                            );
                          }
                          else{
                            return SizedBox(height: 50);
                          }
                        },
                        separatorBuilder: (context, i) => SizedBox(height: 12),
                        itemCount: AdsCubit.get(context).filteredAds.length + 1,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AdsScreen())
          );
        },
        label: Text(AppLocalizations.of(context)!.newAd, style: TextStyle(fontWeight: FontWeight.w600)),
        icon: Icon(Icons.add),
        backgroundColor: mainColor,
        elevation: 4,
      ),
    );
  }

  void _showEnhancedAdDetails(BuildContext context, Ad ad) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              AppLocalizations.of(context)!.advertisementDetails,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: mainColor,
              ),
            ),
            SizedBox(height: 20),
            DetailRow(
              icon: Icons.campaign,
              label: AppLocalizations.of(context)!.platform,
              value: ad.platform?.name ?? AppLocalizations.of(context)!.notAvailable,
            ),
            DetailRow(
              icon: Icons.attach_money,
              label: AppLocalizations.of(context)!.cost,
              value: "${AppLocalizations.of(context)!.currency(ad.cost ?? 0)}",
            ),
            DetailRow(
              icon: Icons.calendar_today,
              label: AppLocalizations.of(context)!.date,
              value: ad.date.toString().split(" ").first,
            ),
            if(ad.description != null) 
              DetailRow(
                icon: Icons.description,
                label: AppLocalizations.of(context)!.descriptionLabel,
                value: ad.description ?? "",
              ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(AppLocalizations.of(context)!.close, style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
