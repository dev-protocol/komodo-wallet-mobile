import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:komodo_dex/blocs/coins_bloc.dart';
import 'package:komodo_dex/blocs/main_bloc.dart';
import 'package:komodo_dex/blocs/settings_bloc.dart';
import 'package:komodo_dex/localizations.dart';
import 'package:komodo_dex/model/cex_provider.dart';
import 'package:komodo_dex/model/coin_balance.dart';
import 'package:komodo_dex/model/transaction_data.dart';
import 'package:komodo_dex/screens/authentification/lock_screen.dart';
import 'package:komodo_dex/services/db/database.dart';
import 'package:komodo_dex/utils/utils.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';
import 'package:komodo_dex/model/addressbook_provider.dart';
import 'package:komodo_dex/screens/addressbook/addressbook_page.dart';

class TransactionDetail extends StatefulWidget {
  const TransactionDetail({this.transaction, this.coinBalance});

  final Transaction transaction;
  final CoinBalance coinBalance;

  @override
  _TransactionDetailState createState() => _TransactionDetailState();
}

class _TransactionDetailState extends State<TransactionDetail> {
  @override
  void dispose() {
    mainBloc.isUrlLaucherIsOpen = false;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LockScreen(
      context: context,
      child: Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        appBar: AppBar(
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.share),
              onPressed: () {
                final String fromOrTo = double.parse(
                            widget.transaction.myBalanceChange) >
                        0
                    ? '${AppLocalizations.of(context).from}: ${widget.transaction.from[0]}'
                    : '${AppLocalizations.of(context).to} ${widget.transaction.to.length > 1 ? widget.transaction.to[1] : widget.transaction.to[0]}';
                String fee = '';
                if (widget.transaction.feeDetails != null &&
                    widget.transaction.feeDetails.amount != null) {
                  fee = widget.transaction.feeDetails.amount.toString();
                }
                final String dataToShare =
                    'Transaction detail:\nAmount: ${widget.transaction.myBalanceChange} ${widget.transaction.coin}\nDate: ${widget.transaction.getTimeFormat()}\nBlock: ${widget.transaction.blockHeight}\nConfirmations: ${widget.transaction.confirmations}\nFee: $fee ${widget.transaction.coin}\n$fromOrTo\nTx Hash: ${widget.transaction.txHash}';
                mainBloc.isUrlLaucherIsOpen = true;

                Share.share(dataToShare);
              },
            ),
            IconButton(
              icon: Icon(Icons.open_in_browser),
              onPressed: () {
                String urlPostTx = 'tx/';
                if (widget.coinBalance.coin.swapContractAddress.isNotEmpty) {
                  urlPostTx = 'tx/0x';
                }
                launchURL(widget.coinBalance.coin.explorerUrl[0] +
                    urlPostTx +
                    widget.transaction.txHash);
              },
            )
          ],
          elevation: 0,
        ),
        body: ListView(
          children: <Widget>[_buildHeader(), _buildListDetails()],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final Transaction tx = widget.transaction;
    return Container(
      height: 200,
      color: Theme.of(context).primaryColor,
      child: Column(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: StreamBuilder<bool>(
                          initialData: settingsBloc.showBalance,
                          stream: settingsBloc.outShowBalance,
                          builder: (BuildContext context,
                              AsyncSnapshot<bool> snapshot) {
                            final amount = deci(tx.myBalanceChange);
                            String amountString = deci2s(amount);
                            if (snapshot.hasData && snapshot.data == false) {
                              amountString =
                                  (amount < deci(0) ? '-' : '') + '**.**';
                            }
                            return AutoSizeText(
                              '$amountString ${tx.coin}',
                              style: Theme.of(context).textTheme.title,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                            );
                          }),
                    ),
                  ),
                  _buildUsdAmount(),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  tx.getTimeFormat(),
                  style: Theme.of(context).textTheme.body2,
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                    color: tx.confirmations > 0
                        ? Colors.lightGreen
                        : Colors.red.shade500,
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: tx.confirmations > 0
                      ? Text(AppLocalizations.of(context).txConfirmed)
                      : Text(AppLocalizations.of(context).txNotConfirmed),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildUsdAmount() {
    final CexProvider cexProvider = Provider.of<CexProvider>(context);

    const Widget _progressIndicator = SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(
        strokeWidth: 2.0,
      ),
    );

    Widget _usdAmount(String priceForOne) {
      if (priceForOne == null) return _progressIndicator;

      if (double.parse(priceForOne) == 0) return Container();

      return StreamBuilder<bool>(
          initialData: settingsBloc.showBalance,
          stream: settingsBloc.outShowBalance,
          builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
            bool hidden = false;
            final double amount = double.parse(priceForOne) *
                double.parse(widget.transaction.myBalanceChange);
            if (snapshot.hasData && snapshot.data == false) hidden = true;

            return Text(
              cexProvider.convert(amount, hidden: hidden),
              style: Theme.of(context).textTheme.body2,
            );
          });
    }

    if (widget.coinBalance.priceForOne != null)
      return _usdAmount(widget.coinBalance.priceForOne);

    return StreamBuilder(
        stream: coinsBloc.outCoins,
        builder:
            (BuildContext context, AsyncSnapshot<List<CoinBalance>> snapshot) {
          if (!snapshot.hasData) return _progressIndicator;

          String priceForOne;
          try {
            priceForOne = snapshot.data
                .firstWhere((CoinBalance balance) =>
                    balance.coin.abbr == widget.coinBalance.coin.abbr)
                .priceForOne;
          } catch (_) {}

          return _usdAmount(priceForOne);
        });
  }

  Widget _buildListDetails() {
    return Column(
      children: <Widget>[
        widget.transaction.blockHeight > 0
            ? ItemTransationDetail(
                title: AppLocalizations.of(context).txBlock,
                data: widget.transaction.blockHeight.toString())
            : Container(),
        ItemTransationDetail(
            title: AppLocalizations.of(context).txConfirmations,
            data: widget.transaction.confirmations.toString()),
        ItemTransationDetail(
            title: AppLocalizations.of(context).txFee, data: _getFee()),
        double.parse(widget.transaction.myBalanceChange) > 0
            ? ItemTransationDetail(
                title: AppLocalizations.of(context).from,
                data: widget.transaction.from[0])
            : ItemTransationDetail(
                title: AppLocalizations.of(context).to,
                data: widget.transaction.getToAddress().isNotEmpty
                    ? widget.transaction.getToAddress()[0]
                    : ''),
        ItemTransationDetail(title: 'Tx Hash', data: widget.transaction.txHash),
        ItemTransactionNote(title: 'Note', txHash: widget.transaction.txHash),
      ],
    );
  }

  String _getFee() {
    String fee = '';

    if (widget.transaction.feeDetails.amount == null ||
        widget.transaction.feeDetails.amount.isEmpty) {
      fee = widget.transaction.feeDetails?.totalFee.toString();
    } else {
      fee = widget.transaction.feeDetails?.amount.toString();
    }

    if (widget.coinBalance.coin.swapContractAddress.isNotEmpty) {
      return fee + ' ETH';
    } else {
      return fee + ' ' + widget.transaction.coin;
    }
  }
}

