-- Migration: Create food_reservations table for tracking who reserved shared foods

-- Create the food_reservations table
CREATE TABLE IF NOT EXISTS food_reservations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shared_food_id UUID NOT NULL,
  reserved_by TEXT NOT NULL,
  reserved_by_name TEXT,
  reserved_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  provider_id TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Add indexes for performance
  CONSTRAINT unique_reservation UNIQUE (shared_food_id, reserved_by)
);

-- Create indexes for better query performance
CREATE INDEX idx_food_reservations_shared_food ON food_reservations(shared_food_id);
CREATE INDEX idx_food_reservations_reserved_by ON food_reservations(reserved_by);
CREATE INDEX idx_food_reservations_provider ON food_reservations(provider_id);

-- Add RLS policies
ALTER TABLE food_reservations ENABLE ROW LEVEL SECURITY;

-- Policy: Users can see reservations for foods they provide or reserved
CREATE POLICY "Users can view relevant reservations" ON food_reservations
  FOR SELECT USING (
    auth.uid()::text = provider_id OR
    auth.uid()::text = reserved_by
  );

-- Policy: Users can create reservations
CREATE POLICY "Users can create reservations" ON food_reservations
  FOR INSERT WITH CHECK (
    auth.uid()::text = reserved_by
  );

-- Policy: Providers can delete reservations for their foods
CREATE POLICY "Providers can delete reservations" ON food_reservations
  FOR DELETE USING (
    auth.uid()::text = provider_id
  );

-- Add comment for documentation
COMMENT ON TABLE food_reservations IS 'Tracks reservations for shared foods between friends';
COMMENT ON COLUMN food_reservations.shared_food_id IS 'ID of the shared food from shared_foods table';
COMMENT ON COLUMN food_reservations.reserved_by IS 'User ID of person who reserved the food';
COMMENT ON COLUMN food_reservations.reserved_by_name IS 'Local name of the person (stored locally)';
COMMENT ON COLUMN food_reservations.provider_id IS 'User ID of the food provider';
