import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/financial_support_model.dart';

class FinancialSupportRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<FinancialSupportModel>> getAccounts() async {
    final response = await _supabase
        .from('financial_support_accounts')
        .select()
        .order('created_at', ascending: false);
    
    return (response as List)
        .map((json) => FinancialSupportModel.fromJson(json))
        .toList();
  }

  Future<void> addAccount(FinancialSupportModel account) async {
    await _supabase.from('financial_support_accounts').insert(account.toJson());
  }

  Future<void> updateAccount(FinancialSupportModel account) async {
    await _supabase
        .from('financial_support_accounts')
        .update(account.toJson())
        .eq('id', account.id);
  }

  Future<void> deleteAccount(String id) async {
    await _supabase.from('financial_support_accounts').delete().eq('id', id);
  }
}
