-- Create message_feedback table
create table message_feedback (
  id uuid default gen_random_uuid() primary key,
  message_id uuid references messages(id) on delete cascade,
  is_like boolean not null,
  feedback_message text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Add index for faster lookups
create index message_feedback_message_id_idx on message_feedback(message_id); 