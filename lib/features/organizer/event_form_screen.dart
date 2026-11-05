import 'dart:async';
import 'dart:typed_data';

import 'package:tande/core/constants.dart';
import 'package:tande/core/location/reverse_geocoder.dart';
import 'package:tande/core/map/basemap_layer.dart';
import 'package:tande/core/observability/analytics.dart';
import 'package:tande/core/theme/adaptive.dart';
import 'package:tande/core/utils/country_code.dart';
import 'package:tande/core/utils/format.dart';
import 'package:tande/data/repositories/providers.dart';
import 'package:tande/features/explore/explore_providers.dart';
import 'package:tande/features/organizer/organizer_providers.dart';
import 'package:tande/features/tournament/tournament_providers.dart';
import 'package:tande/l10n/generated/app_localizations.dart';
import 'package:tande/l10n/labels.dart';
import 'package:tande/models/tournament_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:tande/core/widgets/tande_toast.dart';
import 'package:tande/core/map/tile_source.dart';

/// Fallback map center until the device location arrives (Montevideo).
const _defaultCenter = LatLng(-34.9012, -56.1646);

/// Create or edit an event (with a tap-to-place venue pin on the map).
class EventFormScreen extends ConsumerStatefulWidget {
  const EventFormScreen({super.key, this.tournamentId, this.duplicateOfId});

  /// `null` creates a new event; otherwise the event to edit.
  final String? tournamentId;

  /// Event to copy into a brand-new one (create flow, dates shifted a week,
  /// banner left out). Mutually exclusive with [tournamentId].
  final String? duplicateOfId;

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
  late String _currency;
  late DateTime _start;
  late DateTime _end;
  LatLng? _pin;

  /// Banner state: freshly picked bytes (not uploaded yet), the stored
  /// path when editing, and a removed path whose object is deleted after
  /// the save lands.
  Uint8List? _bannerBytes;
  String? _bannerPath;
  String? _clearedBanner;

  final _mapController = MapController();

  /// Pending reverse-geocode after a map tap (see [_onMapTapped]).
  Timer? _pinDebounce;

  bool _prefilled = false;
  bool _saving = false;
  bool _locating = false;

  bool get _isEditing => widget.tournamentId != null;
  bool get _isDuplicate => widget.duplicateOfId != null;

  @override
  void initState() {
    super.initState();
    // New event: the device region's currency (locale countryCode → the
    // country table, home market otherwise). Editing overwrites this with
    // the stored value in _applyTournament.
    _currency = _deviceCurrency();
    final initial = DateTime.now().add(const Duration(days: 7));
    _start = DateTime(initial.year, initial.month, initial.day, 19);
    _end = DateTime(initial.year, initial.month, initial.day, 23);
  }

