import 'dart:math';
import 'package:apidash_core/apidash_core.dart';
import 'package:apidash_design_system/apidash_design_system.dart';
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:apidash/consts.dart';
import 'package:apidash/providers/providers.dart';
import 'package:apidash/utils/utils.dart';
import 'package:apidash/widgets/widgets.dart';

class EditEnvironmentVariables extends ConsumerStatefulWidget {
  const EditEnvironmentVariables({super.key});

  @override
  ConsumerState<EditEnvironmentVariables> createState() =>
      EditEnvironmentVariablesState();
}

class EditEnvironmentVariablesState
    extends ConsumerState<EditEnvironmentVariables> {
  late int seed;
  final random = Random.secure();
  late List<EnvironmentVariableModel> variableRows;
  bool isAddingRow = false;

  @override
  void initState() {
    super.initState();
    seed = random.nextInt(kRandMax);
  }

  void _onFieldChange(String selectedId) {
    final environment = ref.read(selectedEnvironmentModelProvider);
    final secrets = getEnvironmentSecrets(environment);
    ref.read(environmentsStateNotifierProvider.notifier).updateEnvironment(
      selectedId,
      values: [...variableRows.sublist(0, variableRows.length - 1), ...secrets],
    );
  }

  @override
  Widget build(BuildContext context) {
    dataTableShowLogs = false;
    final selectedId = ref.watch(selectedEnvironmentIdStateProvider);
    ref.watch(selectedEnvironmentModelProvider
        .select((environment) => getEnvironmentVariables(environment).length));
    var rows =
        getEnvironmentVariables(ref.read(selectedEnvironmentModelProvider));
    variableRows = rows.isEmpty
        ? [
            kEnvironmentVariableEmptyModel,
          ]
        : rows + [kEnvironmentVariableEmptyModel];
    isAddingRow = false;

    List<DataColumn> columns = const [
      DataColumn2(
        label: Text(kNameCheckbox),
        fixedWidth: 30,
      ),
      DataColumn2(
        label: Text("Variable name"),
      ),
      DataColumn2(
        label: Text('='),
        fixedWidth: 30,
      ),
      DataColumn2(
        label: Text("Variable value"),
      ),
      DataColumn2(
        label: Text(''),
        fixedWidth: 32,
      ),
    ];

    List<DataRow> dataRows = List<DataRow>.generate(
      variableRows.length,
      (index) {
        bool isLast = index + 1 == variableRows.length;
        return DataRow(
          key: ValueKey("$selectedId-$index-variables-row-$seed"),
          cells: <DataCell>[
            DataCell(
              ADCheckBox(
                keyId: "$selectedId-$index-variables-c-$seed",
                value: variableRows[index].enabled,
                onChanged: isLast
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            variableRows[index] =
                                variableRows[index].copyWith(enabled: value);
                          });
                        }
                        _onFieldChange(selectedId!);
                      },
                colorScheme: Theme.of(context).colorScheme,
              ),
            ),
            DataCell(
              CellField(
                keyId: "$selectedId-$index-variables-k-$seed",
                initialValue: variableRows[index].key,
                hintText: "Add Variable",
                onChanged: (value) {
                  // Auto-detect multi-line .env paste
                  if (looksLikeEnvContent(value)) {
                    final parsed = parseEnvContent(value);
                    if (parsed.isNotEmpty) {
                      seed = random.nextInt(kRandMax);
                      // Remove the current empty row if it's the last one
                      if (isLast) {
                        variableRows.removeAt(index);
                      }
                      // Insert parsed env vars at the current position
                      variableRows.insertAll(index, parsed);
                      // Ensure there's always an empty row at the end
                      if (variableRows.last != kEnvironmentVariableEmptyModel) {
                        variableRows.add(kEnvironmentVariableEmptyModel);
                      }
                      _onFieldChange(selectedId!);
                      setState(() {});
                      return;
                    }
                  }
                  if (isLast && !isAddingRow) {
                    isAddingRow = true;
                    variableRows[index] =
                        variableRows[index].copyWith(key: value, enabled: true);
                    variableRows.add(kEnvironmentVariableEmptyModel);
                  } else {
                    variableRows[index] =
                        variableRows[index].copyWith(key: value);
                  }
                  _onFieldChange(selectedId!);
                },
                colorScheme: Theme.of(context).colorScheme,
              ),
            ),
            DataCell(
              Center(
                child: Text(
                  "=",
                  style: kCodeStyle,
                ),
              ),
            ),
            DataCell(
              CellField(
                keyId: "$selectedId-$index-variables-v-$seed",
                initialValue: variableRows[index].value,
                hintText: kHintAddValue,
                onChanged: (value) {
                  // Auto-detect multi-line .env paste in value field
                  if (looksLikeEnvContent(value)) {
                    final parsed = parseEnvContent(value);
                    if (parsed.isNotEmpty) {
                      seed = random.nextInt(kRandMax);
                      if (isLast) {
                        variableRows.removeAt(index);
                      }
                      variableRows.insertAll(index, parsed);
                      if (variableRows.last != kEnvironmentVariableEmptyModel) {
                        variableRows.add(kEnvironmentVariableEmptyModel);
                      }
                      _onFieldChange(selectedId!);
                      setState(() {});
                      return;
                    }
                  }
                  // Auto-strip surrounding quotes from value
                  var cleanValue = value;
                  if (cleanValue.length >= 2 &&
                      ((cleanValue.startsWith('"') &&
                              cleanValue.endsWith('"')) ||
                          (cleanValue.startsWith("'") &&
                              cleanValue.endsWith("'")))) {
                    cleanValue = cleanValue.substring(1, cleanValue.length - 1);
                  }
                  if (isLast && !isAddingRow) {
                    isAddingRow = true;
                    variableRows[index] = variableRows[index]
                        .copyWith(value: cleanValue, enabled: true);
                    variableRows.add(kEnvironmentVariableEmptyModel);
                  } else {
                    variableRows[index] =
                        variableRows[index].copyWith(value: cleanValue);
                  }
                  _onFieldChange(selectedId!);
                },
                colorScheme: Theme.of(context).colorScheme,
              ),
            ),
            DataCell(
              InkWell(
                onTap: isLast
                    ? null
                    : () {
                        seed = random.nextInt(kRandMax);
                        if (variableRows.length == 2) {
                          setState(() {
                            variableRows = [
                              kEnvironmentVariableEmptyModel,
                            ];
                          });
                        } else {
                          variableRows.removeAt(index);
                        }
                        _onFieldChange(selectedId!);
                      },
                child: Theme.of(context).brightness == Brightness.dark
                    ? kIconRemoveDark
                    : kIconRemoveLight,
              ),
            ),
          ],
        );
      },
    );

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: kBorderRadius12,
          ),
          margin: kPh10t10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(scrollbarTheme: kDataTableScrollbarTheme),
                  child: DataTable2(
                    columnSpacing: 12,
                    dividerThickness: 0,
                    horizontalMargin: 0,
                    headingRowHeight: 0,
                    dataRowHeight: kDataTableRowHeight,
                    bottomMargin: kDataTableBottomPadding,
                    isVerticalScrollBarVisible: true,
                    columns: columns,
                    rows: dataRows,
                  ),
                ),
              ),
              if (!kIsMobile) kVSpacer40,
            ],
          ),
        ),
        if (!kIsMobile)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: kPb15,
              child: ElevatedButton.icon(
                onPressed: () {
                  variableRows.add(kEnvironmentVariableEmptyModel);
                  _onFieldChange(selectedId!);
                },
                icon: const Icon(Icons.add),
                label: const Text(
                  kLabelAddVariable,
                  style: kTextStyleButton,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
