-- Migration: Enforce single reservation per food
-- This ensures only ONE person can reserve a food item at a time

-- Drop the old constraint that allowed multiple reservations
ALTER TABLE food_reservations DROP CONSTRAINT IF EXISTS unique_reservation;

-- Add new constraint: Only ONE reservation per food (regardless of who)
-- This replaces the old (shared_food_id, reserved_by) constraint
ALTER TABLE food_reservations
  ADD CONSTRAINT unique_single_reservation_per_food
  UNIQUE (shared_food_id);

-- Add comment for documentation
COMMENT ON CONSTRAINT unique_single_reservation_per_food ON food_reservations IS
  'Ensures only one person can reserve a food item at a time. When someone reserves a food, it becomes unavailable for others until the reservation is released.';
