-- Create user_connections table for friend relationships
-- This table handles bidirectional connections between users

CREATE TABLE IF NOT EXISTS public.user_connections (
    id BIGSERIAL PRIMARY KEY,
    user_id TEXT NOT NULL, -- The user who owns this connection record
    friend_id TEXT NOT NULL, -- The user they're connected to
    friend_name TEXT, -- Name assigned to the friend (can be null initially)
    status TEXT NOT NULL DEFAULT 'connected', -- 'connected', 'blocked', 'pending'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Constraints
    CONSTRAINT valid_user_id_format CHECK (user_id ~ '^ER-[A-Z0-9]{8}$'),
    CONSTRAINT valid_friend_id_format CHECK (friend_id ~ '^ER-[A-Z0-9]{8}$'),
    CONSTRAINT no_self_connection CHECK (user_id != friend_id),
    CONSTRAINT valid_status CHECK (status IN ('connected', 'blocked', 'pending')),

    -- Unique constraint to prevent duplicate connections
    UNIQUE(user_id, friend_id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_connections_user_id ON public.user_connections(user_id);
CREATE INDEX IF NOT EXISTS idx_user_connections_friend_id ON public.user_connections(friend_id);
CREATE INDEX IF NOT EXISTS idx_user_connections_status ON public.user_connections(status);
CREATE INDEX IF NOT EXISTS idx_user_connections_created_at ON public.user_connections(created_at);

-- Enable Row Level Security
ALTER TABLE public.user_connections ENABLE ROW LEVEL SECURITY;

-- Create policies for Row Level Security
-- Users can only see connections where they are either the user_id or friend_id
CREATE POLICY "Users can view their own connections" ON public.user_connections
    FOR SELECT USING (true); -- For now, allow all reads - can be restricted later

-- Users can insert connections where they are the user_id
CREATE POLICY "Users can create their own connections" ON public.user_connections
    FOR INSERT WITH CHECK (true); -- For now, allow all inserts - can be restricted later

-- Users can update connections where they are the user_id
CREATE POLICY "Users can update their own connections" ON public.user_connections
    FOR UPDATE USING (true); -- For now, allow all updates - can be restricted later

-- Users can delete connections where they are the user_id
CREATE POLICY "Users can delete their own connections" ON public.user_connections
    FOR DELETE USING (true); -- For now, allow all deletes - can be restricted later

-- Grant permissions
GRANT ALL ON public.user_connections TO anon;
GRANT ALL ON public.user_connections TO authenticated;

-- Add trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_user_connections_updated_at
    BEFORE UPDATE ON public.user_connections
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Optional: Create a function to safely add bidirectional connections
CREATE OR REPLACE FUNCTION add_bidirectional_connection(
    user_a TEXT,
    user_b TEXT,
    user_a_name_for_b TEXT DEFAULT NULL,
    user_b_name_for_a TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Validate input
    IF user_a = user_b THEN
        RAISE EXCEPTION 'Cannot connect user to themselves';
    END IF;

    IF NOT (user_a ~ '^ER-[A-Z0-9]{8}$' AND user_b ~ '^ER-[A-Z0-9]{8}$') THEN
        RAISE EXCEPTION 'Invalid user ID format';
    END IF;

    -- Insert connection A -> B
    INSERT INTO public.user_connections (user_id, friend_id, friend_name, status)
    VALUES (user_a, user_b, user_a_name_for_b, 'connected')
    ON CONFLICT (user_id, friend_id) DO UPDATE SET
        friend_name = EXCLUDED.friend_name,
        status = 'connected',
        updated_at = NOW();

    -- Insert connection B -> A
    INSERT INTO public.user_connections (user_id, friend_id, friend_name, status)
    VALUES (user_b, user_a, user_b_name_for_a, 'connected')
    ON CONFLICT (user_id, friend_id) DO UPDATE SET
        friend_name = EXCLUDED.friend_name,
        status = 'connected',
        updated_at = NOW();

    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$;
