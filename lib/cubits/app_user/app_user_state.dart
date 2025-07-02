part of 'app_user_cubit.dart';

abstract class AppUserState {}

class AppUserInitial extends AppUserState {}

class AppUserLoading extends AppUserState {}

class AppUserLoaded extends AppUserState {}

class AppUserError extends AppUserState {
  final String message;
  AppUserError(this.message);
}
class TotalUpdatedState extends AppUserState {}

class ProfitUpdatedState extends AppUserState {}

class TotalOrdersUpdatedState extends AppUserState {}

class UserUpdatedState extends AppUserState {}

class AppUserSuccess extends AppUserState {}

class AppUserDataValuesLoading extends AppUserState {}