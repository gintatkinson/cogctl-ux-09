import 'package:get_it/get_it.dart';

// Services
import 'package:cogctl_ux/features/geo_location/data/mock_location_service.dart';
import 'package:cogctl_ux/features/infrastructure/data/mock_inventory_location_service.dart';
import 'package:cogctl_ux/features/infrastructure/data/mock_equipment_rack_service.dart';
import 'package:cogctl_ux/features/infrastructure/data/mock_network_inventory_service.dart';
import 'package:cogctl_ux/features/yang_telemetry/data/mock_counter_gauge_service.dart';
import 'package:cogctl_ux/features/yang_telemetry/data/mock_identifiers_references_service.dart';
import 'package:cogctl_ux/features/yang_telemetry/data/mock_date_time_service.dart';
import 'package:cogctl_ux/features/yang_telemetry/data/mock_time_duration_service.dart';
import 'package:cogctl_ux/features/yang_telemetry/data/mock_address_tag_service.dart';
import 'package:cogctl_ux/features/software_configuration/data/mock_types_references_service.dart';
import 'package:cogctl_ux/features/software_configuration/data/mock_software_manufacturer_service.dart';

// Repositories & Interfaces
import 'package:cogctl_ux/features/geo_location/domain/repositories/i_location_repository.dart';
import 'package:cogctl_ux/features/geo_location/data/repositories/location_repository_impl.dart';
import 'package:cogctl_ux/features/infrastructure/domain/repositories/i_inventory_location_repository.dart';
import 'package:cogctl_ux/features/infrastructure/data/repositories/inventory_location_repository_impl.dart';
import 'package:cogctl_ux/features/infrastructure/domain/repositories/i_equipment_rack_repository.dart';
import 'package:cogctl_ux/features/infrastructure/data/repositories/equipment_rack_repository_impl.dart';
import 'package:cogctl_ux/features/infrastructure/domain/repositories/i_network_inventory_repository.dart';
import 'package:cogctl_ux/features/infrastructure/data/repositories/network_inventory_repository_impl.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/repositories/i_counter_gauge_repository.dart';
import 'package:cogctl_ux/features/yang_telemetry/data/repositories/counter_gauge_repository_impl.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/repositories/i_identifiers_references_repository.dart';
import 'package:cogctl_ux/features/yang_telemetry/data/repositories/identifiers_references_repository_impl.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/repositories/i_date_time_repository.dart';
import 'package:cogctl_ux/features/yang_telemetry/data/repositories/date_time_repository_impl.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/repositories/i_time_duration_repository.dart';
import 'package:cogctl_ux/features/yang_telemetry/data/repositories/time_duration_repository_impl.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/repositories/i_address_tag_repository.dart';
import 'package:cogctl_ux/features/yang_telemetry/data/repositories/address_tag_repository_impl.dart';
import 'package:cogctl_ux/features/software_configuration/domain/repositories/i_types_references_repository.dart';
import 'package:cogctl_ux/features/software_configuration/data/repositories/types_references_repository_impl.dart';
import 'package:cogctl_ux/features/software_configuration/domain/repositories/i_software_manufacturer_repository.dart';
import 'package:cogctl_ux/features/software_configuration/data/repositories/software_manufacturer_repository_impl.dart';

final sl = GetIt.instance;

void initServiceLocator({bool force = false}) {
  if (force) {
    sl.reset();
  } else if (sl.isRegistered<MockLocationService>()) {
    return;
  }
  // Concrete mock services (singletons)
  sl.registerLazySingleton<MockLocationService>(() => MockLocationService());
  sl.registerLazySingleton<MockInventoryLocationService>(() => MockInventoryLocationService());
  sl.registerLazySingleton<MockEquipmentRackService>(() => MockEquipmentRackService());
  sl.registerLazySingleton<MockNetworkInventoryService>(() => MockNetworkInventoryService());
  sl.registerLazySingleton<MockCounterGaugeService>(() => MockCounterGaugeService());
  sl.registerLazySingleton<MockIdentifiersReferencesService>(() => MockIdentifiersReferencesService());
  sl.registerLazySingleton<MockDateTimeService>(() => MockDateTimeService());
  sl.registerLazySingleton<MockTimeDurationService>(() => MockTimeDurationService());
  sl.registerLazySingleton<MockAddressTagService>(() => MockAddressTagService());
  sl.registerLazySingleton<MockTypesReferencesService>(() => MockTypesReferencesService());
  sl.registerLazySingleton<MockSoftwareManufacturerService>(() => MockSoftwareManufacturerService());

  // Repositories mapping to implementations
  sl.registerLazySingleton<ILocationRepository>(
    () => LocationRepositoryImpl(sl<MockLocationService>()),
  );
  sl.registerLazySingleton<IInventoryLocationRepository>(
    () => InventoryLocationRepositoryImpl(sl<MockInventoryLocationService>()),
  );
  sl.registerLazySingleton<IEquipmentRackRepository>(
    () => EquipmentRackRepositoryImpl(sl<MockEquipmentRackService>()),
  );
  sl.registerLazySingleton<INetworkInventoryRepository>(
    () => NetworkInventoryRepositoryImpl(sl<MockNetworkInventoryService>()),
  );
  sl.registerLazySingleton<ICounterGaugeRepository>(
    () => CounterGaugeRepositoryImpl(sl<MockCounterGaugeService>()),
  );
  sl.registerLazySingleton<IIdentifiersReferencesRepository>(
    () => IdentifiersReferencesRepositoryImpl(sl<MockIdentifiersReferencesService>()),
  );
  sl.registerLazySingleton<IDateTimeRepository>(
    () => DateTimeRepositoryImpl(sl<MockDateTimeService>()),
  );
  sl.registerLazySingleton<ITimeDurationRepository>(
    () => TimeDurationRepositoryImpl(sl<MockTimeDurationService>()),
  );
  sl.registerLazySingleton<IAddressTagRepository>(
    () => AddressTagRepositoryImpl(sl<MockAddressTagService>()),
  );
  sl.registerLazySingleton<ITypesReferencesRepository>(
    () => TypesReferencesRepositoryImpl(sl<MockTypesReferencesService>()),
  );
  sl.registerLazySingleton<ISoftwareManufacturerRepository>(
    () => SoftwareManufacturerRepositoryImpl(sl<MockSoftwareManufacturerService>()),
  );
}
