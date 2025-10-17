-- Fix food_reservations RLS policies to work without Supabase Auth
-- This app uses custom user IDs (ER-XXXXXXXX) instead of auth.uid()

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view relevant reservations" ON food_reservations;
DROP POLICY IF EXISTS "Users can create reservations" ON food_reservations;
DROP POLICY IF EXISTS "Providers can delete reservations" ON food_reservations;

-- Create new policies that allow access without auth.uid()
-- Note: In production, you might want to add API key validation or other security measures

-- Policy: Allow all reads for now (can be restricted later)
CREATE POLICY "Allow all reads" ON food_reservations
  FOR SELECT USING (true);

-- Policy: Allow all inserts for now (can be restricted later)
CREATE POLICY "Allow all inserts" ON food_reservations
  FOR INSERT WITH CHECK (true);

-- Policy: Allow all updates for now (can be restricted later)
CREATE POLICY "Allow all updates" ON food_reservations
  FOR UPDATE USING (true);

-- Policy: Allow all deletes for now (can be restricted later)
CREATE POLICY "Allow all deletes" ON food_reservations
  FOR DELETE USING (true);

-- Grant permissions to anon and authenticated users
GRANT ALL ON food_reservations TO anon;
GRANT ALL ON food_reservations TO authenticated;
