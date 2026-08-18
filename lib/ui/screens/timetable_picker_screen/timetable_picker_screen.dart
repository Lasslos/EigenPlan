import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:your_schedule/core/provider/selected_timetable_resource_provider.dart';
import 'package:your_schedule/core/provider/timetable_menu_provider.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/core/untis.dart';

/// "Switch timetable" picker — see `docs/api/spec/NOTES.md` §4b. Always shows
/// `timetable/menu`'s curated shortlist (own timetable + dependents) above the full
/// `timetable/filter` directory for the selected resourceType; the search field is
/// an optional client-side filter over that directory, not a precondition for
/// browsing it — mirroring `filter_screen.dart`'s existing search idiom.
class TimetablePickerScreen extends ConsumerStatefulWidget {
  const TimetablePickerScreen({super.key});

  @override
  ConsumerState<TimetablePickerScreen> createState() =>
      _TimetablePickerScreenState();
}

class _TimetablePickerScreenState extends ConsumerState<TimetablePickerScreen> {
  late final FocusNode _searchFocusNode;
  late final TextEditingController _searchController;
  bool _showSearch = false;
  String _searchQuery = '';
  String? _selectedResourceType;

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  static const _resourceTypeLabels = {
    'CLASS': 'Klasse',
    'STUDENT': 'Schüler',
    'TEACHER': 'Lehrer',
    'ROOM': 'Raum',
  };

  void _select(WidgetRef ref, TimetableResourceRef resource) {
    ref.read(selectedTimetableResourceProvider.notifier).select(resource);
    Navigator.pop(context);
  }

  void _selectOwn(WidgetRef ref) {
    ref.read(selectedTimetableResourceProvider.notifier).resetToOwn();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    var session = ref.watch(selectedUntisSessionProvider) as ActiveUntisSession;

    return Scaffold(
      appBar: AppBar(
        leading: _showSearch
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _showSearch = false;
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
              )
            : null,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: !_showSearch
              ? const Text('Stundenplan wechseln')
              : Container(
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(30),
                  ),
                  padding: const EdgeInsets.only(left: 10),
                  child: Center(
                    child: TextField(
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      textAlignVertical: TextAlignVertical.center,
                      autofocus: true,
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        suffixIcon: IconButton(
                          iconSize: 18,
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          }),
                        ),
                        hintText: 'Suchen',
                      ),
                    ),
                  ),
                ),
        ),
        actions: [
          if (!_showSearch)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => _showSearch = true),
            ),
        ],
      ),
      body: _PickerBody(
        session: session,
        resourceTypeLabels: _resourceTypeLabels,
        selectedResourceType: _selectedResourceType,
        onResourceTypeChanged: (type) =>
            setState(() => _selectedResourceType = type),
        searchQuery: _searchQuery,
        onSelectOwn: () => _selectOwn(ref),
        onSelect: (resource) => _select(ref, resource),
      ),
    );
  }
}

class _PickerBody extends ConsumerWidget {
  final ActiveUntisSession session;
  final Map<String, String> resourceTypeLabels;
  final String? selectedResourceType;
  final void Function(String type) onResourceTypeChanged;
  final String searchQuery;
  final VoidCallback onSelectOwn;
  final void Function(TimetableResourceRef resource) onSelect;

  const _PickerBody({
    required this.session,
    required this.resourceTypeLabels,
    required this.selectedResourceType,
    required this.onResourceTypeChanged,
    required this.searchQuery,
    required this.onSelectOwn,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var menu = ref.watch(timetableMenuProvider(session));
    // `timetable/menu` is the authoritative source for which resourceTypes this
    // account may browse via `timetable/filter`, but it can itself be unavailable
    // (e.g. a 404 `NO_TIMETABLES_AVAILABLE_FOR_YOUR_USER`) even though
    // `timetable/filter` still works for one resourceType — see
    // docs/api/spec/NOTES.md §2b/§4b. Fall back to the account's own `userData.type`
    // (`elemType`) in that case; for anonymous sessions that field is itself `null`
    // (see docs/api/captures/startup/06_bs_gfv_user_data.md), but a live probe
    // confirmed `timetable/filter` only accepts `resourceType=CLASS` for those
    // (403 on STUDENT/TEACHER/ROOM), so default anonymous accounts to CLASS rather
    // than offering all four and hitting a 403.
    var availableTypes = menu != null && menu.availableTimetables.isNotEmpty
        ? menu.availableTimetables
        : session.userData.type != null
        ? [session.userData.type!]
        : session.loginMode == LoginMode.anonymous
        ? const ['CLASS']
        : resourceTypeLabels.keys.toList();
    var resourceType =
        selectedResourceType ??
        (availableTypes.isNotEmpty ? availableTypes.first : 'CLASS');

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('Eigener Stundenplan'),
          onTap: onSelectOwn,
        ),
        if (menu != null && menu.dependents.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('Angehörige'),
          ),
          for (final dependent in menu.dependents)
            ListTile(
              leading: const Icon(Icons.family_restroom),
              title: Text(
                dependent.resource.displayName?.isNotEmpty == true
                    ? dependent.resource.displayName!
                    : dependent.resource.longName ??
                          dependent.resource.shortName ??
                          '',
              ),
              onTap: () => onSelect(
                TimetableResourceRef(
                  resourceType: dependent.type,
                  resourceId: dependent.resource.id,
                  displayName:
                      dependent.resource.displayName ??
                      dependent.resource.longName,
                ),
              ),
            ),
        ],
        const Divider(height: 1),
        // No point offering a choice of one — skip the chip row entirely. Shown
        // unconditionally (not gated behind the search field) so browsing the full
        // directory doesn't require typing a query first.
        if (availableTypes.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Wrap(
              spacing: 8,
              children: [
                for (final type in availableTypes)
                  ChoiceChip(
                    label: Text(resourceTypeLabels[type] ?? type),
                    selected: resourceType == type,
                    onSelected: (_) => onResourceTypeChanged(type),
                  ),
              ],
            ),
          ),
        Expanded(
          child: _FilterResultList(
            session: session,
            resourceType: resourceType,
            searchQuery: searchQuery,
            onSelect: onSelect,
          ),
        ),
      ],
    );
  }
}

