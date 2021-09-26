import 'package:flutter/material.dart';
import 'package:komodo_dex/blocs/dialog_bloc.dart';
import 'package:komodo_dex/blocs/settings_bloc.dart';
import 'package:komodo_dex/localizations.dart';
import 'package:komodo_dex/model/cex_provider.dart';
import 'package:komodo_dex/model/rewards_provider.dart';
import 'package:komodo_dex/screens/authentification/lock_screen.dart';
import 'package:komodo_dex/utils/utils.dart';
import 'package:komodo_dex/widgets/cex_data_marker.dart';
import 'package:komodo_dex/widgets/primary_button.dart';
import 'package:komodo_dex/widgets/secondary_button.dart';
import 'package:komodo_dex/app_config/theme_data.dart';
import 'package:provider/provider.dart';

class RewardsPage extends StatefulWidget {
  @override
  _RewardsPageState createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  RewardsProvider rewardsProvider;

  @override
  Widget build(BuildContext context) {
    rewardsProvider = Provider.of<RewardsProvider>(context);
    final List<RewardsItem> rewards = rewardsProvider.rewards;

    return LockScreen(
      context: context,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).rewardsTitle),
        ),
        backgroundColor: Theme.of(context).backgroundColor,
        body: rewards == null
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  rewardsProvider.update();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(
                    child: Column(
                      children: <Widget>[
                        rewardsProvider.updateInProgress
                            ? const SizedBox(
                                height: 1,
                                child: LinearProgressIndicator(),
                              )
                            : Container(height: 1),
                        _buildHeader(),
                        _buildButtons(),
                        _buildLink(),
                        _buildTable(),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    if (rewardsProvider.errorMessage == null) return Container();

    return Container(
      alignment: const Alignment(0, 0),
      height: 36,
      child: Text(
        rewardsProvider.errorMessage,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.pink),
      ),
    );
  }

  Widget _buildLink() {
    return Container(
      child: InkWell(
        onTap: () {
          launchURL('https://support.komodoplatform.com/support/'
              'solutions/articles/'
              '29000024428-komodo-5-active-user-reward-all-you-need-to-know');
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              Text(
                AppLocalizations.of(context).rewardsReadMore,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.open_in_new,
                size: 12,
                color: Colors.blue,
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButtons() {
    final double total = rewardsProvider.total;
    return Container(
      padding: const EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: 24,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: SecondaryButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                text: AppLocalizations.of(context).rewardsCancel),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Opacity(
            opacity: total <= 0 || rewardsProvider.claimInProgress ? 0.6 : 1,
            child: PrimaryButton(
              onPressed: total <= 0 || rewardsProvider.claimInProgress
                  ? null
                  : () {
                      rewardsProvider.receive();
                    },
              text: AppLocalizations.of(context).rewardsReceive,
              backgroundColor: const Color.fromARGB(255, 1, 102, 129),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final double total = rewardsProvider.total;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 170,
      child: Column(
        children: <Widget>[
          const SizedBox(height: 40),
          SizedBox(width: 50, child: Image.asset('assets/coin-icons/kmd.png')),
          const SizedBox(height: 8),
          rewardsProvider.errorMessage == null &&
                  rewardsProvider.successMessage != null
              ? Container(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    rewardsProvider.successMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.green),
                  ),
                )
              : total > 0
                  ? Column(
                      children: <Widget>[
                        Text(
                          'KMD ${formatPrice(total)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Builder(builder: (context) {
                          final cexProvider =
                              Provider.of<CexProvider>(context, listen: false);
                          final double price = cexProvider.getUsdPrice('KMD');

                          final amountUsd = total * price;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CexMarker(
                                context,
                                size: const Size.fromHeight(12),
                                color: settingsBloc.isLightTheme
                                    ? cexColorLight
                                    : cexColor,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                cexProvider.convert(amountUsd),
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle2
                                    .copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w100,
                                    ),
                              ),
                            ],
                          );
                        }),
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 2,
                          height: 1,
                          child: rewardsProvider.claimInProgress
                              ? const LinearProgressIndicator()
                              : Container(),
                        )
                      ],
                    )
                  : Container(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        AppLocalizations.of(context).noRewards,
                      ),
                    ),
          _buildErrorMessage(),
        ],
      ),
    );
  }

  Widget _buildTable() {
    final List<TableRow> rows = [];
    for (int i = 0; i < rewardsProvider.rewards.length; i++) {
      final RewardsItem item = rewardsProvider.rewards[i];
      rows.add(_buildTableRow(i, item));
    }

    if (rows.isEmpty) return Container();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: 4,
          ),
          child: Text(
            AppLocalizations.of(context).rewardsTableTitle,
            style: Theme.of(context).textTheme.bodyText1,
          ),
        ),
        Table(
          border: TableBorder.all(color: Colors.white.withAlpha(15)),
          columnWidths: const {
            0: IntrinsicColumnWidth(),
            3: IntrinsicColumnWidth(),
            4: IntrinsicColumnWidth(),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(
                  border: Border(
                bottom: BorderSide(
                  color: Colors.white.withAlpha(15),
                ),
              )),
              children: [
                Container(
                  padding: const EdgeInsets.only(
                      left: 12, right: 8, top: 8, bottom: 8),
                  child: Text(
                    AppLocalizations.of(context).rewardsTableUXTO,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(
                      left: 8, right: 8, top: 8, bottom: 8),
                  child: Text(
                    AppLocalizations.of(context).rewardsTableRewards,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(
                      left: 8, right: 8, top: 8, bottom: 8),
                  child: Text(
                    AppLocalizations.of(context).rewardsTableFiat,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  alignment: const Alignment(0, 0),
                  padding: const EdgeInsets.only(
                      left: 8, right: 8, top: 8, bottom: 8),
                  child: Text(
                    AppLocalizations.of(context).rewardsTableTime,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(
                      left: 8, right: 12, top: 8, bottom: 8),
                  alignment: const Alignment(0, 0),
                  child: Text(
                    AppLocalizations.of(context).rewardsTableStatus,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            ...rows,
          ],
        ),
      ],
    );
  }

  TableRow _buildTableRow(int i, RewardsItem item) {
    return TableRow(
        decoration: BoxDecoration(
          color: i % 2 == 0 ? Colors.black.withAlpha(25) : null,
        ),
        children: [
          Container(
            padding:
                const EdgeInsets.only(left: 12, right: 8, top: 12, bottom: 12),
            child: Text(
              formatPrice(item.amount, 4),
              maxLines: 1,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          item.reward == null
              ? Container(
                  padding: const EdgeInsets.only(
                      left: 8, right: 8, top: 12, bottom: 12),
                  child: const Text(
                    '-',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                )
              : Container(
                  color: const Color.fromARGB(60, 1, 102, 129),
                  padding: const EdgeInsets.only(
                      left: 8, right: 8, top: 12, bottom: 12),
                  child: Text(
                    formatPrice(item.reward, 4),
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
          item.reward == null
              ? Container(
                  padding: const EdgeInsets.only(
                      left: 8, right: 8, top: 12, bottom: 12),
                  child: const Text(
                    '-',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                )
              : Builder(builder: (context) {
                  final cexProvider =
                      Provider.of<CexProvider>(context, listen: false);
                  final double price = cexProvider.getUsdPrice('KMD');

                  final amountUsd = item.reward * price;
                  return Container(
                    color: const Color.fromARGB(60, 1, 102, 129),
                    padding: const EdgeInsets.only(
                        left: 8, right: 8, top: 12, bottom: 12),
                    child: Row(
                      children: [
                        CexMarker(
                          context,
                          size: const Size.fromHeight(12),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          cexProvider.convert(amountUsd),
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
          Container(
            alignment: const Alignment(0, 0),
            padding:
                const EdgeInsets.only(left: 8, right: 8, top: 12, bottom: 12),
            child: item.stopAt == null || item.stopAt == null
                ? Container()
                : Builder(builder: (context) {
                    final duration = Duration(
                        milliseconds: item.stopAt * 1000 -
                            DateTime.now().millisecondsSinceEpoch);

                    return Text(
                      _formatTimeLeft(duration),
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 13,
                        color: duration.inDays < 2 ? Colors.orange : null,
                      ),
                    );
                  }),
          ),
          item.reward != null
              ? Container(
                  alignment: const Alignment(1, 0),
                  padding: const EdgeInsets.only(
                      left: 8, right: 12, top: 12, bottom: 12),
                  child: Icon(
                    Icons.check_circle,
                    size: 14,
                    color: const Color.fromARGB(255, 1, 102, 129),
                  ),
                )
              : TableRowInkWell(
                  onTap: () {
                    _showStatusHint(item);
                  },
                  child: Container(
                    alignment: const Alignment(1, 0),
                    padding: const EdgeInsets.only(
                        left: 8, right: 12, top: 12, bottom: 12),
                    child: Text(
                      item.error['short'],
                      maxLines: 1,
                      style: TextStyle(
                        color: Theme.of(context).hintColor.withAlpha(150),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
        ]);
  }

  void _showStatusHint(RewardsItem item) {
    dialogBloc.dialog = showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context).rewardsPopupTitle),
            contentPadding: const EdgeInsets.only(
              left: 25,
              right: 25,
              top: 25,
              bottom: 15,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(item.error['long']),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    RaisedButton(
                      onPressed: () {
                        dialogBloc.closeDialog(context);
                      },
                      child: Text(AppLocalizations.of(context).rewardsPopupOk),
                    )
                  ],
                )
              ],
            ),
          );
        }).then((dynamic _) => dialogBloc.dialog = null);
  }

  String _formatTimeLeft(Duration duration) {
    final int dd = duration.inDays;
    final int hh = duration.inHours;
    final int mm = duration.inMinutes;

    if (dd > 0) {
      return AppLocalizations.of(context).rewardsTimeDays(dd);
    }
    if (hh > 0) {
      String minutes = mm.remainder(60).toString();
      if (minutes.length < 2) minutes = '0$minutes';
      return AppLocalizations.of(context).rewardsTimeHours(hh, minutes);
    }
    if (mm > 0) {
      return AppLocalizations.of(context).rewardsTimeMin(mm);
    }
    return '-';
  }
}