class ItemTransationDetail extends StatelessWidget {
  const ItemTransationDetail({this.title, this.data});

  final String title;
  final String data;

  @override
  Widget build(BuildContext context) {
    final AddressBookProvider addressBookProvider =
        Provider.of<AddressBookProvider>(context);
    final Contact contact = addressBookProvider.contactByAddress(data);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.subtitle,
          ),
          const SizedBox(
            width: 16,
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                if (contact == null) {
                  copyToClipBoard(context, data);
                } else {
                  Navigator.push<dynamic>(
                      context,
                      MaterialPageRoute<dynamic>(
                        builder: (BuildContext context) => AddressBookPage(
                          contact: contact,
                        ),
                      ));
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: contact == null
                    ? AutoSizeText(
                        data,
                        style: Theme.of(context).textTheme.body2,
                        textAlign: TextAlign.end,
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Icon(
                            Icons.account_circle,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          AutoSizeText(
                            contact.name,
                            style: Theme.of(context).textTheme.body2.copyWith(
                                  color: Colors.white,
                                ),
                          )
                        ],
                      ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class ItemTransactionNote extends StatefulWidget {
  const ItemTransactionNote({
    @required this.title,
    @required this.txHash,
  }) : assert(txHash != null);

  final String title;
  final String txHash;

  @override
  _ItemTransactionNoteState createState() => _ItemTransactionNoteState();
}

class _ItemTransactionNoteState extends State<ItemTransactionNote> {
  String noteText;
  final noteTextController = TextEditingController();
  bool isEdit = false;

  @override
  void initState() {
    super.initState();
    Db.getNote(widget.txHash).then((n) {
      setState(() {
        noteText = n;
        noteTextController.text = noteText;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            widget.title,
            style: Theme.of(context).textTheme.subtitle,
          ),
          const SizedBox(
            width: 16,
          ),
          Expanded(
            child: isEdit
                ? TextField(
                    controller: noteTextController,
                  )
                : InkWell(
                    onTap: () {
                      if (noteText != null && noteText.isNotEmpty)
                        copyToClipBoard(context, noteText);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: AutoSizeText(
                        (noteText == null || noteText.isEmpty)
                            ? 'Add a Note'
                            : noteText,
                        style: Theme.of(context).textTheme.body2,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ),
          ),
          IconButton(
            icon: Icon(isEdit ? Icons.check : Icons.edit),
            onPressed: () {
              setState(
                () {
                  if (isEdit) {
                    noteTextController.text = noteTextController.text.trim();
                    noteText = noteTextController.text;
                    Db.saveNote(
                        widget.txHash, noteText.isNotEmpty ? noteText : null);
                  }
                  isEdit = !isEdit;
                },
              );
            },
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    noteTextController.dispose();
    super.dispose();
  }
}
