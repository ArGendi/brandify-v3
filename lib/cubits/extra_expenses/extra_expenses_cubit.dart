import 'package:bloc/bloc.dart';
import 'package:brandify/main.dart';
import 'package:brandify/models/local/hive_services.dart';
import 'package:brandify/view/widgets/custom_button.dart';
import 'package:brandify/view/widgets/detail_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:brandify/constants.dart';
import 'package:brandify/cubits/app_user/app_user_cubit.dart';
import 'package:brandify/enum.dart';
import 'package:brandify/models/extra_expense.dart';
import 'package:brandify/models/firebase/firestore/extra_expenses_services.dart';
import 'package:brandify/models/firebase/firestore/firestore_services.dart';
import 'package:brandify/models/package.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
part 'extra_expenses_state.dart';

class ExtraExpensesCubit extends Cubit<ExtraExpensesState> {
  List<ExtraExpense> expenses = [];
  List<ExtraExpense> _allExpenses = []; // Add this line to store all expenses
  String? name;
  int? price;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  
  ExtraExpensesCubit() : super(ExtraExpensesInitial());

  static ExtraExpensesCubit get(BuildContext context) => BlocProvider.of(context);

  void sortExpenses({required bool byPrice, required bool descending}) {
    if (byPrice) {
      expenses.sort((a, b) => descending
          ? (b.price ?? 0).compareTo(a.price ?? 0)
          : (a.price ?? 0).compareTo(b.price ?? 0));
    } else {
      expenses.sort((a, b) => descending
          ? (b.date ?? DateTime.now()).compareTo(a.date ?? DateTime.now())
          : (a.date ?? DateTime.now()).compareTo(b.date ?? DateTime.now()));
    }
    emit(ExtraExpensesLoaded());
  }

  Future<void> getAllExpensesFromHive() async {
    var box = Hive.box(HiveServices.getTableName(extraExpensesTable));
    var keys = box.keys.toList();
    _allExpenses = [];
    
    for (var key in keys) {
      var expenseMap = Map<String, dynamic>.from(box.get(key));
      var expense = ExtraExpense.fromJson(expenseMap);
      expense.id = key;
      _allExpenses.add(expense);
    }
    
    expenses = List.from(_allExpenses);
    emit(ExtraExpensesLoaded()); 
  }
  Future<int> getAllExpenses() async {
    try {
      emit(ExtraExpensesLoading());
      await Package.checkAccessability(
        online: () async {
          var response = await ExtraExpensesServices().getExtraExpenses();
          if (response.status == Status.success) {
            _allExpenses = response.data; // Store all expenses
            expenses = List.from(_allExpenses); // Create a copy for filtering
            sortExpenses(byPrice: false, descending: true);
          }
        },
        offline: () async {
          await getAllExpensesFromHive();
          //_allExpenses = List.from(expenses); // Store all expenses
          sortExpenses(byPrice: false, descending: true);
        },
      );
      emit(ExtraExpensesLoaded());
      int totalCost = expenses.fold(0, (sum, expense) => sum + (expense.price ?? 0));
      return totalCost;
    } catch (e) {
      emit(ExtraExpensesError(e.toString()));
      return 0;
    }
  }

  Future<int> getExpensesInDateRange(DateTime fromDate, DateTime toDate) async {
    try {
      emit(ExtraExpensesLoading());
      await Package.checkAccessability(
        online: () async {
          var response = await ExtraExpensesServices().getExtraExpenses();
          if (response.status == Status.success) {
            // Filter expenses by date range
            _allExpenses = response.data.where((expense) {
              if (expense.date == null) return false;
              return expense.date!.isAfter(DateTime(fromDate.year, fromDate.month, fromDate.day)) && 
                     expense.date!.isBefore(DateTime(toDate.year, toDate.month, toDate.day).add(const Duration(days: 1)));
            }).toList();
            expenses = List.from(_allExpenses); // Create a copy for filtering
            sortExpenses(byPrice: false, descending: true);
          }
        },
        offline: () async {
          await getAllExpensesFromHive();
          // Filter expenses by date range from local storage
          _allExpenses = expenses.where((expense) {
            if (expense.date == null) return false;
            return expense.date!.isAfter(fromDate.subtract(const Duration(days: 1))) && 
                   expense.date!.isBefore(toDate.add(const Duration(days: 1)));
          }).toList();
          expenses = List.from(_allExpenses); // Create a copy for filtering
          sortExpenses(byPrice: false, descending: true);
        },
      );
      emit(ExtraExpensesLoaded());
      int totalCost = expenses.fold(0, (sum, expense) => sum + (expense.price ?? 0));
      return totalCost;
    } catch (e) {
      emit(ExtraExpensesError(e.toString()));
      return 0;
    }
  }

  void filterExpensesByDate(DateTime start, DateTime end) {
    expenses = _allExpenses.where((expense) {
      if (expense.date == null) return false;
      
      final startDate = DateTime(start.year, start.month, start.day);
      final endDate = DateTime(end.year, end.month, end.day, 23, 59, 59);
      final expenseDate = DateTime(expense.date!.year, expense.date!.month, expense.date!.day);
      
      return expenseDate.isAtSameMomentAs(startDate) || 
             expenseDate.isAtSameMomentAs(endDate) ||
             (expenseDate.isAfter(startDate) && expenseDate.isBefore(endDate));
    }).toList();
    emit(ExtraExpensesLoaded());
  }

