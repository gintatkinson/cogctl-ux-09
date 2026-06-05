import 'package:equatable/equatable.dart';
import 'package:cogctl_ux/features/software_configuration/domain/inventory_type_reference.dart';

enum TypesReferencesStatus { initial, success, failure }

class TypesReferencesState extends Equatable {
  final List<MockInventoryTypeReference> references;
  final TypesReferencesStatus status;
  final String? generalError;

  const TypesReferencesState({
    required this.references,
    this.status = TypesReferencesStatus.initial,
    this.generalError,
  });

  @override
  List<Object?> get props => [references, status, generalError];

  TypesReferencesState copyWith({
    List<MockInventoryTypeReference>? references,
    TypesReferencesStatus? status,
    String? Function()? generalError,
  }) {
    return TypesReferencesState(
      references: references ?? this.references,
      status: status ?? this.status,
      generalError: generalError != null ? generalError() : this.generalError,
    );
  }
}
