# Supabase Database Setup for Friend Connections

## Required Tables

### 1. user_connections table

Execute the SQL in `supabase_migrations/create_user_connections_table.sql` in your Supabase SQL editor.

This creates:
- `user_connections` table with bidirectional friend relationships
- Proper indexes for performance
- Row Level Security policies
- Validation constraints for User-ID format (ER-XXXXXXXX)
- Helper function `add_bidirectional_connection()` for safe connections

### 2. user_activity table (optional)

```sql
CREATE TABLE IF NOT EXISTS public.user_activity (
    user_id TEXT PRIMARY KEY,
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    CONSTRAINT valid_user_id_format CHECK (user_id ~ '^ER-[A-Z0-9]{8}$')
);

ALTER TABLE public.user_activity ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their own activity" ON public.user_activity FOR ALL USING (true);
GRANT ALL ON public.user_activity TO anon, authenticated;
```

## Testing the Setup

After creating the tables, run:

```bash
flutter test test/features/sharing/presentation/services/friend_service_integration_test.dart
```

The connection test should pass once the `user_connections` table exists.

## Manual Setup Steps

1. Go to your Supabase project dashboard
2. Navigate to SQL Editor
3. Paste the contents of `supabase_migrations/create_user_connections_table.sql`
4. Execute the SQL
5. Verify tables are created in the Table Editor

## Verification

Test the setup by running a simple connection test:

```dart
final testResult = await FriendService.testConnection();
print('Supabase connection: $testResult'); // Should print true
```