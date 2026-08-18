import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/core/provider/connectivity_provider.dart';
import 'package:your_schedule/core/untis.dart';

part 'mobile_data_provider.g.dart';

@riverpod
class AccountInfo extends _$AccountInfo {
  @override
  MobileData? build(UntisSession session) {
    assert(session is ActiveUntisSession, 'Session must be active');
    if (ref.watch(canMakeRequestProvider)) {
      var data = ref.watch(requestMobileDataProvider(session));
      if (data.hasValue) {
        return data.requireValue;
      }
    }
    return ref.watch(cachedMobileDataProvider(session));
  }
}
