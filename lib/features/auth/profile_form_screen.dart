import 'dart:async';

import 'package:tande/core/location/reverse_geocoder.dart';
import 'package:tande/core/theme/adaptive.dart';
import 'package:tande/core/utils/age.dart';
import 'package:tande/core/utils/contact.dart';
import 'package:tande/core/utils/country_code.dart';
import 'package:tande/data/repositories/providers.dart';
import 'package:tande/features/auth/widgets/profile_fields.dart';
import 'package:tande/features/explore/explore_providers.dart';
import 'package:tande/features/organizer/organizer_providers.dart';
import 'package:tande/features/tournament/tournament_providers.dart';
import 'package:tande/l10n/generated/app_localizations.dart';
import 'package:tande/l10n/labels.dart';
import 'package:tande/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tande/core/widgets/tande_toast.dart';

/// Creates or edits the signed-in user's profile.
///
/// Reached from the Profile tab ("Edit profile"), and as the fallback for
/// first-time OAuth sign-ins and the email-confirmation sign-up flow —
/// regular sign-up collects the profile itself and never lands here.
class ProfileFormScreen extends ConsumerStatefulWidget {
  const ProfileFormScreen({super.key});

  @override
  ConsumerState<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends ConsumerState<ProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _instagramController = TextEditingController();
  final _telegramController = TextEditingController();
  final _contactUrlController = TextEditingController();

  DateTime? _birthDate;
  String _gender = '';
  List<String> _sports = ['football'];
  bool _isOrganizer = false;
  bool _hydrated = false;
  bool _loading = false;

  // Debounced live uniqueness check for the username (250 ms, like the
  // sign-up form), excluding this profile's own handle.
  Timer? _usernameDebounce;
  bool _usernameTaken = false;

  /// Dial code shown next to the phone field; the stored phone stays one
  /// international digit string (`5491122334455`, no `+`).
  String _dialCode = defaultCountryCode.dial;

  /// The user picked a dial code themselves (location no longer applies).
  bool _dialTouched = false;

  /// The user changed the dial code or typed in the phone field.
  bool _phoneEdited = false;

