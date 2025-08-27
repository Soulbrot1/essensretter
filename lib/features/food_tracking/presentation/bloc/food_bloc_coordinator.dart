import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'food_data_bloc.dart';
import 'food_data_state.dart';
import 'food_ui_bloc.dart';
import 'food_ui_event.dart';

/// Koordiniert die Kommunikation zwischen FoodDataBloc und FoodUIBloc
class FoodBlocCoordinator {
  final FoodDataBloc dataBloc;
  final FoodUIBloc uiBloc;
  StreamSubscription<FoodDataState>? _subscription;

  FoodBlocCoordinator({required this.dataBloc, required this.uiBloc}) {
    _setupCoordination();
  }

  void _setupCoordination() {
    // Listen to data changes and update UI accordingly
    _subscription = dataBloc.stream.listen((dataState) {
      if (dataState is FoodDataLoaded) {
        // Update UI bloc with new food data
        uiBloc.add(UpdateFoodListEvent(dataState.foods));
      }
    });
  }

  void dispose() {
    _subscription?.cancel();
  }
}

/// MultiBlocProvider Helper für einfache Integration
class FoodBlocProvider extends StatelessWidget {
  final Widget child;
  final FoodDataBloc dataBloc;
  final FoodUIBloc uiBloc;
  late final FoodBlocCoordinator _coordinator;

  FoodBlocProvider({
    super.key,
    required this.child,
    required this.dataBloc,
    required this.uiBloc,
  }) {
    _coordinator = FoodBlocCoordinator(dataBloc: dataBloc, uiBloc: uiBloc);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<FoodDataBloc>.value(value: dataBloc),
        BlocProvider<FoodUIBloc>.value(value: uiBloc),
      ],
      child: child,
    );
  }

  void dispose() {
    _coordinator.dispose();
  }
}
