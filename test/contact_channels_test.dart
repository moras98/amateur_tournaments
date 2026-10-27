import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tande/core/utils/contact.dart';
import 'package:tande/core/widgets/contact_sheet.dart';
import 'package:tande/l10n/generated/app_localizations.dart';
import 'package:tande/models/contact_channel.dart';
import 'package:tande/models/user_model.dart';

UserModel player({
  String phone = '',
  String instagram = '',
  String telegram = '',
  String contactUrl = '',
}) {
  return UserModel(
    id: 'u-1',
    username: 'jugador',
    fullName: 'Jugador Uno',
    gender: 'm',
    phone: phone,
    instagram: instagram,
    telegram: telegram,
    contactUrl: contactUrl,
  );
}

void main() {
  group('normalizar handles', () {
    test('instagram acepta @, handle pelado y URL completa', () {
      expect(normalizeInstagram('@club_atletico'), 'club_atletico');
      expect(normalizeInstagram('club_atletico'), 'club_atletico');
      expect(normalizeInstagram('  @club_atletico  '), 'club_atletico');
      expect(
        normalizeInstagram('https://www.instagram.com/club_atletico/'),
        'club_atletico',
      );
      expect(
        normalizeInstagram('instagram.com/club_atletico?hl=es'),
        'club_atletico',
      );
      // Un post no es un perfil: se queda con el primer segmento.
      expect(
        normalizeInstagram('instagram.com/club_atletico/p/ABC123'),
        'club_atletico',
      );
      expect(normalizeInstagram('   '), '');
    });

    test('telegram acepta @, handle y t.me', () {
      expect(normalizeTelegram('@cancha_sur'), 'cancha_sur');
      expect(normalizeTelegram('cancha_sur'), 'cancha_sur');
      expect(normalizeTelegram('https://t.me/cancha_sur'), 'cancha_sur');
      expect(normalizeTelegram('telegram.me/cancha_sur'), 'cancha_sur');
      expect(normalizeTelegram(''), '');
    });

    test('el enlace gana esquema solo si le falta', () {
      expect(normalizeContactUrl('forms.gle/abc'), 'https://forms.gle/abc');
      expect(
        normalizeContactUrl('https://forms.gle/abc'),
        'https://forms.gle/abc',
      );
      expect(normalizeContactUrl('http://club.uy'), 'http://club.uy');
      expect(normalizeContactUrl('  '), '');
    });
  });

  group('vias disponibles', () {
    test('solo telefono: WhatsApp y llamada, sin selector', () {
      final user = player(phone: '59891123456');
      final kinds = contactChannelsOf(user).map((c) => c.kind).toList();

      expect(kinds, [ContactKind.whatsapp, ContactKind.call]);
      // Nada que elegir: la tarjeta sigue abriendo WhatsApp de una.
      expect(user.hasExtraContactChannels, isFalse);
    });

    test('las vias extra se suman en orden, despues del telefono', () {
      final user = player(
        phone: '59891123456',
        instagram: 'club',
        telegram: 'clubchat',
        contactUrl: 'https://forms.gle/abc',
      );
      final kinds = contactChannelsOf(
        user,
        linkLabel: 'Formulario',
      ).map((c) => c.kind).toList();

      expect(kinds, [
        ContactKind.whatsapp,
        ContactKind.call,
        ContactKind.instagram,
        ContactKind.telegram,
        ContactKind.link,
      ]);
      expect(user.hasExtraContactChannels, isTrue);
    });

    test('sin telefono pero con Instagram: hay una via igual', () {
      final user = player(instagram: 'club');

      expect(contactChannelsOf(user).single.kind, ContactKind.instagram);
      expect(user.hasContactChannels, isTrue);
      expect(user.canBeContacted, isFalse);
    });

    test('sin nada: no hay vias', () {
      expect(contactChannelsOf(player()), isEmpty);
      expect(player().hasContactChannels, isFalse);
    });

    test('el enlace lleva la etiqueta que decide el organizador', () {
      final channel = contactChannelsOf(
        player(contactUrl: 'https://forms.gle/abc'),
        linkLabel: 'Formulario de inscripción',
      ).single;

      expect(channel.label, 'Formulario de inscripción');
      expect(channel.target, 'https://forms.gle/abc');
    });
  });

  group('hoja de contacto', () {
    /// Captures what the sheet asks the platform to open.
    List<String> captureLaunches(WidgetTester tester) {
      final launched = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/url_launcher'),
        (call) async {
          launched.add('${call.arguments['url']}');
          return true;
        },
      );
      return launched;
    }

    testWidgets('lista las vias y abre Instagram con el handle normalizado', (
      tester,
    ) async {
      final launched = captureLaunches(tester);
      final user = player(phone: '59891123456', instagram: 'club_atletico');

      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          // The sheet reads AppLocalizations: the app always installs them.
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es', 'UY'),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () async {
                    result = await showContactSheet(
                      context: context,
                      title: 'Contactar a Club A',
                      channels: contactChannelsOf(user),
                      message: 'Hola',
                    );
                  },
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Contactar a Club A'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('Llamar'), findsOneWidget);
      expect(find.text('Instagram'), findsOneWidget);
      expect(find.text('@club_atletico'), findsOneWidget);

      await tester.tap(find.text('Instagram'));
      await tester.pumpAndSettle();

      expect(launched, ['https://instagram.com/club_atletico']);
      expect(result, isTrue);
    });

    testWidgets('un enlace sin esquema no se abre y lo informa', (
      tester,
    ) async {
      final launched = captureLaunches(tester);
      // Stored raw on purpose: openLink refuses what the app never writes.
      final user = player(contactUrl: 'forms.gle/abc');

      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          // The sheet reads AppLocalizations: the app always installs them.
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es', 'UY'),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () async {
                    result = await showContactSheet(
                      context: context,
                      title: 'Contactar',
                      channels: contactChannelsOf(user),
                    );
                  },
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ver enlace'));
      await tester.pumpAndSettle();

      expect(launched, isEmpty);
      expect(result, isFalse);
    });
  });
}