class _FilterResultList extends ConsumerWidget {
  final ActiveUntisSession session;
  final String resourceType;
  final String searchQuery;
  final void Function(TimetableResourceRef resource) onSelect;

  const _FilterResultList({
    required this.session,
    required this.resourceType,
    required this.searchQuery,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var filterAsync = ref.watch(
      requestTimetableFilterProvider(session, resourceType),
    );

    return filterAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          Center(child: Text('Fehler beim Laden: $error')),
      data: (filter) {
        var items = _itemsFor(filter);
        var query = searchQuery.toLowerCase();
        if (query.isNotEmpty) {
          items = items
              .where(
                (item) =>
                    item.fullName.toLowerCase().contains(query) ||
                    (item.resource.shortName ?? '').toLowerCase().contains(
                      query,
                    ) ||
                    (item.resource.displayName ?? '').toLowerCase().contains(
                      query,
                    ),
              )
              .toList();
        }

        if (items.isEmpty) {
          return const Center(child: Text('Keine Ergebnisse.'));
        }

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            var item = items[index];
            return ListTile(
              title: Text(item.fullName),
              subtitle: item.subtitle != null ? Text(item.subtitle!) : null,
              onTap: () => onSelect(
                TimetableResourceRef(
                  resourceType: resourceType,
                  resourceId: item.resource.id,
                  displayName: item.fullName,
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<_FilterItem> _itemsFor(TimetableFilterResponse filter) {
    switch (resourceType) {
      case 'CLASS':
        return [
          for (final entry in filter.classes)
            _FilterItem(
              entry.classResource,
              entry.classResource.longName ??
                  entry.classResource.shortName ??
                  '',
              entry.department?.longName,
            ),
        ];
      case 'TEACHER':
        return [
          for (final entry in filter.teachers)
            _FilterItem(entry.teacher, _teacherFullName(entry.teacher), null),
        ];
      case 'ROOM':
        return [
          for (final entry in filter.rooms)
            _FilterItem(
              entry.room,
              entry.room.longName ?? entry.room.shortName ?? '',
              entry.building?.longName,
            ),
        ];
      case 'STUDENT':
        final items = [
          for (final entry in filter.students)
            _FilterItem(
              entry.student,
              // `student.displayName` (confirmed live) carries the full
              // "Firstname Lastname" — `longName` can be surname-only, unlike the
              // `timetable/filter` sample this was originally modeled from. See
              // openapi.yaml's `TimetableResource.displayName`.
              entry.student.displayName?.isNotEmpty == true
                  ? entry.student.displayName!
                  : entry.student.longName ?? entry.student.shortName ?? '',
              entry.classes.isNotEmpty
                  ? entry.classes.first.classResource.longName
                  : null,
            ),
        ];
        // Sorted by class, then by name within a class, rather than the server's
        // (effectively unordered, whole-school) response order — makes a several-
        // hundred-entry directory actually browsable. Classless students (no
        // current class membership) sort after everyone else instead of first —
        // an empty subtitle would otherwise sort before any real class name.
        return items..sort((a, b) {
          if (a.subtitle == null || b.subtitle == null) {
            if (a.subtitle == b.subtitle) {
              return a.fullName.compareTo(b.fullName);
            }
            return a.subtitle == null ? 1 : -1;
          }
          final classCompare = a.subtitle!.compareTo(b.subtitle!);
          return classCompare != 0
              ? classCompare
              : a.fullName.compareTo(b.fullName);
        });
      default:
        return [];
    }
  }

  /// `timetable/filter`'s own `teacher.longName` is only the surname (see
  /// docs/api/captures/home/timetable_filter.md) — prefer the real "Firstname
  /// Lastname" from getUserData2017's teacher master data (keyed by the same
  /// resource id) when available.
  String _teacherFullName(TimetableResource teacher) {
    final fromMasterData = session.userData.teachers[teacher.id]?.longName;
    if (fromMasterData != null && fromMasterData.isNotEmpty) {
      return fromMasterData;
    }
    return teacher.longName ?? teacher.shortName ?? '';
  }
}

class _FilterItem {
  final TimetableResource resource;
  final String fullName;
  final String? subtitle;

  const _FilterItem(this.resource, this.fullName, this.subtitle);
}
