import 'dart:async';

import 'package:bracket/core/constants.dart';
import 'package:bracket/core/location/reverse_geocoder.dart';
import 'package:bracket/core/map/tile_provider.dart';
import 'package:bracket/core/theme/adaptive.dart';
import 'package:bracket/core/utils/format.dart';
import 'package:bracket/data/repositories/providers.dart';
import 'package:bracket/features/explore/explore_providers.dart';
import 'package:bracket/features/organizer/organizer_providers.dart';
import 'package:bracket/features/tournament/tournament_providers.dart';
import 'package:bracket/l10n/generated/app_localizations.dart';
import 'package:bracket/l10n/labels.dart';
import 'package:bracket/models/tournament_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

/// Fallback map center until the device location arrives (Montevideo).
const _defaultCenter = LatLng(-34.9012, -56.1646);

/// Create or edit an event (with a tap-to-place venue pin on the map).
class EventFormScreen extends ConsumerStatefulWidget {
  const EventFormScreen({super.key, this.tournamentId});

  /// `null` creates a new event; otherwise the event to edit.
  final String? tournamentId;

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _title = TextEditingController();
  final _description = TextEditingController();
  final _prizes = TextEditingController();
  final _cost = TextEditingController();
  final _teams = TextEditingController(text: '8');
  final _venue = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();

  String _sport = AppConstants.sports.first;
  String _kind = AppConstants.kinds.first;
  late DateTime _start;
  late DateTime _end;
  LatLng? _pin;

  final _mapController = MapController();

  /// Pending reverse-geocode after a map tap (see [_onMapTapped]).
  Timer? _pinDebounce;

  bool _prefilled = false;
  bool _saving = false;
  bool _locating = false;

  bool get _isEditing => widget.tournamentId != null;