  /// Default currency for a new tournament: the phone's region mapped
  /// through [countryCodes] (audit 4.9), the home market for locales
  /// without a region or outside the table.
  static String _deviceCurrency() {
    final region =
        WidgetsBinding.instance.platformDispatcher.locale.countryCode;
    if (region != null && region.isNotEmpty) {
      final country = countryForIso(region);
      if (country != null) return country.currency;
    }
    return defaultCurrency;
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
    _currency = tournament.currency;
    _start = tournament.startTime;
    _end = tournament.endTime;
    _pin = tournament.location;
    _bannerPath = tournament.bannerPath;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Editing loads the event itself; duplicating loads the source event and
    // copies it into a *new* one — same provider, different post-processing.
    final sourceId = widget.tournamentId ?? widget.duplicateOfId;
    if (sourceId == null) return _formScaffold();

    final tournamentAsync = ref.watch(tournamentProvider(sourceId));
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
          if (_isDuplicate) {
            // A duplicate is "the same tournament, next week": shift both
            // dates and drop the banner (reusing the stored object would tie
            // the two rows to one upload, and deleting one would break the
            // other). Everything else — venue, cupo, precio, moneda — carries.
            _start = tournament.startTime.add(const Duration(days: 7));
            _end = tournament.endTime.add(const Duration(days: 7));
            _bannerPath = null;
          }
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
            const SizedBox(height: 12),
            _sectionLabel(context, l10n.bannerSectionLabel),
            Text(
              l10n.bannerHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            _bannerField(l10n),
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
            // Amount and currency in one row: the prefix tracks the
            // selection, so typing 25 after picking EUR reads "€ 25".
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('event-cost'),
                    controller: _cost,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.costLabel,
                      hintText: l10n.costFreeHint,
                      prefixText: '${currencySymbol(_currency)} ',
                    ),
                    validator: (value) => _costValidator(value, l10n),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 132,
                  child: DropdownButtonFormField<String>(
                    key: const Key('event-currency'),
                    initialValue: currencies.contains(_currency)
                        ? _currency
                        : defaultCurrency,
                    // Same shape as the dial-code dropdown: expanded so the
                    // closed field ellipsizes instead of overflowing.
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l10n.currencyLabel),
                    items: [
                      for (final code in currencies)
                        DropdownMenuItem(
                          value: code,
                          child: Text('$code  ${currencySymbol(code)}'),
                        ),
                    ],
                    selectedItemBuilder: (context) => [
                      for (final code in currencies)
                        Text(code, overflow: TextOverflow.ellipsis),
                    ],
                    onChanged: (code) =>
                        setState(() => _currency = code ?? defaultCurrency),
                  ),
                ),
              ],
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
                        const BasemapLayer(),
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
                        ref.watch(tileSourceProvider).attribution,
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

  /// Optional banner: nothing → "add" button; a pick or a stored banner →
  /// preview with change/remove. Nothing here is required to save.
  Widget _bannerField(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final pending = _bannerBytes != null;
    if (!pending && _bannerPath == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          key: const Key('event-banner-add'),
          onPressed: _pickBanner,
          icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
          label: Text(l10n.bannerAdd),
        ),
      );
    }
    // Pending picks preview their own bytes; stored ones resolve through
    // the storage service (public URL / in-memory mock).
    final ImageProvider image = pending
        ? MemoryImage(_bannerBytes!)
        : ref.read(bannerStorageProvider).imageFor(_bannerPath!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image(
            key: const Key('event-banner-preview'),
            image: image,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => ColoredBox(
              color: theme.colorScheme.surfaceContainerHighest,
              child: const SizedBox(height: 120),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            TextButton.icon(
              key: const Key('event-banner-change'),
              onPressed: _pickBanner,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(l10n.bannerChange),
            ),
            const Spacer(),
            IconButton(
              key: const Key('event-banner-remove'),
              onPressed: _removeBanner,
              tooltip: l10n.bannerRemove,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ],
    );
  }

  /// Opens the gallery; a cancelled pick keeps whatever was there.
  Future<void> _pickBanner() async {
    final bytes = await ref.read(bannerPickerProvider).pick();
    if (bytes == null || !mounted) return;
    setState(() {
      _bannerBytes = bytes;
      _clearedBanner = null; // A pick after a remove restores the banner.
    });
  }

  void _removeBanner() {
    setState(() {
      if (_bannerBytes != null) {
        // Only the unsaved pick goes; the stored banner (if any) stays.
        _bannerBytes = null;
      } else if (_bannerPath != null) {
        _clearedBanner = _bannerPath;
        _bannerPath = null;
      }
    });
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
        showTandeToast(context, l10n.locationDenied);
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

      showTandeToast(context, switch (result) {
        _AddressResult.failed => l10n.locationNoAddress,
        _AddressResult.completed => l10n.addressFilled,
        _AddressResult.unchanged => l10n.locationUpdated,
      }, kind: ToastKind.error);
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
      showTandeToast(context, l10n.addressFailed, kind: ToastKind.error);
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
      showTandeToast(context, l10n.endDateBeforeStart);
      return;
    }

    final session = ref.read(authStateProvider);
    if (session == null) return;

    // Captured before the awaits: `ref` throws once disposed, and the
    // caches must refresh even if the user navigates away mid-save.
    final container = ProviderScope.containerOf(context, listen: false);

    // Set before the Pro check so a double tap cannot start two saves.
    setState(() => _saving = true);

    // Last gate before the insert: the route-level ProGate checked when the
    // form opened, but the free-tier count can change while it is open (for
    // example, another device creates an event). Editing never adds an
    // active tournament, so it is always allowed.
    if (!_isEditing && !await canCreateActiveTournament(ref)) {
      if (!mounted) return;
      setState(() => _saving = false);
      context.push('/pro');
      return;
    }

    try {
      final repository = ref.read(tournamentRepositoryProvider);

      if (_isEditing) {
        final existing = await repository.fetchById(widget.tournamentId!);
        if (existing == null) throw StateError(l10n.eventNotFound);
        if (_parsedTeams < existing.totalConfirmed) {
          if (!mounted) return;
          showTandeToast(
            context,
            l10n.capBelowConfirmed(existing.totalConfirmed),
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
        // A fresh pick uploads before the update so its path rides the
        // single row write; a removal clears the column (its object goes
        // after the save). An upload failure keeps the stored banner
        // (and is reported after the save, which still goes through).
        var bannerPath = existing.bannerPath;
        var bannerFailed = false;
        final picked = _bannerBytes;
        if (picked != null) {
          try {
            bannerPath = await repository.uploadBanner(existing.id, picked);
          } catch (_) {
            bannerFailed = true;
          }
        } else if (_clearedBanner != null) {
          bannerPath = null;
        }
        final updated = existing.copyWith(
          sport: _sport,
          kind: _kind,
          title: _title.text.trim(),
          description: _description.text.trim(),
          prizes: _prizes.text.trim(),
          startTime: _start,
          endTime: _end,
          inscriptionCost: _parsedCost,
          currency: _currency,
          totalTeams: _parsedTeams,
          venueName: _venue.text.trim(),
          address: _address.text.trim(),
          city: _city.text.trim(),
          location: () => _pin,
          bannerPath: () => bannerPath,
          status: status,
        );
        await repository.update(updated);
        container.read(analyticsProvider).track('tournament_updated', {
          'tournament_id': updated.id,
          'sport': _sport,
          'kind': _kind,
        });
        // The removed banner's object only goes once the row stopped
        // pointing at it.
        if (_clearedBanner != null) {
          await repository.removeBanner(_clearedBanner!);
        }
        invalidateOrganizerState(container, tournamentId: updated.id);
        // Explore caches its results: an edit changes what the cards show
        // (title, cost, dates, banner), so refresh it like the create path
        // does.
        container.invalidate(exploreResultsProvider);
        if (!mounted) return;
        showTandeToast(
          context,
          bannerFailed ? l10n.bannerSaveFailed : l10n.eventSaved,
          kind: bannerFailed ? ToastKind.error : ToastKind.success,
        );
      } else {
        final created = await repository.create(
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
            currency: _currency,
            totalTeams: _parsedTeams,
            venueName: _venue.text.trim(),
            address: _address.text.trim(),
            city: _city.text.trim(),
            location: _pin,
          ),
        );
        container.read(analyticsProvider).track('tournament_created', {
          'tournament_id': created.id,
          'sport': _sport,
          'kind': _kind,
          'teams': _parsedTeams,
          'currency': _currency,
        });
        // The banner needs the assigned id, so it uploads (and persists
        // its path) right after the row exists. A failure keeps the event
        // — the organizer just re-adds the image from Editar.
        var bannerFailed = false;
        final picked = _bannerBytes;
        if (picked != null) {
          try {
            final path = await repository.uploadBanner(created.id, picked);
            await repository.update(created.copyWith(bannerPath: () => path));
          } catch (_) {
            bannerFailed = true;
          }
        }
        container
          ..invalidate(myTournamentsProvider)
          ..invalidate(exploreResultsProvider);
        if (!mounted) return;
        showTandeToast(
          context,
          bannerFailed ? l10n.bannerSaveFailed : l10n.eventPublished,
          kind: bannerFailed ? ToastKind.error : ToastKind.success,
        );
      }

      if (mounted) context.pop();
    } catch (error) {
      if (mounted) {
        showTandeToast(
          context,
          l10n.eventSaveError(error),
          kind: ToastKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

/// How a pin→address completion went.
enum _AddressResult { completed, unchanged, failed }
