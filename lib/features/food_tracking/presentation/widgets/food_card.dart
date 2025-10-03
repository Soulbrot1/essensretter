import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/food.dart';
import '../bloc/food_bloc.dart';
import '../bloc/food_event.dart';
import 'food_tips_dialog.dart';
import '../../../sharing/presentation/services/supabase_food_sync_service.dart';
import '../../../sharing/presentation/services/simple_user_identity_service.dart';
import '../../../sharing/presentation/widgets/reservation_popup_dialog.dart';

class FoodCard extends StatefulWidget {
  final Food food;
  const FoodCard({super.key, required this.food});

  @override
  State<FoodCard> createState() => _FoodCardState();
}

class _FoodCardState extends State<FoodCard> {
  bool _hasReservation = false;
  Timer? _reservationUpdateTimer;

  @override
  void initState() {
    super.initState();
    if (widget.food.isShared) {
      _checkReservationStatus();
      // Check for reservation updates every 5 seconds when food is shared
      _startReservationTimer();
    }
  }

  @override
  void dispose() {
    _reservationUpdateTimer?.cancel();
    super.dispose();
  }

  void _startReservationTimer() {
    _reservationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (
      timer,
    ) {
      if (widget.food.isShared && mounted) {
        _checkReservationStatus();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void didUpdateWidget(FoodCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload reservations if the shared status changed
    if (widget.food.isShared != oldWidget.food.isShared ||
        widget.food.id != oldWidget.food.id) {
      // Cancel existing timer
      _reservationUpdateTimer?.cancel();

      if (widget.food.isShared) {
        _checkReservationStatus();
        _startReservationTimer();
      } else {
        setState(() {
          _hasReservation = false;
        });
      }
    }
  }

  Future<void> _checkReservationStatus() async {
    if (widget.food.isShared) {
      final foodId = widget.food.id;

      // Check if this is a shared food ID format (shared_supabase_id_friend_id)
      if (foodId.startsWith('shared_')) {
        return; // This is someone else's shared food, no reservations to show
      }

      // This is OUR own shared food - check for reservations
      try {
        // Get current user ID to find their shared foods
        final currentUserId =
            await SimpleUserIdentityService.getCurrentUserId();
        if (currentUserId == null) {
          return;
        }

        // Find this food in shared_foods table by name and user
        final sharedFoodData = await SupabaseFoodSyncService.client
            .from('shared_foods')
            .select('id, name, user_id')
            .eq('user_id', currentUserId)
            .eq('name', widget.food.name)
            .maybeSingle();

        if (sharedFoodData != null) {
          final sharedFoodId = sharedFoodData['id'] as String;

          // Check if there's any reservation (we only need to know if it exists)
          final reservation = await SupabaseFoodSyncService.client
              .from('food_reservations')
              .select()
              .eq('shared_food_id', sharedFoodId)
              .maybeSingle();

          if (mounted) {
            setState(() {
              _hasReservation = reservation != null;
            });
          }
        }
      } catch (e) {
        // Failed to check reservation status - non-critical
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysUntilExpiry = widget.food.daysUntilExpiry;
    final isExpired = widget.food.isExpired;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            // Erweiterter Touch-Bereich für die Checkbox
            GestureDetector(
              behavior:
                  HitTestBehavior.opaque, // Macht den gesamten Bereich klickbar
              onTap: () {
                context.read<FoodBloc>().add(
                  ToggleConsumedEvent(widget.food.id),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(
                  right: 12.0,
                ), // Erweitert den Touch-Bereich
                child: Container(
                  width: 32, // Größerer Touch-Bereich
                  height: 40, // Erweitert auf die volle Kartenhöhe
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 22, // Checkbox um 10% vergrößert (20 * 1.1)
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.food.isConsumed
                            ? Colors.green
                            : Colors.grey.shade400,
                        width: 1.5,
                      ),
                      color: widget.food.isConsumed
                          ? Colors.green
                          : Colors.transparent,
                    ),
                    child: widget.food.isConsumed
                        ? const Icon(Icons.check, color: Colors.white, size: 12)
                        : null,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Berechne die optimale Schriftgröße basierend auf der Textlänge
                      double fontSize = 16.0; // Maximale Größe
                      final textPainter = TextPainter(
                        text: TextSpan(
                          text: widget.food.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: fontSize,
                          ),
                        ),
                        maxLines: 1,
                        textDirection: TextDirection.ltr,
                      )..layout(maxWidth: double.infinity);

                      // Wenn der Text zu breit ist, verkleinere die Schriftgröße
                      while (textPainter.width > constraints.maxWidth &&
                          fontSize > 10) {
                        fontSize -= 0.5;
                        textPainter.text = TextSpan(
                          text: widget.food.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: fontSize,
                          ),
                        );
                        textPainter.layout(maxWidth: double.infinity);
                      }

                      return Text(
                        widget.food.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: fontSize,
                          color: widget.food.isConsumed ? Colors.grey : null,
                        ),
                      );
                    },
                  ),
                  if (widget.food.isConsumed)
                    Positioned.fill(
                      child: Center(
                        child: Container(height: 1.5, color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
            Stack(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _showExpiryDatePicker(context, widget.food),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: widget.food.isConsumed
                              ? Colors.grey.withValues(alpha: 0.2)
                              : isExpired
                              ? Colors.red.withValues(alpha: 0.2)
                              : Colors.green.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            isExpired
                                ? '-${daysUntilExpiry.abs()}'
                                : '$daysUntilExpiry',
                            style: TextStyle(
                              color: widget.food.isConsumed
                                  ? Colors.grey
                                  : isExpired
                                  ? Colors.red.shade700
                                  : Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) =>
                              FoodTipsDialog(foodName: widget.food.name),
                        );
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: widget.food.isConsumed
                              ? Colors.grey.withValues(alpha: 0.2)
                              : Colors.blue.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.info_outline,
                          color: widget.food.isConsumed
                              ? Colors.grey
                              : Colors.blue,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        if (widget.food.isShared && _hasReservation) {
                          // Show reservations popup
                          showDialog(
                            context: context,
                            builder: (dialogContext) => ReservationPopupDialog(
                              food: widget.food,
                              onFoodRemoved: () {
                                // Update the food to be not shared locally
                                final updatedFood = widget.food.copyWith(
                                  isShared: false,
                                );
                                context.read<FoodBloc>().add(
                                  UpdateFoodEvent(updatedFood),
                                );

                                // Cancel the timer as food is no longer shared
                                _reservationUpdateTimer?.cancel();
                                setState(() {
                                  _hasReservation = false;
                                });
                              },
                              onReservationChanged: () {
                                // Reload reservation status
                                _checkReservationStatus();
                              },
                            ),
                          );
                        } else {
                          _toggleSharedStatus(context, widget.food);
                        }
                      },
                      child: Stack(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: widget.food.isConsumed
                                  ? Colors.grey.withValues(alpha: 0.2)
                                  : widget.food.isShared
                                  ? Colors.green.withValues(alpha: 0.3)
                                  : Colors.grey.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.food.isShared
                                  ? Icons.share
                                  : Icons.share_outlined,
                              color: widget.food.isConsumed
                                  ? Colors.grey
                                  : widget.food.isShared
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                              size: 18,
                            ),
                          ),
                          // Reservation Badge - shows a dot if reserved
                          if (widget.food.isShared && _hasReservation)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        _showDeleteConfirmation(context, widget.food);
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: widget.food.isConsumed
                              ? Colors.grey.withValues(alpha: 0.2)
                              : Colors.red.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          color: widget.food.isConsumed
                              ? Colors.grey
                              : Colors.red,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.food.isConsumed)
                  Positioned.fill(
                    child: Center(
                      child: Container(height: 1.5, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showExpiryDatePicker(BuildContext context, Food food) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = food.expiryDate ?? now;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(now) ? initialDate : now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
      locale: const Locale('de', 'DE'),
      helpText: 'Haltbarkeitsdatum für ${food.name}',
      cancelText: 'Abbrechen',
      confirmText: 'Speichern',
    );

    if (pickedDate != null && context.mounted) {
      final updatedFood = food.copyWith(expiryDate: pickedDate);
      context.read<FoodBloc>().add(UpdateFoodEvent(updatedFood));
    }
  }

  void _toggleSharedStatus(BuildContext context, Food food) async {
    final wasShared = food.isShared;
    final updatedFood = food.copyWith(isShared: !food.isShared);

    context.read<FoodBloc>().add(UpdateFoodEvent(updatedFood));

    // Sync with Supabase (but don't block UI)
    try {
      if (!wasShared) {
        // Food is now being shared
        await SupabaseFoodSyncService.shareFood(updatedFood);
      } else {
        // Food is no longer shared
        await SupabaseFoodSyncService.unshareFood(food);
      }
    } catch (e) {
      // Show user feedback about sync failure
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync mit Server fehlgeschlagen: $e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasShared
                ? '${food.name} wird nicht mehr geteilt'
                : '${food.name} wird jetzt geteilt',
          ),
          backgroundColor: wasShared ? Colors.orange : Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context, Food food) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Lebensmittel wegwerfen?'),
          content: Text('Wurde "${food.name}" weggeworfen?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                // Als weggeworfen markieren (wasDisposed = true)
                context.read<FoodBloc>().add(
                  DeleteFoodEvent(food.id, wasDisposed: true),
                );
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${food.name} wurde als weggeworfen markiert',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
              child: const Text('Ja, weggeworfen'),
            ),
          ],
        );
      },
    );
  }
}
