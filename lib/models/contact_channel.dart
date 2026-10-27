import 'package:flutter/material.dart';
import 'package:tande/models/user_model.dart';

/// One way of reaching a person.
///
/// Amateur tournaments are coordinated almost entirely off-app, and WhatsApp
/// is only one of the channels: a club runs sign-ups on a Google Form, a
/// padel organizer answers on Instagram, a league has a Telegram group. The
/// app should open whatever the person actually uses instead of forcing
/// WhatsApp as the only door.
enum ContactKind { whatsapp, call, instagram, telegram, link }

@immutable
class ContactChannel {
  const ContactChannel({
    required this.kind,
    required this.target,
    this.label = '',
  });

  final ContactKind kind;

  /// The raw value to act on: a phone (digits, country code), a handle or a
  /// URL depending on [kind].
  final String target;

  /// What that channel is called in the UI ("Instagram", "Formulario de
  /// inscripción"). Empty means the kind's own name.
  final String label;

  IconData get icon => switch (kind) {
    ContactKind.whatsapp => Icons.chat_bubble_outline,
    ContactKind.call => Icons.call_outlined,
    ContactKind.instagram => Icons.camera_alt_outlined,
    ContactKind.telegram => Icons.send_outlined,
    ContactKind.link => Icons.link,
  };
}

extension ContactChannels on UserModel {
  /// True when there is a channel beyond the phone. Only then does the UI ask
  /// "which one?" — with a phone and nothing else, WhatsApp stays one tap.
  bool get hasExtraContactChannels =>
      instagram.isNotEmpty || telegram.isNotEmpty || contactUrl.isNotEmpty;
}

/// The channels [user] can actually be reached on, in the order they are
/// offered. Phone first: it is what every player has and what payments are
/// coordinated through.
///
/// [linkLabel] names the free-form link (the organizer decides whether it is a
/// sign-up form, a spreadsheet or a club site).
List<ContactChannel> contactChannelsOf(
  UserModel user, {
  String linkLabel = '',
}) {
  return [
    if (user.phone.isNotEmpty)
      ContactChannel(kind: ContactKind.whatsapp, target: user.phone),
    if (user.phone.isNotEmpty)
      ContactChannel(kind: ContactKind.call, target: user.phone),
    if (user.instagram.isNotEmpty)
      ContactChannel(kind: ContactKind.instagram, target: user.instagram),
    if (user.telegram.isNotEmpty)
      ContactChannel(kind: ContactKind.telegram, target: user.telegram),
    if (user.contactUrl.isNotEmpty)
      ContactChannel(
        kind: ContactKind.link,
        target: user.contactUrl,
        label: linkLabel,
      ),
  ];
}
