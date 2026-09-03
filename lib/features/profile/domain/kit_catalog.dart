import 'cyclist_kit.dart';
import 'level_info.dart';

/// Catálogo de todo lo que se puede llevar en la subida: los 6 maillots
/// y las 6 bicis de rango (cambian de color con el rango, se desbloquean
/// al llegar) más las piezas especiales y gestos que se ganan por logros
/// concretos, y los 3 sets temáticos. (Las voces de guía viven en
/// `features/voice/`, con su propio sistema de desbloqueo.)
///
/// Es contenido de producto -- editable sin tocar la lógica. Los ids son
/// estables (se guardan en `SharedPreferences`).
class KitCatalog {
  KitCatalog._();

  // --- Piezas de rango (índice 0 = Novato ... 5 = Leyenda) ------------
  static const _rankNames = [
    'principiante',
    'rodador',
    'escalador',
    'fondista',
    'élite',
    'leyenda',
  ];
  static const _rankMinLevels = [1, 5, 10, 15, 20, 25];

  static final List<KitItem> _rankMaillots = [
    for (var i = 0; i < 6; i++)
      KitItem(
        id: 'maillot_r$i',
        slot: KitSlot.maillot,
        name: 'Maillot de ${_rankNames[i]}',
        description: 'El maillot de tu rango. Cambia de color al subir.',
        unlock: KitUnlockCondition(
          KitUnlockKind.rankReached,
          value: _rankMinLevels[i].toDouble(),
        ),
        rankTierIndex: i,
      ),
  ];

  static final List<KitItem> _rankBikes = [
    for (var i = 0; i < 6; i++)
      KitItem(
        id: 'bici_r$i',
        slot: KitSlot.bici,
        name: 'Bici de ${_rankNames[i]}',
        description: 'Tu bici mejora y cambia de color con el rango.',
        unlock: KitUnlockCondition(
          KitUnlockKind.rankReached,
          value: _rankMinLevels[i].toDouble(),
        ),
        rankTierIndex: i,
      ),
  ];

  // --- Piezas especiales por logros ----------------------------------
  static const _specials = <KitItem>[
    KitItem(
      id: 'maillot_lunares',
      slot: KitSlot.maillot,
      name: 'Maillot de lunares',
      description: 'El de los mejores escaladores. Homenaje al escarabajo.',
      unlock: KitUnlockCondition(
        KitUnlockKind.rankCompleted,
        rank: CyclistRank.escalador,
      ),
      setId: 'set_escarabajo',
    ),
    KitItem(
      id: 'bici_ligera',
      slot: KitSlot.bici,
      name: 'Bici blanca ligera',
      description: 'Sin gramo de más. Para las rampas.',
      unlock: KitUnlockCondition(
        KitUnlockKind.rankCompleted,
        rank: CyclistRank.escalador,
      ),
      setId: 'set_escarabajo',
    ),
    KitItem(
      id: 'maillot_aero',
      slot: KitSlot.maillot,
      name: 'Maillot aero',
      description: 'Ajustado, sin arrugas. Para ir rápido.',
      unlock: KitUnlockCondition(KitUnlockKind.rideSpeedKmh, value: 34),
      setId: 'set_contrarreloj',
    ),
    KitItem(
      id: 'bici_aero',
      slot: KitSlot.bici,
      name: 'Bici de contrarreloj',
      description: 'Cuadro de perfil, ruedas lenticulares.',
      unlock: KitUnlockCondition(KitUnlockKind.rideSpeedKmh, value: 34),
      setId: 'set_contrarreloj',
    ),
    KitItem(
      id: 'bici_perfil',
      slot: KitSlot.bici,
      name: 'Ruedas de perfil',
      description: 'Ruedas más altas para rodar en llano.',
      unlock: KitUnlockCondition(KitUnlockKind.totalKm, value: 3000),
    ),
    KitItem(
      id: 'maillot_lana',
      slot: KitSlot.maillot,
      name: 'Maillot de lana',
      description: 'A la vieja usanza. Para las salidas largas.',
      unlock: KitUnlockCondition(KitUnlockKind.longestRideKm, value: 100),
      setId: 'set_randonneur',
    ),
    KitItem(
      id: 'bici_acero',
      slot: KitSlot.bici,
      name: 'Bici de acero',
      description: 'Con alforjas y luces. Aguanta lo que le eches.',
      unlock: KitUnlockCondition(KitUnlockKind.longestRideKm, value: 100),
      setId: 'set_randonneur',
    ),
  ];

  // --- Gestos (animaciones extra del muñequito) ---------------------
  static const _gestos = <KitItem>[
    KitItem(
      id: 'gesto_beber',
      slot: KitSlot.gesto,
      name: 'Beber del bidón',
      description: 'Toma agua en las salidas largas.',
      unlock: KitUnlockCondition.always,
      setId: 'set_randonneur',
    ),
    KitItem(
      id: 'gesto_danzar',
      slot: KitSlot.gesto,
      name: 'Danzar en los pedales',
      description: 'Se para en los pedales en las rampas duras.',
      unlock: KitUnlockCondition.always,
      setId: 'set_escarabajo',
    ),
    KitItem(
      id: 'gesto_wheelie',
      slot: KitSlot.gesto,
      name: 'Wheelie al cruzar un arco',
      description: 'Levanta la rueda al pasar un punto de interés.',
      unlock: KitUnlockCondition(KitUnlockKind.postales, value: 15),
    ),
    KitItem(
      id: 'gesto_bandera',
      slot: KitSlot.gesto,
      name: 'Bandera al coronar',
      description: 'Alza una bandera al completar un rango.',
      unlock: KitUnlockCondition(
        KitUnlockKind.rankCompleted,
        rank: CyclistRank.rodador,
      ),
    ),
    KitItem(
      id: 'gesto_aero',
      slot: KitSlot.gesto,
      name: 'Posición aero',
      description: 'Se agacha sobre el manillar para cortar el viento.',
      unlock: KitUnlockCondition(KitUnlockKind.rideSpeedKmh, value: 34),
      setId: 'set_contrarreloj',
    ),
  ];

  static final List<KitItem> items = [
    ..._rankMaillots,
    ..._rankBikes,
    ..._specials,
    ..._gestos,
  ];

  static final Map<String, KitItem> byId = {
    for (final item in items) item.id: item,
  };

  static List<KitItem> forSlot(KitSlot slot) =>
      items.where((i) => i.slot == slot).toList();

  static const sets = <KitSet>[
    KitSet(
      id: 'set_escarabajo',
      name: 'Escarabajo',
      description: 'Homenaje a los escaladores colombianos.',
      itemIds: ['maillot_lunares', 'bici_ligera', 'gesto_danzar'],
    ),
    KitSet(
      id: 'set_contrarreloj',
      name: 'Contrarreloj',
      description: 'Todo para ir contra el crono.',
      itemIds: ['maillot_aero', 'bici_aero', 'gesto_aero'],
    ),
    KitSet(
      id: 'set_randonneur',
      name: 'Randonneur',
      description: 'Para las jornadas de kilómetros y kilómetros.',
      itemIds: ['maillot_lana', 'bici_acero', 'gesto_beber'],
    ),
  ];

  static KitSet? setById(String? id) {
    if (id == null) return null;
    for (final set in sets) {
      if (set.id == id) return set;
    }
    return null;
  }

  /// Kit por defecto: rango más bajo + los dos gestos base.
  static const defaultKit = CyclistKit(
    maillotId: 'maillot_r0',
    biciId: 'bici_r0',
    gestoIds: {'gesto_beber', 'gesto_danzar'},
  );
}
