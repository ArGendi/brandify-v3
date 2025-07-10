import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:brandify/constants.dart';
import 'package:brandify/cubits/extra_expenses/extra_expenses_cubit.dart';
import 'package:brandify/main.dart';
import 'package:brandify/models/extra_expense.dart';
import 'package:brandify/view/widgets/custom_button.dart';
import 'package:brandify/view/widgets/custom_texfield.dart';
import 'package:brandify/view/widgets/expense_item.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:brandify/view/widgets/detail_row.dart';

class ExtraExpensesScreen extends StatefulWidget {
  const ExtraExpensesScreen({super.key});

  @override
  State<ExtraExpensesScreen> createState() => _ExtraExpensesScreenState();
}

class _ExtraExpensesScreenState extends State<ExtraExpensesScreen> {
  DateTimeRange? selectedDateRange;

  @override
  void initState() {
    super.initState();
    ExtraExpensesCubit.get(context).getAllExpenses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.businessExpenses,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: mainColor, 
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: Icon(Icons.sort),
            onPressed: _showSortOptions,
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[50],
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: BlocBuilder<ExtraExpensesCubit, ExtraExpensesState>(
            builder: (context, state) {
              if (state is ExtraExpensesLoading) {
                return Center(
                  child: CircularProgressIndicator(
                    color: mainColor,
                    strokeWidth: 3,
                  )
                );
              }
              return Visibility(
                visible: ExtraExpensesCubit.get(context).expenses.isNotEmpty,
                replacement: _buildEmptyState(),
                child: Column(
                  children: [
                    if (selectedDateRange != null)
                      _buildDateRangeCard(),
                    SizedBox(height: 15),
                    _buildTotalExpensesCard(),
                    SizedBox(height: 20),
                    Expanded(
                      child: _buildExpensesList(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _AddBottomSheet(context),
        label: Text(AppLocalizations.of(context)!.addOrderExpense, 
          style: TextStyle(fontWeight: FontWeight.w600)),
        icon: Icon(Icons.add),
        backgroundColor: mainColor,
        elevation: 4,
      ),
    );
  }

  double _calculateTotalExpenses() {
    return ExtraExpensesCubit.get(context).expenses.fold(
      0,
      (sum, expense) => sum + (expense.price ?? 0),
    );
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
      ExtraExpensesCubit.get(context).filterExpensesByDate(picked.start, picked.end);
    }
  }

  Future<void> _AddBottomSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      isScrollControlled: true,
      context: context,
      builder: (_) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              top: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Form(
              key: ExtraExpensesCubit.get(context).formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextFormField(
                          text: AppLocalizations.of(context)!.expenseName,
                          hintText: AppLocalizations.of(context)!.electricityExample,
                          onSaved: (value) {
                            if (value!.isNotEmpty)
                              ExtraExpensesCubit.get(context).name = value;
                          },
                          onValidate: (value) {
                            if (value!.isEmpty) {
                              return AppLocalizations.of(context)!.enterName;
                            } else
                              return null;
                          },
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: CustomTextFormField(
                          keyboardType: TextInputType.number,
                          text: AppLocalizations.of(context)!.price,
                          hintText: AppLocalizations.of(context)!.priceHint,
                          onSaved: (value) {
                            if (value!.isNotEmpty)
                              ExtraExpensesCubit.get(context).price =
                                  int.parse(value);
                          },
                          onValidate: (value) {
                            if (value!.isEmpty) {
                              return AppLocalizations.of(context)!.enterPrice;
                            } else
                              return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  BlocBuilder<ExtraExpensesCubit, ExtraExpensesState>(
                    builder: (context, state) {
                      if (state is LoadingAddExtraExpenseState) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      } else {
                        return CustomButton(
                          text: AppLocalizations.of(context)!.add,
                          onPressed: () async {
                            bool done = await ExtraExpensesCubit.get(context)
                                .onAddSide(context);
                            if (done) navigatorKey.currentState?.pop();
                          },
                          bgColor: mainColor,  
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void showExpenseDetails(BuildContext context, ExtraExpense expense, int index) {
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
              'Expense Details', // Replace with AppLocalizations if available
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: mainColor,
              ),
            ),
            SizedBox(height: 20),
            DetailRow(
              icon: Icons.label,
              label: 'Name', // Replace with AppLocalizations if available
              value: expense.name ?? '',
            ),
            DetailRow(
              icon: Icons.attach_money,
              label: 'Amount', // Replace with AppLocalizations if available
              value: expense.price?.toString() ?? '',
            ),
            DetailRow(
              icon: Icons.calendar_today,
              label: 'Date', // Replace with AppLocalizations if available
              value: expense.date?.toString().split(' ')[0] ?? '',
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
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
                    child: Text('Close', style: TextStyle(fontSize: 16)), // Replace with AppLocalizations if available
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ExtraExpensesCubit.get(context).deleteExpense(index);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text('Delete', style: TextStyle(fontSize: 16)), // Replace with AppLocalizations if available
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onPressed) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white24,
            width: 1,
          ),
        ),
        child: IconButton(
          icon: Icon(icon, color: Colors.white, size: 20),
          onPressed: onPressed,
        ),
      );
    }

    Widget _buildEmptyState() {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.money_off, size: 50, color: Colors.grey),
            // Image.asset(
            //     "assets/images/empty.png",
            //     height: 200, 
            //   ),
            const SizedBox(
              height: 20,
            ),
             Text(
              AppLocalizations.of(context)!.noExpensesDesc,
              textAlign: TextAlign.center,
              style: TextStyle(
                //fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildDateRangeCard() {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '${AppLocalizations.of(context)!.from} ${selectedDateRange!.start.toString().split(' ')[0]} ${AppLocalizations.of(context)!.to} ${selectedDateRange!.end.toString().split(' ')[0]}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildTotalExpensesCard() {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.totalExpenses,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${AppLocalizations.of(context)!.currency(_calculateTotalExpenses())}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: mainColor,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                // Container(
                //   padding: EdgeInsets.all(12),
                //   decoration: BoxDecoration(
                //     color: Colors.red.shade50,
                //     borderRadius: BorderRadius.circular(12),
                //   ),
                //   child: Icon(
                //     Icons.receipt_outlined,
                //     color: Colors.red.shade700,
                //     size: 24,
                //   ),
                // ),
                // SizedBox(width: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: mainColor.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () async {
                      try {
                        final expenses = ExtraExpensesCubit.get(context).expenses;
                        if (expenses.isEmpty) return;
                        
                        final total = _calculateTotalExpenses();
                        final pdf = pw.Document();
                        
                        pdf.addPage(
                          pw.MultiPage(
                            pageTheme: pw.PageTheme(
                              pageFormat: PdfPageFormat.a4,
                              margin: pw.EdgeInsets.all(32),
                              theme: pw.ThemeData.withFont(
                                base: pw.Font.helvetica(),
                                bold: pw.Font.helveticaBold(),
                              ),
                            ),
                            build: (context) => [
                              pw.Header(
                                level: 0,
                                child: pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Text(AppLocalizations.of(navigatorKey.currentContext!)!.expensesSummary, 
                                      style: pw.TextStyle(
                                        fontSize: 28,
                                        fontWeight: pw.FontWeight.bold,
                                      )
                                    ),
                                    pw.Text(DateTime.now().toString().split(' ')[0],
                                      style: pw.TextStyle(
                                        fontSize: 14,
                                        color: PdfColors.grey700,
                                      )
                                    ),
                                  ],
                                ),
                              ),
                              pw.SizedBox(height: 20),
                              
                              ...expenses.map((expense) => pw.Container(
                                margin: pw.EdgeInsets.only(bottom: 15),
                                padding: pw.EdgeInsets.all(15),
                                decoration: pw.BoxDecoration(
                                  border: pw.Border.all(color: PdfColors.grey300),
                                  borderRadius: pw.BorderRadius.circular(8),
                                ),
                                child: pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text(expense.name ?? 'N/A',
                                      style: pw.TextStyle(
                                        fontSize: 16,
                                        fontWeight: pw.FontWeight.bold,
                                      )
                                    ),
                                    pw.SizedBox(height: 8),
                                    pw.Row(
                                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                      children: [
                                        pw.Text('${AppLocalizations.of(navigatorKey.currentContext!)!.totalAmount(expense.price ?? 0)}'),
                                        pw.Text('${AppLocalizations.of(navigatorKey.currentContext!)!.date}: ${expense.date?.toString().split(' ')[0] ?? 'N/A'}'),
                                      ],
                                    ),
                                  ],
                                ),
                              )).toList(),
                              
                              pw.SizedBox(height: 20),
                              pw.Container(
                                padding: pw.EdgeInsets.all(15),
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.grey100,
                                  borderRadius: pw.BorderRadius.circular(8),
                                ),
                                child: pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Text('${AppLocalizations.of(navigatorKey.currentContext!)!.totalExpenses}:',
                                      style: pw.TextStyle(
                                        fontSize: 16,
                                        fontWeight: pw.FontWeight.bold,
                                      )
                                    ),
                                    pw.Text('${AppLocalizations.of(navigatorKey.currentContext!)!.priceAmount(total)}',
                                      style: pw.TextStyle(
                                        fontSize: 16,
                                        fontWeight: pw.FontWeight.bold,
                                        color: PdfColors.teal,
                                      )
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );

                        final directory = await getApplicationDocumentsDirectory();
                        final file = File('${directory.path}/expenses_summary.pdf');
                        await file.writeAsBytes(await pdf.save());

                        final box = context.findRenderObject() as RenderBox?;
                        await SharePlus.instance.share(
                          ShareParams(
                            files: [XFile(file.path),], 
                            text: AppLocalizations.of(context)!.expensesSummary,
                            sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
                          )
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppLocalizations.of(context)!.failedToGeneratePdf)),
                        );
                      }
                    },
                    child: Icon(
                      Icons.share,
                      color: mainColor,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    Widget _buildExpensesList() {
      return ListView.separated(
        physics: BouncingScrollPhysics(),
        itemBuilder: (_, i) {
          final expense = ExtraExpensesCubit.get(context).expenses[i];
          return Row(
            children: [
              Expanded(
                child: ExpenseItem(
                  expense: expense,
                  onTap: (ctx, exp){
                    context.read<ExtraExpensesCubit>().showExpenseDetails(context, expense, i);
                  },
                ),
              ),
              SizedBox(width: 5),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  ExtraExpensesCubit.get(context).deleteExpense(i); 
                },
              ),
            ],
          );
        },
        separatorBuilder: (_, __) => SizedBox(height: 12),
        itemCount: ExtraExpensesCubit.get(context).expenses.length,
      );
    }

    void _showSortOptions() {
      showModalBottomSheet(
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
                AppLocalizations.of(context)!.sortExpenses,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: mainColor,
                ),
              ),
              SizedBox(height: 20),
              _buildSortOption(
                Icons.arrow_upward,
                AppLocalizations.of(context)!.highestPrice,
                () {
                  ExtraExpensesCubit.get(context).sortExpenses(byPrice: true, descending: true);
                  Navigator.pop(context);
                },
              ),
              _buildSortOption(
                Icons.arrow_downward,
                AppLocalizations.of(context)!.lowestPrice,
                () {
                  ExtraExpensesCubit.get(context).sortExpenses(byPrice: true, descending: false);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      );
    }

    Widget _buildSortOption(IconData icon, String label, VoidCallback onTap) {
      return ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: mainColor),
        ),
        title: Text(label),
        onTap: onTap,
      );
    }
}