  /// The stored number doesn't start with a dial code we know: it is kept
  /// verbatim on save unless the user edits it.
  bool _phoneHadUnknownDial = false;

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _usernameController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _instagramController.dispose();
    _telegramController.dispose();
    _contactUrlController.dispose();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    _usernameDebounce?.cancel();
    final username = value.trim();
    _usernameDebounce = Timer(const Duration(milliseconds: 250), () async {
      final me = ref.read(currentProfileProvider).valueOrNull;
      final taken = username.isEmpty
          ? false
          : await ref
                .read(profileRepositoryProvider)
                .isUsernameTaken(username, excludingId: me?.id);
      if (!mounted) return;
      setState(() => _usernameTaken = taken);
    });
  }

  /// Seeds the form from the loaded profile exactly once, so typing never
  /// gets overwritten by a rebuild.
  void _hydrate(UserModel? profile, String? fallbackName) {
    if (_hydrated) return;
    _hydrated = true;

    _usernameController.text = profile?.username ?? '';
    _nameController.text = profile?.fullName.isNotEmpty == true
        ? profile!.fullName
        : (fallbackName ?? '');
    _hydratePhone(profile?.phone ?? '');
    _birthDate = profile?.birthDate;
    _gender = profile?.gender ?? '';
    _sports = profile?.sports.isNotEmpty == true
        ? List.of(profile!.sports)
        : const ['football'];
    _isOrganizer = profile?.isOrganizer ?? false;
    _instagramController.text = profile?.instagram ?? '';
    _telegramController.text = profile?.telegram ?? '';
    _contactUrlController.text = profile?.contactUrl ?? '';
  }

  /// Splits the stored international number into dial code + national part,
  /// or (no number yet) asks the device location which dial code to
  /// pre-select for the input.
  void _hydratePhone(String phone) {
    if (phone.isEmpty) {
      _applyLocationDial();
      return;
    }
    final split = splitIntlPhone(phone);
    if (split == null) {
      // A format outside [countryCodes]: show the digits untouched and let
      // an unedited save write them back byte-for-byte.
      _phoneHadUnknownDial = true;
      _phoneController.text = phone.replaceAll(RegExp(r'\D'), '');
      return;
    }
    _dialCode = split.dial;
    _phoneController.text = split.national;
  }

  /// Pre-selects the phone's dial code from the device position (reverse
  /// geocoded), so first-time input comes pre-filled with `+598` in
  /// Uruguay. Silent fallback to the app's default country when the
  /// position is denied/offline or the country isn't in [countryCodes].
  ///
  /// Never overrides a dial code the user picked, one parsed from a stored
  /// number, or the moment they already started typing.
  Future<void> _applyLocationDial() async {
    // Captured before the first await: `ref` throws once disposed.
    final geocoder = ref.read(reverseGeocodeProvider);
    final location = await ref
        .read(userLocationProvider.future)
        .catchError((_) => null);
    if (!mounted || location == null || _dialTouched) return;
    // Switching the dial code mid-typing would change what the number means.
    if (_phoneController.text.isNotEmpty) return;

    ResolvedAddress? address;
    try {
      address = await geocoder.resolve(location);
    } catch (_) {
      return;
    }
    if (!mounted || address == null || _dialTouched) return;
    if (_phoneController.text.isNotEmpty) return;

    final country = countryForIso(address.countryCode);
    if (country != null && country.dial != _dialCode) {
      setState(() => _dialCode = country.dial);
    }
  }

  /// The value persisted in `UserModel.phone`: dial code + digits — the
  /// format WhatsApp (`wa.me`) and the dialer expect. Empty field stays
  /// empty (the optional number isn't a bare `+598`), and an unedited number
  /// we couldn't split is written back verbatim rather than prefixed.
  String _phoneDigits() {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    if (_phoneHadUnknownDial && !_phoneEdited) return digits;
    return '$_dialCode$digits';
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showAdaptiveDatePicker(
      context,
      initialDate: _birthDate ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (picked == null || !mounted) return;
    setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l10n = AppLocalizations.of(context)!;
    if (_sports.isEmpty) {
      showTandeToast(context, l10n.chooseSport);
      return;
    }
    if (_birthDate == null) {
      showTandeToast(context, l10n.chooseBirthDate);
      return;
    }
    // Same minimum-age gate as sign-up (Terms §3): an edit must not turn the
    // stored birth date into an under-18 one.
    if (!isAdult(_birthDate!)) {
      showTandeToast(context, l10n.mustBe18);
      return;
    }

    setState(() => _loading = true);

    // Captured before the await: `ref` throws once disposed, and profile
    // changes must reach the joined views (organizer card, WhatsApp
    // numbers, request list) even if the user navigates away mid-save.
    final container = ProviderScope.containerOf(context, listen: false);
    try {
      final session = ref.read(authStateProvider);
      if (session == null) {
        showTandeToast(context, l10n.noSession);
        return;
      }

      final existing = await ref
          .read(profileRepositoryProvider)
          .fetchById(session.userId);

      final profile =
          (existing ??
                  UserModel(
                    id: session.userId,
                    username: '',
                    fullName: '',
                    gender: '',
                  ))
              .copyWith(
                username: _usernameController.text.trim(),
                fullName: _nameController.text.trim(),
                birthDate: () => _birthDate,
                gender: _gender,
                phone: _phoneDigits(),
                // Same normalisation the launcher applies: the stored value
                // is the bare handle, so the sheet can show "@club" and the
                // profile survives a user pasting a full URL.
                instagram: normalizeInstagram(_instagramController.text),
                telegram: normalizeTelegram(_telegramController.text),
                contactUrl: normalizeContactUrl(_contactUrlController.text),
                isOrganizer: _isOrganizer,
                sports: _sports,
              );

      await ref.read(profileRepositoryProvider).save(profile);
      container
        ..invalidate(currentProfileProvider)
        // Joined profile views outlive this screen: the tournament
        // detail's organizer card (WhatsApp number!) and the organizer's
        // request list (player name/phone) embed profiles.
        ..invalidate(organizerProvider)
        ..invalidate(tournamentInscriptionsProvider);

      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        // Post-signup: return to wherever the user originally headed.
        final from = GoRouterState.of(context).uri.queryParameters['from'];
        final destination = from != null && from.startsWith('/')
            ? from
            : '/explore';
        context.go(destination);
      }
    } catch (e) {
      if (mounted) {
        showTandeToast(context, l10n.saveFailed('$e'), kind: ToastKind.error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    final session = ref.watch(authStateProvider);
    final isEdit = profileAsync.valueOrNull?.isComplete ?? false;
    final fallbackName = session?.email.split('@').first;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(l10n.loadError('$error'))),
        data: (profile) {
          _hydrate(profile, fallbackName);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(labelText: l10n.fullName),
                          validator: (value) => (value ?? '').trim().isNotEmpty
                              ? null
                              : l10n.enterName,
                        ),
                        const SizedBox(height: 12),
                        UsernameField(
                          controller: _usernameController,
                          isTaken: _usernameTaken,
                          onChanged: _onUsernameChanged,
                        ),
                        const SizedBox(height: 12),
                        BirthDateField(
                          value: _birthDate,
                          onTap: _pickBirthDate,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.gender,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        GenderChips(
                          selected: _gender,
                          onChanged: (gender) => setState(() {
                            _gender = gender;
                          }),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.sportsYouPlay,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        SportsChips(
                          selected: _sports,
                          onToggle: (sport) => setState(() {
                            _sports = List.of(_sports);
                            _sports.contains(sport)
                                ? _sports.remove(sport)
                                : _sports.add(sport);
                          }),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 104,
                              child: DropdownButtonFormField<String>(
                                initialValue: _dialCode,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: l10n.country,
                                ),
                                items: [
                                  for (final country in countryCodes)
                                    DropdownMenuItem(
                                      value: country.dial,
                                      child: Text(
                                        '${country.dialLabel}  '
                                        '${l10n.countryName(country.iso)}',
                                      ),
                                    ),
                                ],
                                selectedItemBuilder: (context) => [
                                  for (final country in countryCodes)
                                    Text(country.dialLabel),
                                ],
                                onChanged: (dial) {
                                  if (dial == null) return;
                                  setState(() {
                                    _dialCode = dial;
                                    _dialTouched = true;
                                    _phoneEdited = true;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                onChanged: (_) => _phoneEdited = true,
                                decoration: InputDecoration(
                                  labelText: l10n.phoneOptional,
                                  helperText: l10n.phoneHelp,
                                ),
                                validator: (value) {
                                  final digits = (value ?? '').replaceAll(
                                    RegExp(r'\D'),
                                    '',
                                  );
                                  if (digits.isEmpty) return null;
                                  return (_dialCode.length + digits.length) >= 8
                                      ? null
                                      : l10n.phoneInvalid;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          l10n.contactChannelsTitle,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.contactChannelsHelp,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _instagramController,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: l10n.instagramOptional,
                            hintText: l10n.instagramHint,
                            prefixIcon: const Icon(
                              Icons.camera_alt_outlined,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _telegramController,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: l10n.telegramOptional,
                            hintText: l10n.telegramHint,
                            prefixIcon: const Icon(
                              Icons.send_outlined,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _contactUrlController,
                          keyboardType: TextInputType.url,
                          decoration: InputDecoration(
                            labelText: l10n.contactUrlOptional,
                            hintText: 'https://forms.gle/…',
                            helperText: l10n.contactUrlHelp,
                            prefixIcon: const Icon(Icons.link, size: 20),
                          ),
                          validator: (value) {
                            final normalized = normalizeContactUrl(value ?? '');
                            if (normalized.isEmpty) return null;
                            final uri = Uri.tryParse(normalized);
                            final valid =
                                uri != null &&
                                (uri.scheme == 'https' ||
                                    uri.scheme == 'http') &&
                                uri.host.contains('.');
                            return valid ? null : l10n.contactUrlInvalid;
                          },
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.organizerMode),
                          subtitle: Text(l10n.organizerModeHint),
                          trailing: AdaptiveSwitch(
                            value: _isOrganizer,
                            onChanged: (value) =>
                                setState(() => _isOrganizer = value),
                          ),
                          onTap: () =>
                              setState(() => _isOrganizer = !_isOrganizer),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _loading ? null : _save,
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  isEdit ? l10n.saveChanges : l10n.startButton,
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
