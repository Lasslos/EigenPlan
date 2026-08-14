import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/core/rpc_request/rpc.dart';
import 'package:your_schedule/core/untis/models/school_search/school.dart';

part 'request_school_list.g.dart';

/// Requests a list of schools for the given [query].
///
/// The request is send to the schoolsearch server and uses the [query] to search for schools.
@riverpod
Future<List<School>> requestSchoolList(Ref ref, String query) async {
  final response = await rpcRequest(
    serverUrl: Uri.parse('https://schoolsearch.webuntis.com/schoolquery2'),
    method: 'searchSchool',
    params: [
      {
        'search': query,
      }
    ],
  );

  return switch (response) {
    RPCResponseResult() => response.result['schools'].map<School>((school) => School.fromJson(school)).toList(),
    RPCResponseError() => throw response.error,
  };
}
