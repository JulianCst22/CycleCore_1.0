// Pruebas de arquitectura (fitness functions): hacen cumplir las reglas de
// la arquitectura modular de CycleCore sobre el código real. Si alguien
// agrega un import que rompe una regla, este test falla y dice cuál.
//
// Módulos:
//  - core_*      packages/core/<nombre>   infraestructura compartida
//  - <feature>   lib/features/<nombre>    módulos de negocio
//  - app         lib/main.dart + lib/app  raíz de composición
//
// Ver la documentación de cada regla en su `test`.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

const _layers = {'domain', 'data', 'application', 'presentation'};

/// Capas de una feature a las que NO puede importar cada capa.
const _forbiddenLayerImports = {
  'domain': {'data', 'application', 'presentation'},
  'data': {'application', 'presentation'},
  'application': {'presentation'},
  'presentation': <String>{},
};

/// Paquetes que atan una capa a Flutter o a Riverpod: el dominio es puro.
const _forbiddenInDomain = [
  'package:flutter/',
  'package:flutter_riverpod/',
  'package:core_ui/',
  'package:core_platform/',
];

class _Import {
  final String from;
  final String uri;
  final String? target;
  const _Import(this.from, this.uri, this.target);
}

final _directive = RegExp(
  r"^\s*(?:import|export)\s+'([^']+)'",
  multiLine: true,
);

List<String> _dartFiles(String dir) {
  final root = Directory(dir);
  if (!root.existsSync()) return const [];
  return root
      .listSync(recursive: true)
      .whereType<File>()
      .map((f) => f.path.replaceAll(r'\', '/'))
      .where((f) => f.endsWith('.dart') && !f.endsWith('.g.dart'))
      .toList()
    ..sort();
}

List<String> _sourceFiles() => [
  ..._dartFiles('lib'),
  for (final pkg in Directory(
    'packages/core',
  ).listSync().whereType<Directory>())
    ..._dartFiles('${pkg.path.replaceAll(r'\', '/')}/lib'),
];

String? _resolve(String from, String uri) {
  if (uri.startsWith('dart:')) return null;
  if (uri.startsWith('package:cyclecore_app/')) {
    return 'lib/${uri.substring('package:cyclecore_app/'.length)}';
  }
  final core = RegExp(r'^package:core_([a-z_]+)/(.+)$').firstMatch(uri);
  if (core != null) return 'packages/core/${core[1]}/lib/${core[2]}';
  if (uri.startsWith('package:')) return null;
  return p.posix.normalize(p.posix.join(p.posix.dirname(from), uri));
}

List<_Import> _imports() => [
  for (final file in _sourceFiles())
    for (final m in _directive.allMatches(File(file).readAsStringSync()))
      _Import(file, m[1]!, _resolve(file, m[1]!)),
];

/// Módulo al que pertenece un archivo del repo.
String _moduleOf(String path) {
  final parts = path.split('/');
  if (path.startsWith('packages/core/')) return 'core_${parts[2]}';
  if (path.startsWith('lib/features/')) return parts[2];
  return 'app';
}

/// Capa de un archivo de feature (`null` fuera de las features).
String? _layerOf(String path) {
  final parts = path.split('/');
  return path.startsWith('lib/features/') && parts.length > 4 ? parts[3] : null;
}

void main() {
  final imports = _imports();

  test('no hay dependencias circulares entre módulos', () {
    final graph = <String, Set<String>>{};
    for (final i in imports.where((i) => i.target != null)) {
      final from = _moduleOf(i.from), to = _moduleOf(i.target!);
      if (from != to) graph.putIfAbsent(from, () => {}).add(to);
    }

    final cycles = <String>[];
    final state = <String, int>{}; // 1 = visitando, 2 = listo
    final stack = <String>[];
    void visit(String module) {
      state[module] = 1;
      stack.add(module);
      for (final next in graph[module] ?? const <String>{}) {
        if (state[next] == 1) {
          cycles.add(
            [...stack.sublist(stack.indexOf(next)), next].join(' -> '),
          );
        } else if (state[next] == null) {
          visit(next);
        }
      }
      stack.removeLast();
      state[module] = 2;
    }

    for (final module in graph.keys) {
      if (state[module] == null) visit(module);
    }
    expect(
      cycles,
      isEmpty,
      reason: 'Ciclos entre módulos:\n${cycles.join('\n')}',
    );
  });

  test('los módulos core no conocen la app ni las features', () {
    final violations = [
      for (final i in imports)
        if (i.from.startsWith('packages/core/') &&
            i.target != null &&
            !_moduleOf(i.target!).startsWith('core_'))
          '${i.from} -> ${i.uri}',
    ];
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('entre features solo se importa la API pública (<feature>.dart)', () {
    final violations = [
      for (final i in imports)
        if (i.target != null &&
            i.target!.startsWith('lib/features/') &&
            _moduleOf(i.from) != _moduleOf(i.target!) &&
            i.target !=
                'lib/features/${_moduleOf(i.target!)}/${_moduleOf(i.target!)}.dart')
          '${i.from} -> ${i.uri}',
    ];
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('de un módulo core solo se importa su API pública (core_x.dart)', () {
    final violations = [
      for (final i in imports)
        if (i.uri.startsWith('package:core_') && i.uri.contains('/src/'))
          '${i.from} -> ${i.uri}',
    ];
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('las capas de cada feature respetan la regla de dependencia', () {
    final violations = <String>[];
    for (final i in imports) {
      final layer = _layerOf(i.from);
      if (layer == null || i.target == null) continue;
      final sameFeature = _moduleOf(i.from) == _moduleOf(i.target!);
      final targetLayer = _layerOf(i.target!);
      if (sameFeature &&
          targetLayer != null &&
          _forbiddenLayerImports[layer]!.contains(targetLayer)) {
        violations.add('$layer -> $targetLayer: ${i.from} -> ${i.uri}');
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('el dominio es puro: sin Flutter, Riverpod ni UI', () {
    final violations = [
      for (final i in imports)
        if (_layerOf(i.from) == 'domain' &&
            _forbiddenInDomain.any(i.uri.startsWith))
          '${i.from} -> ${i.uri}',
    ];
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('cada feature tiene API pública y solo carpetas de capa', () {
    final problems = <String>[];
    for (final dir in Directory(
      'lib/features',
    ).listSync().whereType<Directory>()) {
      final name = p.basename(dir.path);
      if (!File('${dir.path}/$name.dart').existsSync()) {
        problems.add('$name: falta la API pública $name.dart');
      }
      for (final entry in dir.listSync()) {
        final entryName = p.basename(entry.path);
        if (entry is Directory && !_layers.contains(entryName)) {
          problems.add('$name: carpeta "$entryName" no es una capa ($_layers)');
        }
        if (entry is File && entryName != '$name.dart') {
          problems.add('$name: "$entryName" debe ir dentro de una capa');
        }
      }
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('lib/ solo contiene main.dart, app/ y features/', () {
    final unexpected = [
      for (final entry in Directory('lib').listSync())
        if (!{'main.dart', 'app', 'features'}.contains(p.basename(entry.path)))
          p.basename(entry.path),
    ];
    expect(unexpected, isEmpty, reason: unexpected.join('\n'));
  });
}