  Future<void> addExpense(BuildContext context, ExtraExpense expense) async {
    try {
      emit(ExtraExpensesLoading());
      
      await Package.checkAccessability(
        online: () async{
          var response = await FirestoreServices().add(extraExpensesTable,expense.toJson());
          if(response.status == Status.success){
            expense.backendId = response.data;
            expenses.add(expense);
          }
        },
        offline: () async{
          int id = await Hive.box(HiveServices.getTableName(extraExpensesTable)).add(expense.toJson());
          expense.id = id;
          expenses.add(expense);  
        }
      );
      AppUserCubit.get(context).deductFromProfit(expense.price ?? 0);
      emit(ExtraExpensesLoaded());
    } catch (e) {
      emit(ExtraExpensesError(e.toString()));
    }
  }

  Future<void> updateExpense(ExtraExpense expense) async {
    try {
      emit(ExtraExpensesLoading());
      await Package.checkAccessability(
        online: () async{
          final result = await FirestoreServices().update(
            extraExpensesTable, 
            expense.backendId!, 
            expense.toJson()
          );
          
          if (result.status == Status.success) {
            final index = expenses.indexWhere((e) => e.id == expense.id);
            if (index != -1) {
              expenses[index] = expense;
            }
          }
        },
        offline: () async{
          await Hive.box(HiveServices.getTableName(extraExpensesTable)).put(expense.id, expense.toJson());
        },
      );
      
      
      emit(ExtraExpensesLoaded());
    } catch (e) {
      emit(ExtraExpensesError(e.toString()));
    }
  }

  Future<void> deleteExpense(int index) async {
    try {
      emit(ExtraExpensesLoading());
      
      await Package.checkAccessability(
        online: () async{
          var res = await FirestoreServices().delete(extraExpensesTable, expenses[index].backendId!);
          if(res.status == Status.success){ 
            AppUserCubit.get(navigatorKey.currentState!.context).addToProfit(expenses[index].price?? 0); 
            expenses.removeAt(index);
            emit(ExtraExpensesLoaded());
          }
          else{
            emit(FailDeleteExtraExpenseState());
            ScaffoldMessenger.of(navigatorKey.currentState!.context).showSnackBar(
              SnackBar(content: Text(res.data.toString())),
            );
          }
        }, 
        offline: () async{
          print("delete offline");
          print("expenses nameeee: ${expenses[index].name} - expenses idddd: ${expenses[index].id}");
          await Hive.box(HiveServices.getTableName(extraExpensesTable)).delete(expenses[index].id);
          AppUserCubit.get(navigatorKey.currentState!.context).addToProfit(expenses[index].price?? 0);
          expenses.removeAt(index);
          emit(ExtraExpensesLoaded());
        },
      );
      
    } catch (e) {
      emit(ExtraExpensesError(e.toString()));
    }
  }

  Future<bool> onAddSide(BuildContext context) async{
    bool valid = formKey.currentState?.validate() ?? false;
    if(valid){
      formKey.currentState?.save();
      ExtraExpense temp = ExtraExpense(name: name, price: price, date: DateTime.now());
      emit(LoadingAddExtraExpenseState());
      await Package.checkAccessability(
        online: () async{
          var response = await FirestoreServices().add(extraExpensesTable,temp.toJson());
          if(response.status == Status.success){
            temp.backendId = response.data;
            expenses.add(temp);
            emit(ExtraExpenseAddedState());
            AppUserCubit.get(context).deductFromProfit(temp.price ?? 0); 
          }
          else{
            emit(FailAddExtraExpenseState());
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response.data.toString())),
            );
          }
        },
        offline: () async{
          int id = await Hive.box(HiveServices.getTableName(extraExpensesTable)).add(temp.toJson());
          temp.id = id;
          expenses.add(temp);
          emit(ExtraExpenseAddedState());
          AppUserCubit.get(context).deductFromProfit(temp.price ?? 0); 
        },
      );
        
      return true;
    }
    return false;
  }

  void reset(){
    expenses = [];
    _allExpenses = [];
    name = null;
    price = null;
    emit(ExtraExpensesInitial());
  }

  void clear() {
    name = null;
    price = null;
    expenses = [];
    _allExpenses = [];
    emit(ExtraExpensesInitial());
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
              AppLocalizations.of(context)!.expenseDetails,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: mainColor,
              ),
            ),
            SizedBox(height: 20),
            DetailRow(
              icon: Icons.label,
              label:  AppLocalizations.of(context)!.name,
              value: expense.name ?? '',
            ),
            DetailRow(
              icon: Icons.attach_money,
              label:  AppLocalizations.of(context)!.amount,
              value: expense.price?.toString() ?? '',
            ),
            DetailRow(
              icon: Icons.calendar_today,
              label:  AppLocalizations.of(context)!.date,
              value: expense.date?.toString().split(' ')[0] ?? '',
            ),
            SizedBox(height: 20),
            CustomButton(
              text: AppLocalizations.of(context)!.close,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}