import 'package:flutter/material.dart';

import 'package:cyclecore_core/theme/cc_colors.dart';
import 'package:cyclecore_core/theme/cc_type.dart';

/// Bloque de "Resumen" de una actividad -- los mismos widgets en el
/// **detalle** y en **guardar/editar**. Antes cada pantalla dibujaba los
/// totales a su manera (el detalle con héroe + filas, el formulario con
/// una cuadrícula de mosaicos), así que veías las cifras de una forma al
/// guardar y de otra al abrir la actividad dos segundos después. Ahora
/// es un solo componente: si se cambia el diseño del resumen, cambia en
/// los dos lados a la vez.

/// Encabezado de sección en versalitas ("RESUMEN", "FOTOS", "NOTAS"...).
class ActivitySectionLabel extends StatelessWidget {
  final String text;

  const ActivitySectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: CcType.label(
        size: 11,
        color: CcColors.inkFaint,
      ).copyWith(letterSpacing: 1.4),
    );
  }
}

/// El dato ancla del resumen -- la distancia, en grande. `gold` la pinta
/// en dorado cuando es récord personal.
class ActivitySummaryHero extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final bool gold;

  const ActivitySummaryHero({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.gold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ActivitySectionLabel(label),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: CcType.displayStyle(
                  size: 46,
                  weight: FontWeight.w800,
                  color: gold ? CcColors.gold : CcColors.ink,
                  letterSpacing: -0.03,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                unit,
                style: const TextStyle(
                  color: CcColors.inkDim,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Un dato de la fila con filete bajo el héroe.
class ActivityStatCell {
  final String label;
  final String value;
  final String unit;
  final bool gold;

  const ActivityStatCell({
    required this.label,
    required this.value,
    this.unit = '',
    this.gold = false,
  });
}

/// Fila de datos separados por un filete vertical, delimitada arriba y
/// abajo por una línea fina.
class ActivityDividedRow extends StatelessWidget {
  final List<ActivityStatCell> cells;

  const ActivityDividedRow({super.key, required this.cells});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: CcColors.lineSoft),
          bottom: BorderSide(color: CcColors.lineSoft),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < cells.length; i++)
              Expanded(
                child: Container(
                  padding: EdgeInsets.fromLTRB(i == 0 ? 0 : 13, 11, 4, 11),
                  decoration: BoxDecoration(
                    border: i == 0
                        ? null
                        : const Border(
                            left: BorderSide(color: CcColors.lineSoft),
                          ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cells[i].label.toUpperCase(),
                        style: CcType.label(
                          size: 9,
                          color: CcColors.inkFaint,
                        ).copyWith(letterSpacing: 1),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              cells[i].value,
                              style: CcType.displayStyle(
                                size: 19,
                                weight: FontWeight.w700,
                                color: cells[i].gold
                                    ? CcColors.gold
                                    : CcColors.ink,
                              ),
                            ),
                            if (cells[i].unit.isNotEmpty) ...[
                              const SizedBox(width: 3),
                              Text(
                                cells[i].unit,
                                style: const TextStyle(
                                  color: CcColors.inkDim,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Un valor (o par prom/máx) de una fila de datos.
typedef ActivityDataValue = ({String? pair, String value, bool gold});

/// Fila de dato: ícono + nombre a la izquierda, valores a la derecha
/// (uno solo, o el par prom/máx del mismo dato). Las cifras que son
/// récord personal van en dorado.
///
/// Si [values] llega vacía y hay [emptyPlaceholder] (p. ej. "Sin datos"),
/// se muestra ese texto en gris -- lo usa el formulario de guardado para
/// dejar claro, antes de guardar, que ese sensor no grabó nada.
class ActivityDataRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String unit;
  final List<ActivityDataValue> values;
  final String? emptyPlaceholder;

  const ActivityDataRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.unit,
    required this.values,
    this.emptyPlaceholder,
  });

  @override
  Widget build(BuildContext context) {
    final showEmpty = values.isEmpty && emptyPlaceholder != null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CcColors.lineSoft)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 9),
          Text(
            label,
            style: const TextStyle(
              color: CcColors.inkDim,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: showEmpty
                ? Text(
                    emptyPlaceholder!,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: CcColors.inkFaint,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        for (final v in values) ...[
                          if (v.pair != null) ...[
                            Text(
                              v.pair!,
                              style: const TextStyle(
                                color: CcColors.inkFaint,
                                fontSize: 11.5,
                              ),
                            ),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            v.value,
                            style: CcType.displayStyle(
                              size: 14,
                              weight: FontWeight.w700,
                              color: v.gold ? CcColors.gold : CcColors.ink,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          unit,
                          style: const TextStyle(
                            color: CcColors.inkFaint,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