  @override
  void initState() {
    super.initState();
    final initial = DateTime.now().add(const Duration(days: 7));
    _start = DateTime(initial.year, initial.month, initial.day, 19);
    _end = DateTime(initial.year, initial.month, initial.day, 23);
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _description,
      _prizes,
      _cost,
      _teams,
      _venue,
      _address,
      _city,
    ]) {
      controller.dispose();
    }
    _pinDebounce?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _applyTournament(TournamentModel tournament) {
    _title.text = tournament.title;
    _description.text = tournament.description;
    _prizes.text = tournament.prizes;
    _cost.text = tournament.inscriptionCost <= 0
        ? ''
        : tournament.inscriptionCost.toStringAsFixed(0);
    _teams.text = '${tournament.totalTeams}';
    _venue.text = tournament.venueName;
    _address.text = tournament.address;
    _city.text = tournament.city;
    _sport = tournament.sport;
    _kind = tournament.kind;
    _start = tournament.startTime;
    _end = tournament.endTime;
    _pin = tournament.location;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!_isEditing) return _formScaffold();

    final tournamentAsync = ref.watch(tournamentProvider(widget.tournamentId!));
    return tournamentAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.eventLoadError(error))),
      ),
      data: (tournament) {
        if (!_prefilled && tournament != null) {
          _prefilled = true;
          // Runs before the form (and its map) first builds, so the map's
          // initial center/zoom already point at the venue pin.
          _applyTournament(tournament);
        }
        return _formScaffold();
      },
    );
  }

  Scaffold _formScaffold() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _sectionLabel(context, l10n.sport),
            Wrap(
              spacing: 8,
              children: [
                for (final sport in AppConstants.sports)
                  ChoiceChip(
                    label: Text(l10n.sportLabel(sport)),
                    selected: _sport == sport,
                    onSelected: (_) => setState(() => _sport = sport),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _sectionLabel(context, l10n.formatLabel),
            SegmentedButton<String>(
              segments: [
                for (final kind in AppConstants.kinds)
                  ButtonSegment(value: kind, label: Text(l10n.kindLabel(kind))),
              ],
              selected: {_kind},
              onSelectionChanged: (selection) =>
                  setState(() => _kind = selection.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('event-title'),
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.titleLabel,
                hintText: 'Copa Centro 7v7',
              ),
              validator: (value) => _required(value, l10n),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('event-description'),
              controller: _description,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.descriptionLabel,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('event-prizes'),
              controller: _prizes,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.prizesLabel,
                hintText: r'Trofeo + $150.000',
              ),
            ),
            const SizedBox(height: 8),
            _dateTile(
              label: l10n.startsLabel,
              icon: Icons.play_circle_outline,
              value: _start,
              onTap: () => _pickDateTime(
                current: _start,
                onPicked: (value) => setState(() => _start = value),
              ),
            ),
            _dateTile(
              label: l10n.endsLabel,
              icon: Icons.stop_circle_outlined,
              value: _end,
              onTap: () => _pickDateTime(
                current: _end,
                onPicked: (value) => setState(() => _end = value),
              ),
            ),
            const SizedBox(height: 4),
            TextFormField(
              key: const Key('event-teams'),
              controller: _teams,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.teamsLabel,
                helperText: l10n.spotsTotal,
              ),
              validator: (value) => _teamsValidator(value, l10n),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('event-cost'),
              controller: _cost,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.costLabel,
                hintText: l10n.costFreeHint,
                prefixText: r'$ ',
              ),
              validator: (value) => _costValidator(value, l10n),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('event-venue'),
              controller: _venue,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.venueLabel),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('event-address'),
              controller: _address,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.addressLabel),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('event-city'),
              controller: _city,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.cityLabel),
            ),
            const SizedBox(height: 20),
            _sectionLabel(context, l10n.locationLabel),
            Text(
              l10n.locationHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _locating ? null : _useCurrentLocation,
              icon: _locating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, size: 18),
              label: Text(l10n.useMyLocation),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 320,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter:
                            _pin ??
                            ref.watch(userLocationProvider).valueOrNull ??
                            _defaultCenter,
                        initialZoom: _pin != null ? 15 : 12,
                        onTap: (tapPosition, latLng) => _onMapTapped(latLng),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: osmTileUrl,
                          userAgentPackageName: 'com.bracket.torneos',
                          tileProvider: ref.watch(tileProviderProvider),
                        ),
                        if (_pin != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _pin!,
                                width: 40,
                                height: 40,
                                // Bounces in when the pin lands (fresh mounts
                                // only — moves keep the settled state).
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: 1),
                                  duration: const Duration(milliseconds: 450),
                                  curve: Curves.elasticOut,
                                  builder: (context, scale, child) =>
                                      Transform.scale(
                                        scale: scale,
                                        child: child,
                                      ),
                                  child: Icon(
                                    Icons.location_pin,
                                    size: 40,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    Positioned(
                      left: 6,
                      bottom: 4,
                      child: Text(
                        '© OpenStreetMap',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_pin != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.pinPlaced(
                      _pin!.latitude.toStringAsFixed(4),
                      _pin!.longitude.toStringAsFixed(4),
                    ),
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isEditing ? l10n.saveChanges : l10n.publishEvent),
          ),
        ),
      ),
    );
  }

  /// Section header: primary green, bold — anchors each form block.
  Widget _sectionLabel(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _dateTile({
    required String label,
    required IconData icon,
    required DateTime value,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(label),
      subtitle: Text(formatEventDate(value)),
      trailing: Icon(
        Icons.edit_calendar_outlined,
        color: theme.colorScheme.outline,
      ),
      onTap: onTap,
    );
  }

  Future<void> _pickDateTime({
    required DateTime current,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final now = DateTime.now();
    final picked = await showAdaptiveDateTimePicker(
      context,
      initial: current,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked == null || !mounted) return;
    onPicked(picked);
  }

  /// Places the pin at the device location and completes the empty
  /// address/city fields via reverse geocoding (text the organizer already
  /// typed is kept).
  Future<void> _useCurrentLocation() async {
    final l10n = AppLocalizations.of(context)!;
    _pinDebounce?.cancel();
    final pinBefore = _pin; // A tap while the GPS fix is in flight wins.
    setState(() => _locating = true);
    try {
      final location = await _currentLocation();
      if (!mounted) return;
      if (location == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.locationDenied)));
        return;
      }
      if (_pin != pinBefore) {
        // The organizer tapped the map while waiting: don't yank the pin
        // back — the tap's own debounce completes its address.
        return;
      }

      setState(() => _pin = location);
      try {
        _mapController.move(location, 16);
      } catch (_) {
        // The map is not attached yet: its initialCenter reads the new pin
        // when it first builds instead.
      }

      final result = await _fillAddressFromPin(location);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(switch (result) {
            _AddressResult.failed => l10n.locationNoAddress,
            _AddressResult.completed => l10n.addressFilled,
            _AddressResult.unchanged => l10n.locationUpdated,
          }),
        ),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  /// Tap-to-place: moves the pin and completes the empty address/city fields
  /// after a short pause, so a quick sequence of taps only fires one
  /// reverse-geocode request (Nominatim allows ~1/second).
  void _onMapTapped(LatLng point) {
    setState(() => _pin = point);
    _pinDebounce?.cancel();
    _pinDebounce = Timer(const Duration(milliseconds: 800), () {
      if (!mounted || _pin != point) return;
      unawaited(_announcePinAddress());
    });
  }

  /// Completes the address silently after a map tap: the fields updating is
  /// the feedback. Only failures get a snackbar.
  Future<void> _announcePinAddress() async {
    final l10n = AppLocalizations.of(context)!;
    final pin = _pin;
    if (pin == null) return;
    final result = await _fillAddressFromPin(pin);
    if (!mounted || _pin != pin) return; // The pin moved on.
    if (result == _AddressResult.failed) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.addressFailed)));
    }
  }

  /// Reverse-geocodes [point] into the empty address/city fields; text the
  /// organizer already typed is never overwritten.
  Future<_AddressResult> _fillAddressFromPin(LatLng point) async {
    ResolvedAddress? resolved;
    try {
      resolved = await ref.read(reverseGeocodeProvider).resolve(point);
    } catch (_) {
      resolved = null;
    }
    if (!mounted || resolved == null) return _AddressResult.failed;

    var filled = false;
    if (_address.text.trim().isEmpty && resolved.street.isNotEmpty) {
      _address.text = resolved.street;
      filled = true;
    }
    if (_city.text.trim().isEmpty && resolved.city.isNotEmpty) {
      _city.text = resolved.city;
      filled = true;
    }
    return filled ? _AddressResult.completed : _AddressResult.unchanged;
  }

  /// Never throws: the provider already maps platform failures to `null`.
  Future<LatLng?> _currentLocation() async {
    // Fresh fix per press: a denied permission or a stale location would
    // otherwise be cached for the whole session.
    ref.invalidate(userLocationProvider);
    try {
      return await ref.read(userLocationProvider.future);
    } catch (_) {
      return null;
    }
  }

  String? _required(String? value, AppLocalizations l10n) =>
      (value == null || value.trim().isEmpty) ? l10n.required : null;

  String? _teamsValidator(String? value, AppLocalizations l10n) {
    final teams = int.tryParse(value?.trim() ?? '');
    if (teams == null || teams < 1) {
      return l10n.minOneTeam;
    }
    return null;
  }

  String? _costValidator(String? value, AppLocalizations l10n) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null; // Free event.
    final amount = _tryParseAmount(text);
    if (amount == null || amount < 0) return l10n.invalidAmount;
    return null;
  }

  /// Parses an Uruguayan-formatted amount: "." thousands, "," decimal —
  /// "20.000" is twenty thousand, not twenty. A dot only counts as decimal
  /// when not followed by exactly three digits ("1500.50").
  double? _tryParseAmount(String text) {
    var t = text.trim().replaceAll(RegExp(r'[\s\$]'), '');
    if (t.isEmpty) return null;
    final lastComma = t.lastIndexOf(',');
    final lastDot = t.lastIndexOf('.');
    if (lastComma > lastDot) {
      // Comma is the decimal separator: "1.500,50".
      t = t.replaceAll('.', '').replaceAll(',', '.');
    } else if (lastDot >= 0 && t.length - lastDot == 4) {
      // Thousands separator: "20.000".
      t = t.replaceAll('.', '');
    } else {
      t = t.replaceAll(',', '');
    }
    return double.tryParse(t);
  }

  double get _parsedCost => _tryParseAmount(_cost.text) ?? 0;

  int get _parsedTeams => int.tryParse(_teams.text.trim()) ?? 4;

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_end.isAfter(_start)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.endDateBeforeStart)));
      return;
    }

    final session = ref.read(authStateProvider);
    if (session == null) return;

    setState(() => _saving = true);
    // Captured before the awaits: `ref` throws once disposed, and the
    // caches must refresh even if the user navigates away mid-save.
    final container = ProviderScope.containerOf(context, listen: false);
    try {
      final repository = ref.read(tournamentRepositoryProvider);

      if (_isEditing) {
        final existing = await repository.fetchById(widget.tournamentId!);
        if (existing == null) throw StateError(l10n.eventNotFound);
        if (_parsedTeams < existing.totalConfirmed) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.capBelowConfirmed(existing.totalConfirmed)),
            ),
          );
          return;
        }
        // Keep open/full in sync with the new capacity: every other count
        // change goes through applyConfirmedDelta/the DB trigger, but the
        // edit path would leave a raised-capacity event stuck as "full".
        final status = existing.status == TournamentStatus.closed
            ? TournamentStatus.closed
            : _parsedTeams <= existing.totalConfirmed
            ? TournamentStatus.full
            : TournamentStatus.open;
        final updated = existing.copyWith(
          sport: _sport,
          kind: _kind,
          title: _title.text.trim(),
          description: _description.text.trim(),
          prizes: _prizes.text.trim(),
          startTime: _start,
          endTime: _end,
          inscriptionCost: _parsedCost,
          totalTeams: _parsedTeams,
          venueName: _venue.text.trim(),
          address: _address.text.trim(),
          city: _city.text.trim(),
          location: () => _pin,
          status: status,
        );
        await repository.update(updated);
        invalidateOrganizerState(container, tournamentId: updated.id);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.eventSaved)));
      } else {
        await repository.create(
          TournamentModel(
            // The repository assigns the id.
            id: '',
            ownerId: session.userId,
            sport: _sport,
            kind: _kind,
            title: _title.text.trim(),
            description: _description.text.trim(),
            prizes: _prizes.text.trim(),
            startTime: _start,
            endTime: _end,
            inscriptionCost: _parsedCost,
            totalTeams: _parsedTeams,
            venueName: _venue.text.trim(),
            address: _address.text.trim(),
            city: _city.text.trim(),
            location: _pin,
          ),
        );
        container
          ..invalidate(myTournamentsProvider)
          ..invalidate(exploreResultsProvider);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.eventPublished)));
      }

      if (mounted) context.pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.eventSaveError(error))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

/// How a pin→address completion went.
enum _AddressResult { completed, unchanged, failed }
